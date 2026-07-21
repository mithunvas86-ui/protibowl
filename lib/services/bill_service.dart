import 'dart:html' as html;
import 'supabase_service.dart';

/// Builds a printable HTML invoice for an order and opens it in a new tab,
/// auto-triggering the browser print dialog (so the customer can Save as PDF).
/// Business info + GST come from the admin-editable `bill_config`.
class BillService {
  static Future<void> download(Map<String, dynamic> order) async {
    Map<String, dynamic> cfg = {};
    try {
      final res = await SupabaseService.client
          .from('app_config')
          .select('value')
          .eq('key', 'bill_config')
          .maybeSingle();
      cfg = (res?['value'] as Map?)?.cast<String, dynamic>() ?? {};
    } catch (_) {/* defaults */}

    final doc = _build(order, cfg);
    final blob = html.Blob([doc], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
  }

  static String _money(num v) => '₹${v.toStringAsFixed(2)}';

  static String _build(Map<String, dynamic> order, Map<String, dynamic> cfg) {
    final items = (order['items'] as List?) ?? const [];
    double subtotal = 0;
    final rows = StringBuffer();
    for (final it in items) {
      final name = (it['name'] ?? 'Item').toString();
      final qty = (it['quantity'] as num?)?.toInt() ?? 1;
      final price = (it['price'] as num?)?.toDouble() ?? 0;
      final amt = price * qty;
      subtotal += amt;
      rows.write('<tr><td>$name</td><td class="c">$qty</td>'
          '<td class="r">${_money(price)}</td>'
          '<td class="r">${_money(amt)}</td></tr>');
    }

    final total = (order['total_price'] as num?)?.toDouble() ?? subtotal;
    final delivery = (total - subtotal) > 0.01 ? (total - subtotal) : 0.0;
    final gstPct = (cfg['gst_percent'] as num?)?.toDouble() ?? 0;
    final gstAmt = gstPct > 0 ? total * gstPct / (100 + gstPct) : 0; // inclusive

    final ci = (order['customer_info'] as Map?)?.cast<String, dynamic>() ?? {};
    final business = (cfg['business_name'] ?? 'Bill').toString();
    final address = (cfg['address'] ?? '').toString();
    final gstNo = (cfg['gst_number'] ?? '').toString();
    final footer = (cfg['footer'] ?? 'Thank you!').toString();
    final orderNo = (order['id'] ?? '').toString();
    final createdAt = (order['created_at'] ?? '').toString().split('T').first;
    final custName = (ci['name'] ?? '').toString();
    final custPhone = (ci['phone'] ?? '').toString();
    final orderType =
        (order['order_type'] ?? '').toString().replaceAll('_', ' ').toUpperCase();
    final gstLabel = gstPct % 1 == 0 ? gstPct.toStringAsFixed(0) : gstPct.toString();

    return '''<!doctype html><html><head><meta charset="utf-8">
<title>Bill #$orderNo</title>
<style>
  body{font-family:Arial,Helvetica,sans-serif;color:#111;max-width:480px;margin:24px auto;padding:0 16px;}
  h1{font-size:20px;margin:0;}
  .muted{color:#666;font-size:12px;}
  .hdr{border-bottom:2px solid #111;padding-bottom:10px;}
  .meta{margin-top:10px;font-size:12px;line-height:1.6;}
  table{width:100%;border-collapse:collapse;margin-top:14px;font-size:13px;}
  th,td{padding:6px 4px;border-bottom:1px solid #eee;text-align:left;}
  th{border-bottom:2px solid #111;}
  .r{text-align:right;} .c{text-align:center;}
  .tot td{border:none;padding:3px 4px;}
  .grand td{font-weight:bold;font-size:15px;border-top:2px solid #111;padding-top:8px;}
  .foot{margin-top:18px;text-align:center;}
  button{margin-top:18px;padding:10px 18px;background:#111;color:#fff;border:none;cursor:pointer;font-size:13px;}
  @media print{button{display:none;}}
</style></head><body>
<div class="hdr">
  <h1>$business</h1>
  ${address.isNotEmpty ? '<div class="muted">$address</div>' : ''}
  ${gstNo.isNotEmpty ? '<div class="muted">GSTIN: $gstNo</div>' : ''}
</div>
<div class="meta">
  <strong>TAX INVOICE</strong><br>
  Order #$orderNo &nbsp;&middot;&nbsp; $createdAt<br>
  ${custName.isNotEmpty ? '$custName &nbsp;&middot;&nbsp; $custPhone<br>' : ''}
  Type: $orderType
</div>
<table>
  <thead><tr><th>Item</th><th class="c">Qty</th><th class="r">Rate</th><th class="r">Amount</th></tr></thead>
  <tbody>$rows</tbody>
</table>
<table class="tot">
  <tr><td>Subtotal</td><td class="r">${_money(subtotal)}</td></tr>
  ${delivery > 0 ? '<tr><td>Delivery charge</td><td class="r">${_money(delivery)}</td></tr>' : ''}
  ${gstPct > 0 ? '<tr><td class="muted">Incl. GST @ $gstLabel%</td><td class="r muted">${_money(gstAmt)}</td></tr>' : ''}
  <tr class="grand"><td>TOTAL</td><td class="r">${_money(total)}</td></tr>
</table>
<div class="foot muted">$footer</div>
<button onclick="window.print()">Download / Save as PDF</button>
</body></html>''';
  }
}
