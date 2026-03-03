import 'package:flutter_test/flutter_test.dart';

class _Item {
  final DateTime createdAt;
  final String id;
  final DateTime? latestReply;
  const _Item({required this.createdAt, required this.id, this.latestReply});
}

int _cmpOtherItems(_Item a, _Item b) {
  final int byCreated = b.createdAt.compareTo(a.createdAt);
  if (byCreated != 0) return byCreated;
  return a.id.compareTo(b.id);
}

int _cmpConversationItems(_Item a, _Item b) {
  final DateTime? aReply = a.latestReply;
  final DateTime? bReply = b.latestReply;
  if (aReply == null && bReply == null) {
    final int byCreated = b.createdAt.compareTo(a.createdAt);
    if (byCreated != 0) return byCreated;
    return a.id.compareTo(b.id);
  }
  if (aReply == null) return 1;
  if (bReply == null) return -1;
  final int byLatest = bReply.compareTo(aReply);
  if (byLatest != 0) return byLatest;
  final int byCreated = b.createdAt.compareTo(a.createdAt);
  if (byCreated != 0) return byCreated;
  return a.id.compareTo(b.id);
}

void main() {
  group('Chest ordering determinism', () {
    test('otherItems: createdAt DESC, then stable id', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final items = <_Item>[
        _Item(createdAt: now, id: 'b'),
        _Item(createdAt: now, id: 'a'),
        _Item(createdAt: now.add(const Duration(seconds: 1)), id: 'z'),
        _Item(createdAt: now.subtract(const Duration(seconds: 1)), id: 'm'),
      ];
      items.sort(_cmpOtherItems);
      expect(items.map((e) => e.id).toList(), ['z', 'a', 'b', 'm']);
    });

    test('conversationItems: latestReply DESC, then createdAt DESC, then id', () {
      final t1 = DateTime(2024, 1, 1, 12, 0, 0);
      final t2 = t1.add(const Duration(seconds: 10));
      final t3 = t1.add(const Duration(seconds: 20));
      final items = <_Item>[
        _Item(createdAt: t1, id: 'c', latestReply: t2),
        _Item(createdAt: t2, id: 'b', latestReply: t2), // same latest, newer createdAt
        _Item(createdAt: t2, id: 'a', latestReply: t2), // same latest & createdAt, id tie-breaker
        _Item(createdAt: t3, id: 'z', latestReply: t1), // older latestReply
      ];
      items.sort(_cmpConversationItems);
      expect(items.map((e) => e.id).toList(), ['b', 'a', 'c', 'z']);
    });

    test('epoch fallback sorts last under DESC createdAt', () {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      final real = DateTime(2024, 1, 1, 0, 0, 0);
      final items = <_Item>[
        _Item(createdAt: epoch, id: 'e'),
        _Item(createdAt: real, id: 'r'),
      ];
      items.sort(_cmpOtherItems);
      expect(items.map((e) => e.id).toList(), ['r', 'e']);
    });
  });
}

