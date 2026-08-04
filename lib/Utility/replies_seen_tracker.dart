import 'package:shared_preferences/shared_preferences.dart';

import 'reply_notification_signal.dart';

class RepliesSeenTracker {
  static const _key = 'last_seen_reply_at_v1';

  static String _keyFor(String? userId) {
    final normalized = userId?.trim() ?? '';
    return normalized.isEmpty ? _key : '${_key}_$normalized';
  }

  static Future<DateTime?> lastSeen({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyFor(userId));
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static Future<void> markNow({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(userId),
      DateTime.now().toUtc().toIso8601String(),
    );
    ReplyNotificationSignal.notifyChanged();
  }

  static Future<void> markAt(DateTime dt, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(userId);
    final current = DateTime.tryParse(prefs.getString(key) ?? '');
    if (current != null && !dt.isAfter(current)) return;
    await prefs.setString(key, dt.toUtc().toIso8601String());
    ReplyNotificationSignal.notifyChanged();
  }
}
