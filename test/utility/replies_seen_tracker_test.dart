import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Utility/replies_seen_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mantiene un cursore separato per ogni utente', () async {
    final firstSeen = DateTime.parse('2026-08-03T10:00:00Z');
    final secondSeen = DateTime.parse('2026-08-03T11:00:00Z');

    await RepliesSeenTracker.markAt(firstSeen, userId: 'user-1');
    await RepliesSeenTracker.markAt(secondSeen, userId: 'user-2');

    expect(await RepliesSeenTracker.lastSeen(userId: 'user-1'), firstSeen);
    expect(await RepliesSeenTracker.lastSeen(userId: 'user-2'), secondSeen);
  });

  test('non arretra il cursore quando arriva un evento più vecchio', () async {
    final newest = DateTime.parse('2026-08-03T12:00:00Z');
    final older = DateTime.parse('2026-08-03T09:00:00Z');

    await RepliesSeenTracker.markAt(newest, userId: 'user-1');
    await RepliesSeenTracker.markAt(older, userId: 'user-1');

    expect(await RepliesSeenTracker.lastSeen(userId: 'user-1'), newest);
  });
}
