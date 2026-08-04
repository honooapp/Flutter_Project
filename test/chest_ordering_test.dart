import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Controller/chest_organizer.dart';

class _Item {
  const _Item({
    required this.id,
    required this.createdAt,
    this.latestReply,
    this.conversationId,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? latestReply;
  final String? conversationId;
}

ChestOrganization<_Item> _organize(List<_Item> items) {
  return ChestOrganizer.organize<_Item>(
    items: items,
    createdAtOf: (item) => item.createdAt,
    stableIdOf: (item) => item.id,
    latestReplyOf: (item) => item.latestReply,
    conversationIdOf: (item) => item.conversationId,
  );
}

void main() {
  group('ChestOrganizer', () {
    test('ordina gli elementi normali per data DESC e id stabile', () {
      final now = DateTime(2024, 1, 1, 12);
      final result = _organize([
        _Item(createdAt: now, id: 'b'),
        _Item(createdAt: now, id: 'a'),
        _Item(createdAt: now.add(const Duration(seconds: 1)), id: 'z'),
        _Item(createdAt: now.subtract(const Duration(seconds: 1)), id: 'm'),
      ]);

      expect(result.items.map((item) => item.id), ['z', 'a', 'b', 'm']);
      expect(result.conversationItemCount, 0);
    });

    test('mette prima le conversazioni ordinate per ultima risposta', () {
      final t1 = DateTime(2024, 1, 1, 12);
      final t2 = t1.add(const Duration(seconds: 10));
      final result = _organize([
        _Item(createdAt: t1, id: 'c', latestReply: t2),
        _Item(createdAt: t2, id: 'b', latestReply: t2),
        _Item(createdAt: t2, id: 'a', latestReply: t2),
        _Item(createdAt: t2, id: 'normal'),
      ]);

      expect(result.items.map((item) => item.id), ['a', 'b', 'normal', 'c']);
      expect(result.conversationItemCount, 3);
    });

    test(
      'il contenuto salvato più di recente precede conversazioni più vecchie',
      () {
        final old = DateTime(2024, 1, 1, 12);
        final recent = old.add(const Duration(minutes: 5));
        final result = _organize([
          _Item(
            createdAt: old,
            id: 'conversation',
            latestReply: old.add(const Duration(minutes: 1)),
            conversationId: 'conversation-1',
          ),
          _Item(createdAt: recent, id: 'just-saved'),
        ]);

        expect(result.items.map((item) => item.id), [
          'just-saved',
          'conversation',
        ]);
      },
    );

    test('mostra una sola slide per conversazione usando il più recente', () {
      final t1 = DateTime(2024, 1, 1, 12);
      final t2 = t1.add(const Duration(seconds: 10));
      final result = _organize([
        _Item(
          createdAt: t1,
          id: 'root',
          latestReply: t2,
          conversationId: 'conversation-1',
        ),
        _Item(createdAt: t2, id: 'outside'),
        _Item(createdAt: t2, id: 'reply', conversationId: 'conversation-1'),
      ]);

      expect(result.items.map((item) => item.id), ['outside', 'reply']);
    });

    test('non modifica la lista ricevuta', () {
      final input = [
        _Item(createdAt: DateTime(2024, 1, 2), id: 'new'),
        _Item(createdAt: DateTime(2024, 1, 1), id: 'old'),
      ];

      final result = _organize(input.reversed.toList());

      expect(result.items.map((item) => item.id), ['new', 'old']);
      expect(() => result.items.add(input.first), throwsUnsupportedError);
    });
  });
}
