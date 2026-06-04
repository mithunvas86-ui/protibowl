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

  Future<String> _generateOrderId() async {
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final todayPrefix = '$dd$mm';
    try {
      final response = await SupabaseService.client
          .from(SupabaseService.tableOrders)
          .select('order_number')
          .like('order_number', '$todayPrefix%')
          .order('order_number', ascending: false)
          .limit(1);
      int count = 1;
      if ((response as List).isNotEmpty) {
        final lastNumber = response[0]['order_number'] as String? ?? '';
        if (lastNumber.length >= 6) {
          final lastCount = int.tryParse(lastNumber.substring(4)) ?? 0;
          count = lastCount + 1;
        }
      }
      final cc = count.toString().padLeft(2, '0');
      return '$dd$mm$cc';
    } catch (_) {
      return _localStorage.generateOrderId();
    }
  }

  Future<String> createOrder({
    required String customerName,
    required String customerPhone,
    required String orderType,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
  }) async {
    try {
      final orderId = await _generateOrderId();
      final customerId = _guestCustomerTracking.generateCustomerId();
      final createdAt = DateTime.now().toIso8601String();

      await _localStorage.saveCustomerInfo(
        name: customerName,
        phone: customerPhone,
        orderType: orderType,
      );

      // 1. Save to Supabase FIRST so we get the UUID back
      String? supabaseId;
      try {
        final res = await SupabaseService.client
            .from(SupabaseService.tableOrders)
            .insert({
              'order_number': orderId,
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
              },
              'items': items,
              'created_at': createdAt,
            })
            .select('id')
            .single();
        supabaseId = res['id'] as String;

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
        },
        'payment_method': paymentMethod,
        'status': 'pending',
        'created_at': createdAt,
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

  Future<void> clearAllOrders() async {
    await _localStorage.clearAllOrders();
    await _sharedOrders.clearAllOrders();
    await fetchOrders();
  }
}
