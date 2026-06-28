import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final _supabase = Supabase.instance.client;

  /// WhatsApp integration disabled - using thermal printer only
  /// Left for reference - can be re-enabled in future if needed
  // Future<bool> sendOrderToWhatsApp({...}) async { ... }

  /// Trigger thermal printer to print bill
  Future<bool> printBillToThermalPrinter({
    required String orderId,
    required String customerName,
    required String customerPhone,
    required String orderType,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
  }) async {
    try {
      // Get printer configuration from app_config
      final config = await _supabase
          .from('app_config')
          .select()
          .eq('key', 'thermal_printer_config')
          .single();

      final printerIp = config['value']['printer_ip'] as String?;
      final printerPort = config['value']['printer_port'] as int? ?? 9100;

      if (printerIp == null) {
        print('Thermal printer not configured');
        return false;
      }

      // Format bill content
      final itemsList = items
          .map((item) =>
              '${item['name'].padRight(20)}x${item['quantity'].toString().padLeft(2)}  ₹${(item['price'] * item['quantity']).toStringAsFixed(0).padLeft(6)}')
          .join('\n');

      final billContent = '''
═══════════════════════════
        PROTI BOWLS
═══════════════════════════
Order ID: #${orderId.toUpperCase()}
Time: ${DateTime.now().toString().split('.')[0]}
───────────────────────────
Customer: $customerName
Phone: $customerPhone
Type: ${orderType.toUpperCase()}
───────────────────────────
$itemsList
───────────────────────────
TOTAL: ₹${totalPrice.toStringAsFixed(0)}
═══════════════════════════
Thank you for your order!
═══════════════════════════
      '''.trim();

      // Send to thermal printer via Edge Function
      final response = await _supabase.functions.invoke(
        'print-to-thermal-printer',
        body: {
          'printerIp': printerIp,
          'printerPort': printerPort,
          'billContent': billContent,
          'orderId': orderId,
        },
      );

      if (response.status == 200) {
        print('Bill sent to thermal printer');
        return true;
      } else {
        print('Thermal printer print failed: ${response.data}');
        return false;
      }
    } catch (e) {
      print('Error printing to thermal printer: $e');
      return false;
    }
  }

  /// Print bill after order creation (WhatsApp disabled)
  Future<Map<String, bool>> processOrderNotifications({
    required String orderId,
    required String customerName,
    required String customerPhone,
    required String orderType,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
  }) async {
    final results = <String, bool>{};

    // Print to thermal printer only
    results['printer'] = await printBillToThermalPrinter(
      orderId: orderId,
      customerName: customerName,
      customerPhone: customerPhone,
      orderType: orderType,
      items: items,
      totalPrice: totalPrice,
    );

    return results;
  }
}
