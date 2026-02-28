import 'package:shared_preferences/shared_preferences.dart';

class RepliesSeenTracker {
  static const _key = 'last_seen_reply_at_v1';

  static Future<DateTime?> lastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static Future<void> markNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, DateTime.now().toIso8601String());
  }

  static Future<void> markAt(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, dt.toIso8601String());
  }
}

