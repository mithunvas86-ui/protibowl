import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Typed handle to the global `Razorpay` checkout object (from checkout.js).
@JS('Razorpay')
extension type _RazorpayJS._(JSObject _) implements JSObject {
  external _RazorpayJS(JSObject options);
  external void open();
  external void on(JSString event, JSFunction handler);
}

/// Result of placing an online order (create → pay → verify).
class PlaceOrderResult {
  final bool success;
  final String message;
  final String? orderNumber;
  final String? dbOrderId;
  final double? totalPrice;
  final List<Map<String, dynamic>>? items;

  const PlaceOrderResult({
    required this.success,
    required this.message,
    this.orderNumber,
    this.dbOrderId,
    this.totalPrice,
    this.items,
  });

  factory PlaceOrderResult.fail(String message) =>
      PlaceOrderResult(success: false, message: message);
}

/// Online-payment flow for the **web** customer app — fully server-driven.
///
///   1. `razorpay-create-order` computes the price from the DB, creates the
///      Razorpay order, and stores a pending order. The client sends only item
///      ids + quantities — never prices.
///   2. Razorpay checkout.js opens for that order (JS interop).
///   3. `razorpay-verify-payment` validates the signature and finalizes the
///      order server-side. Only a verified payment returns success.
class RazorpayService {
  final _supabase = Supabase.instance.client;

  Future<PlaceOrderResult> placeOnlineOrder({
    required List<Map<String, dynamic>> items, // [{menu_item_id, quantity}]
    required String customerName,
    required String customerPhone,
    required String orderType,
    Map<String, String>? deliveryAddress,
  }) async {
    if (!kIsWeb) {
      return PlaceOrderResult.fail('Online payment is only available on the web');
    }
    if (!globalContext.has('Razorpay')) {
      return PlaceOrderResult.fail(
          'Payment library not loaded. Please refresh and try again.');
    }

    // 1. Server creates the order + Razorpay order (price computed server-side).
    final String razorpayOrderId, keyId, currency;
    final num amountPaise;
    final String? orderNumber, dbOrderId;
    final double? totalPrice;
    final List<Map<String, dynamic>>? lineItems;
    try {
      final res = await _supabase.functions.invoke(
        'razorpay-create-order',
        body: {
          'payment_method': 'online',
          'order_type': orderType,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'items': items,
          if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        },
      );
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      if (data['razorpayOrderId'] == null || data['keyId'] == null) {
        return PlaceOrderResult.fail(
            data['error']?.toString() ?? 'Could not start order');
      }
      razorpayOrderId = data['razorpayOrderId'] as String;
      keyId = data['keyId'] as String;
      amountPaise = (data['amount'] as num?) ?? 0;
      currency = (data['currency'] as String?) ?? 'INR';
      orderNumber = data['orderNumber']?.toString();
      dbOrderId = data['dbOrderId']?.toString();
      totalPrice = (data['totalPrice'] as num?)?.toDouble();
      lineItems = (data['items'] as List?)?.cast<Map<String, dynamic>>();
    } catch (e) {
      return PlaceOrderResult.fail('Could not start order: $e');
    }

    // 2. Open Razorpay checkout for that order.
    final payment = await _openCheckout(
      keyId: keyId,
      amountPaise: amountPaise,
      currency: currency,
      orderId: razorpayOrderId,
      customerName: customerName,
      customerPhone: customerPhone,
    );
    if (payment == null) return PlaceOrderResult.fail('Payment cancelled');

    // 3. Server verifies the signature and finalizes the order.
    try {
      final res = await _supabase.functions.invoke(
        'razorpay-verify-payment',
        body: {
          'razorpay_order_id': payment['razorpay_order_id'],
          'razorpay_payment_id': payment['razorpay_payment_id'],
          'razorpay_signature': payment['razorpay_signature'],
        },
      );
      final v = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      if (v['verified'] == true) {
        return PlaceOrderResult(
          success: true,
          message: 'Payment successful',
          orderNumber: v['orderNumber']?.toString() ?? orderNumber,
          dbOrderId: v['dbOrderId']?.toString() ?? dbOrderId,
          totalPrice: (v['totalPrice'] as num?)?.toDouble() ?? totalPrice,
          items: (v['items'] as List?)?.cast<Map<String, dynamic>>() ?? lineItems,
        );
      }
      return PlaceOrderResult.fail('Payment verification failed');
    } catch (e) {
      return PlaceOrderResult.fail('Verification error: $e');
    }
  }

  Future<Map<String, String>?> _openCheckout({
    required String keyId,
    required num amountPaise,
    required String currency,
    required String orderId,
    required String customerName,
    required String customerPhone,
  }) async {
    final completer = Completer<Map<String, String>?>();
    void complete(Map<String, String>? v) {
      if (!completer.isCompleted) completer.complete(v);
    }

    final prefill = JSObject()
      ..setProperty('name'.toJS, customerName.toJS)
      ..setProperty('contact'.toJS, customerPhone.toJS);
    final theme = JSObject()..setProperty('color'.toJS, '#9F402D'.toJS);
    final modal = JSObject()
      ..setProperty('ondismiss'.toJS, (() => complete(null)).toJS);

    final options = JSObject()
      ..setProperty('key'.toJS, keyId.toJS)
      ..setProperty('amount'.toJS, amountPaise.toDouble().toJS)
      ..setProperty('currency'.toJS, currency.toJS)
      ..setProperty('name'.toJS, 'Proti Bowls'.toJS)
      ..setProperty('image'.toJS,
          'https://mithunvas86-ui.github.io/protibowl/icons/Icon-512.png'.toJS)
      ..setProperty('description'.toJS, 'Order Payment'.toJS)
      ..setProperty('order_id'.toJS, orderId.toJS)
      ..setProperty('prefill'.toJS, prefill)
      ..setProperty('theme'.toJS, theme)
      ..setProperty('modal'.toJS, modal)
      ..setProperty(
        'handler'.toJS,
        ((JSObject resp) {
          String read(String k) =>
              (resp.getProperty(k.toJS) as JSString?)?.toDart ?? '';
          complete({
            'razorpay_payment_id': read('razorpay_payment_id'),
            'razorpay_order_id': read('razorpay_order_id'),
            'razorpay_signature': read('razorpay_signature'),
          });
        }).toJS,
      );

    final rzp = _RazorpayJS(options);
    rzp.on('payment.failed'.toJS, ((JSObject _) => complete(null)).toJS);
    rzp.open();
    return completer.future;
  }
}
