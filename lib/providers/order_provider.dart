import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/shared_orders_service.dart';
import '../services/guest_customer_tracking_service.dart';
import '../services/supabase_service.dart';
import '../services/razorpay_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  final _localStorage = LocalStorageService();
  final _sharedOrders = SharedOrdersService();
  final _guestCustomerTracking = GuestCustomerTrackingService();

  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;

  /// Online order: server computes the price, creates the Razorpay order,
  /// runs checkout, and finalizes the order after verifying the signature.
  /// The client never sends prices.
  Future<PlaceOrderResult> placeOnlineOrder({
    required String customerName,
    required String customerPhone,
    required String orderType,
    required List<Map<String, dynamic>> items, // [{menu_item_id, quantity}]
    Map<String, String>? deliveryAddress,
  }) async {
    final r = await RazorpayService().placeOnlineOrder(
      items: items,
      customerName: customerName,
      customerPhone: customerPhone,
      orderType: orderType,
      deliveryAddress: deliveryAddress,
    );
    if (!r.success) return r;

    await _mirrorLocal(
      orderNumber: r.orderNumber ?? '',
      dbOrderId: r.dbOrderId,
      lineItems: r.items ?? const [],
      totalPrice: r.totalPrice ?? 0,
      customerName: customerName,
      customerPhone: customerPhone,
      orderType: orderType,
      deliveryAddress: deliveryAddress,
      paymentMethod: 'online',
      paymentDetails: {'provider': 'razorpay', 'status': 'paid'},
    );
    await fetchOrders();
    return r;
  }

  /// Cash order: server computes the price and stores the order. No payment.
  Future<String> placeCodOrder({
    required String customerName,
    required String customerPhone,
    required String orderType,
    required List<Map<String, dynamic>> items, // [{menu_item_id, quantity}]
    Map<String, String>? deliveryAddress,
  }) async {
    final res = await SupabaseService.client.functions.invoke(
      'razorpay-create-order',
      body: {
        'payment_method': 'cod',
        'order_type': orderType,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'items': items,
        if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      },
    );
    final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
    if (data['orderNumber'] == null) {
      throw Exception(data['error']?.toString() ?? 'Could not place order');
    }
    final orderNumber = data['orderNumber'].toString();

    await _mirrorLocal(
      orderNumber: orderNumber,
      dbOrderId: data['dbOrderId']?.toString(),
      lineItems: (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0,
      customerName: customerName,
      customerPhone: customerPhone,
      orderType: orderType,
      deliveryAddress: deliveryAddress,
      paymentMethod: 'cod',
      paymentDetails: null,
    );
    await fetchOrders();
    return orderNumber;
  }

  /// Mirror the server-created order into local storage so the confirmation
  /// and "my orders" screens (which read locally) keep working.
  Future<void> _mirrorLocal({
    required String orderNumber,
    required String? dbOrderId,
    required List<Map<String, dynamic>> lineItems,
    required double totalPrice,
    required String customerName,
    required String customerPhone,
    required String orderType,
    required Map<String, String>? deliveryAddress,
    required String paymentMethod,
    required Map<String, dynamic>? paymentDetails,
  }) async {
    final createdAt = DateTime.now().toIso8601String();
    final customerId = _guestCustomerTracking.generateCustomerId();

    await _localStorage.saveCustomerInfo(
      name: customerName,
      phone: customerPhone,
      orderType: orderType,
    );

    final orderData = {
      'id': orderNumber,
      'supabase_id': dbOrderId,
      'customer_id': customerId,
      'items': lineItems,
      'total_price': totalPrice,
      'order_type': orderType,
      'customer_info': {
        'name': customerName,
        'phone': customerPhone,
        'order_type': orderType,
        if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        if (paymentDetails != null) 'payment': paymentDetails,
      },
      'payment_method': paymentMethod,
      'status': 'pending',
      'created_at': createdAt,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
    };

    await _localStorage.saveOrder(
      orderId: orderNumber,
      items: lineItems,
      totalPrice: totalPrice,
      orderType: orderType,
    );
    await _sharedOrders.saveOrderToShared(
      orderId: orderNumber,
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
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _sharedOrders.init();
      _orders = _sharedOrders.getAllOrders();
      _orders.sort((a, b) => DateTime.parse(b['created_at'] as String)
          .compareTo(DateTime.parse(a['created_at'] as String)));

      // Sync status from the server (orders are no longer anon-readable, so we
      // ask get-order-status for just our own order ids).
      final ids =
          _orders.map((o) => o['supabase_id']).whereType<String>().toList();
      if (ids.isNotEmpty) {
        try {
          final res = await SupabaseService.client.functions
              .invoke('get-order-status', body: {'ids': ids});
          final list = ((res.data as Map?)?['orders'] as List?) ?? const [];
          final statusById = <String, dynamic>{
            for (final r in list) (r as Map)['id']: r['status'],
          };
          for (var i = 0; i < _orders.length; i++) {
            final sid = _orders[i]['supabase_id'];
            if (sid != null && statusById[sid] != null) {
              _orders[i] = Map<String, dynamic>.from(_orders[i])
                ..['status'] = statusById[sid];
            }
          }
        } catch (_) {/* keep local statuses */}
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    // Customer-side status is mirrored locally; the server is the source of
    // truth (admin updates it, and fetchOrders re-syncs from get-order-status).
    await _sharedOrders.updateOrderStatus(orderId, newStatus);
    await fetchOrders();
  }

  /// Customer-initiated cancel. Reflects locally; a server-side `cancel-order`
  /// edge function is still TODO to also flip the DB row (anon can't write it).
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _sharedOrders.updateOrderStatus(orderId, 'cancelled');
      await fetchOrders();
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return false;
    }
  }

  Future<void> clearAllOrders() async {
    await _localStorage.clearAllOrders();
    await _sharedOrders.clearAllOrders();
    await fetchOrders();
  }
}
