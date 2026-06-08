import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/shared_orders_service.dart';
import '../services/guest_customer_tracking_service.dart';
import '../services/supabase_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  final _localStorage = LocalStorageService();
  final _sharedOrders = SharedOrdersService();
  final _guestCustomerTracking = GuestCustomerTrackingService();

  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<String> createOrder({
    required String customerName,
    required String customerPhone,
    required String orderType,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    Map<String, String>? deliveryAddress,
  }) async {
    try {
      final customerId = _guestCustomerTracking.generateCustomerId();
      final createdAt = DateTime.now().toIso8601String();

      await _localStorage.saveCustomerInfo(
        name: customerName,
        phone: customerPhone,
        orderType: orderType,
      );

      String? supabaseId;
      String orderId = await _localStorage.generateOrderId(customerPhone: customerPhone); // final fallback

      // Layer 1: try RPC for atomic sequential number
      String? rpcNumber;
      try {
        final rpcResult =
            await SupabaseService.client.rpc('get_next_order_number');
        final str = rpcResult?.toString().trim() ?? '';
        if (str.length == 6) rpcNumber = str;
      } catch (_) {}

      // Layer 2: insert to Supabase; trigger sets order_number if RPC failed
      try {
        final insertData = <String, dynamic>{
          'order_type': orderType,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'payment_method': paymentMethod,
          'total_price': totalPrice,
          'status': 'pending',
          'customer_info': {
            'name': customerName,
            'phone': customerPhone,
            'order_type': orderType,
            if (deliveryAddress != null) 'delivery_address': deliveryAddress,
          },
          'items': items,
          'created_at': createdAt,
          if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        };
        if (rpcNumber != null) insertData['order_number'] = rpcNumber;

        final res = await SupabaseService.client
            .from(SupabaseService.tableOrders)
            .insert(insertData)
            .select('id, order_number')
            .single();

        supabaseId = res['id'] as String;
        final dbNumber = res['order_number'] as String?;
        if (dbNumber != null && dbNumber.length == 6) {
          orderId = dbNumber; // DB value (trigger or RPC)
        } else if (rpcNumber != null) {
          orderId = rpcNumber;
        }

        for (final item in items) {
          await SupabaseService.client
              .from(SupabaseService.tableOrderItems)
              .insert({
                'order_id': supabaseId,
                'menu_item_id': item['menu_item_id'],
                'name': item['name'],
                'quantity': item['quantity'],
                'price': item['price'],
              });
        }
      } catch (e) {
        // Layer 3: full local fallback — use RPC number if we got one
        if (rpcNumber != null) orderId = rpcNumber;
        print('⚠️ Supabase write failed: $e');
      }

      // 2. Save locally with supabase_id so we can sync status later
      final orderData = {
        'id': orderId,
        'supabase_id': supabaseId,
        'customer_id': customerId,
        'items': items,
        'total_price': totalPrice,
        'order_type': orderType,
        'customer_info': {
          'name': customerName,
          'phone': customerPhone,
          'order_type': orderType,
          if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        },
        'payment_method': paymentMethod,
        'status': 'pending',
        'created_at': createdAt,
        if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      };

      await _localStorage.saveOrder(
        orderId: orderId,
        items: items,
        totalPrice: totalPrice,
        orderType: orderType,
      );

      await _sharedOrders.saveOrderToShared(
        orderId: orderId,
        orderData: orderData,
      );

      await _guestCustomerTracking.saveGuestCustomer(
        customerId: customerId,
        name: customerName,
        phone: customerPhone,
        email: '',
        orderType: orderType,
        totalSpent: totalPrice,
      );

      // Increment per-item order count (for daily limit enforcement)
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      for (final item in items) {
        final menuItemId = item['menu_item_id'] as String?;
        final qty = (item['quantity'] as int?) ?? 1;
        if (menuItemId == null) continue;
        try {
          await SupabaseService.client.rpc('increment_item_order_count', params: {
            'p_item_id': menuItemId,
            'p_quantity': qty,
            'p_date': todayStr,
          });
        } catch (_) {}
      }

      await fetchOrders();
      return orderId;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _sharedOrders.init(); // ensure _prefs is initialized after hot-reload or web refresh
      _orders = _sharedOrders.getAllOrders();
      _orders.sort((a, b) => DateTime.parse(b['created_at'] as String)
          .compareTo(DateTime.parse(a['created_at'] as String)));

      // Sync latest status from Supabase using the stored UUID
      for (var i = 0; i < _orders.length; i++) {
        final supabaseId = _orders[i]['supabase_id'] as String?;
        if (supabaseId == null) continue;
        try {
          final response = await SupabaseService.client
              .from(SupabaseService.tableOrders)
              .select('status')
              .eq('id', supabaseId)
              .maybeSingle();
          if (response != null && response['status'] != null) {
            _orders[i] = Map<String, dynamic>.from(_orders[i])
              ..['status'] = response['status'];
          }
        } catch (_) {}
      }
    } catch (e) {
      print('Error fetching orders: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _sharedOrders.updateOrderStatus(orderId, newStatus);
      await fetchOrders();
      notifyListeners();
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      // Find the order to get its Supabase UUID
      final order = _orders.firstWhere(
        (o) => o['id'] == orderId,
        orElse: () => {},
      );
      final supabaseId = order['supabase_id'] as String?;

      // Update in Supabase if we have the UUID
      if (supabaseId != null) {
        try {
          await SupabaseService.client
              .from(SupabaseService.tableOrders)
              .update({'status': 'cancelled'})
              .eq('id', supabaseId);
        } catch (e) {
          print('⚠️ Supabase cancel failed: $e');
        }
      }

      await _sharedOrders.updateOrderStatus(orderId, 'cancelled');
      await fetchOrders();
      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }

  Future<void> clearAllOrders() async {
    await _localStorage.clearAllOrders();
    await _sharedOrders.clearAllOrders();
    await fetchOrders();
  }
}
