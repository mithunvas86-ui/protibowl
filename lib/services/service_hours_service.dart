import 'package:flutter/material.dart';
import 'supabase_service.dart';

/// Reads per order-type availability windows (set by the admin) and tells the
/// order form whether dine_in / takeaway / delivery can be ordered right now.
class ServiceHoursService {
  static final _instance = ServiceHoursService._();
  factory ServiceHoursService() => _instance;
  ServiceHoursService._();

  Map<String, dynamic> _hours = {};

  Future<void> load() async {
    try {
      final res = await SupabaseService.client
          .from('app_config')
          .select('value')
          .eq('key', 'service_hours')
          .maybeSingle();
      _hours = (res?['value'] as Map?)?.cast<String, dynamic>() ?? {};
    } catch (_) {/* fail open — no config means everything available */}
  }

  Map<String, dynamic>? _cfg(String type) =>
      (_hours[type] as Map?)?.cast<String, dynamic>();

  /// True if this order type can be ordered at the current local time.
  bool isAvailable(String type) {
    final c = _cfg(type);
    if (c == null) return true; // no config → allow
    if ((c['enabled'] as bool?) == false) return false;
    final open = _parse(c['open'] as String?);
    final close = _parse(c['close'] as String?);
    if (open == null || close == null) return true;
    final now = TimeOfDay.fromDateTime(DateTime.now());
    final n = now.hour * 60 + now.minute;
    final o = open.hour * 60 + open.minute;
    final cl = close.hour * 60 + close.minute;
    return n >= o && n < cl;
  }

  /// A friendly window label, e.g. "9:00 AM – 9:00 PM", or "Unavailable".
  String label(String type) {
    final c = _cfg(type);
    if (c == null) return '';
    if ((c['enabled'] as bool?) == false) return 'Currently unavailable';
    final o = c['open'] as String?;
    final cl = c['close'] as String?;
    if (o == null || cl == null) return '';
    return '${_fmt(o)} – ${_fmt(cl)}';
  }

  TimeOfDay? _parse(String? s) {
    if (s == null || !s.contains(':')) return null;
    final p = s.split(':');
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(String? s) {
    final t = _parse(s);
    if (t == null) return s ?? '';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final ap = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:${t.minute.toString().padLeft(2, '0')} $ap';
  }
}
