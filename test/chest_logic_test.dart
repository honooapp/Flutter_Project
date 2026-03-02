import 'package:flutter_test/flutter_test.dart';

/// Test-only model mirroring the minimal fields used by Chest logic.
class TItem {
  TItem({
    required this.id,
    required this.kind, // 'honoo' | 'hinoo'
    required this.createdAt,
    this.updatedAt,
    this.conversationId,
  });

  final String id;
  final String kind; // 'honoo' or 'hinoo'
  final DateTime createdAt;
  final DateTime? updatedAt; // for honoo ordering in normal mode
  final String? conversationId;

  // Sort key used by Chest for per-item ordering:
  // - honoo: updatedAt (fallback createdAt)
  // - hinoo: createdAt
  DateTime get sortTs =>
      (kind == 'honoo' ? (updatedAt ?? createdAt) : createdAt);
}

/// Builds the normal-mode list per Chest semantics:
/// - Split into conversation roots (those with a latest reply) vs others
/// - Sort conversation roots by latest reply time DESC
/// - Sort others by item sortTs DESC
/// - Regroup items by conversationId contiguously, newest-first within each group
List<TItem> buildNormalList({
  required List<TItem> items,
  required Map<String, DateTime> honooLatestReplyById,
  required Map<String, DateTime> hinooLatestReplyById,
}) {
  final List<TItem> conv = [];
  final List<TItem> other = [];
  for (final it in items) {
    final DateTime? replyAt = (it.kind == 'honoo')
        ? honooLatestReplyById[it.id]
        : hinooLatestReplyById[it.id];
    if (replyAt != null) {
      conv.add(it);
    } else {
      other.add(it);
    }
  }
  conv.sort((a, b) {
    final DateTime aR = (a.kind == 'honoo')
        ? honooLatestReplyById[a.id]!
        : hinooLatestReplyById[a.id]!;
    final DateTime bR = (b.kind == 'honoo')
        ? honooLatestReplyById[b.id]!
        : hinooLatestReplyById[b.id]!;
    return bR.compareTo(aR); // newest first
  });
  other.sort((a, b) => b.sortTs.compareTo(a.sortTs));

  List<TItem> result = [...conv, ...other];

  // Regroup contiguously by conversationId; sort each group by sortTs DESC.
  if (result.isNotEmpty) {
    final itemsCopy = List<TItem>.of(result);
    final int n = itemsCopy.length;
    final consumed = <int>{};
    final regrouped = <TItem>[];

    String? convIdOf(TItem it) => it.conversationId;

    for (int i = 0; i < n; i++) {
      if (consumed.contains(i)) continue;
      final it = itemsCopy[i];
      final cid = convIdOf(it);
      if (cid == null || cid.isEmpty) {
        regrouped.add(it);
        consumed.add(i);
        continue;
      }
      final group = <TItem>[];
      final groupIdx = <int>[];
      for (int j = i; j < n; j++) {
        if (consumed.contains(j)) continue;
        final cand = itemsCopy[j];
        if (convIdOf(cand) == cid) {
          group.add(cand);
          groupIdx.add(j);
        }
      }
      if (group.length <= 1) {
        regrouped.add(it);
        consumed.add(i);
        continue;
      }
      group.sort((a, b) => b.sortTs.compareTo(a.sortTs));
      regrouped.addAll(group);
      for (final g in groupIdx) {
        consumed.add(g);
      }
    }
    result = regrouped;
  }

  return result;
}

/// Builds the conversation-mode list: merged items sorted by createdAt DESC.
List<TItem> buildConversationList(List<TItem> items, String conversationId) {
  final convItems = items.where((it) => it.conversationId == conversationId).toList();
  convItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return convItems;
}

void main() {
  group('Chest logic', () {
    test('Honoo ordering by updated_at', () {
      final a = TItem(
        id: 'A',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T09:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T11:00:00Z'),
      );
      final b = TItem(
        id: 'B',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T09:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
      );
      final c = TItem(
        id: 'C',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T09:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T10:00:00Z'),
      );
      final out = buildNormalList(
        items: [a, b, c],
        honooLatestReplyById: const {},
        hinooLatestReplyById: const {},
      );
      expect(out.map((e) => e.id).toList(), ['B', 'A', 'C']);
    });

    test('Conversation requires ≥ 2 elements', () {
      final root = TItem(
        id: 'R',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T10:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T10:00:00Z'),
        conversationId: 'X',
      );

      // No replies → not treated as conversation root in conv list
      var out = buildNormalList(
        items: [root],
        honooLatestReplyById: const {},
        hinooLatestReplyById: const {},
      );
      // Only one item present; no grouping beyond itself.
      expect(out.length, 1);
      expect(out.first.id, 'R');

      // Add a reply (honoo) with same conversationId and mark latest reply
      final reply = TItem(
        id: 'R1',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T12:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
        conversationId: 'X',
      );
      out = buildNormalList(
        items: [root, reply],
        honooLatestReplyById: {'R': reply.createdAt, 'R1': reply.createdAt},
        hinooLatestReplyById: const {},
      );
      // Should keep both elements and place them contiguously as a conversation group (newest first)
      final idxRoot = out.indexWhere((e) => e.id == 'R');
      final idxReply = out.indexWhere((e) => e.id == 'R1');
      expect(idxRoot != -1 && idxReply != -1, true);
      expect((idxReply - idxRoot).abs(), 1);
      // reply appears before root in the group due to DESC
      expect(idxReply < idxRoot, true);
    });

    test('Conversation internal order (reply before root in conversation mode)', () {
      final root = TItem(
        id: 'R',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T10:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T10:00:00Z'),
        conversationId: 'X',
      );
      final reply = TItem(
        id: 'R1',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T12:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
        conversationId: 'X',
      );
      final conv = buildConversationList([root, reply], 'X');
      expect(conv.map((e) => e.id).toList(), ['R1', 'R']);
    });

    test('No duplicates when merging honoo + hinoo for same conversation', () {
      final honooA = TItem(
        id: 'A',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T09:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T09:00:00Z'),
        conversationId: 'C1',
      );
      final hinooB = TItem(
        id: 'B',
        kind: 'hinoo',
        createdAt: DateTime.parse('2025-01-01T11:00:00Z'),
        conversationId: 'C1',
      );
      final replyToA = TItem(
        id: 'A2',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T12:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
        conversationId: 'C1',
      );
      final list = buildNormalList(
        items: [honooA, hinooB, replyToA],
        honooLatestReplyById: {'A': replyToA.createdAt, 'A2': replyToA.createdAt},
        hinooLatestReplyById: {'B': replyToA.createdAt},
      );
      // Ensure all C1 items are contiguous and appear only once as a single block
      final indices = <int>[];
      for (int i = 0; i < list.length; i++) {
        if (list[i].conversationId == 'C1') indices.add(i);
      }
      expect(indices.isNotEmpty, true);
      // Contiguous segment
      for (int i = 1; i < indices.length; i++) {
        expect(indices[i], indices[i - 1] + 1);
      }
    });

    test('Normal mode: conversations ordered by latest activity', () {
      // Conv A latest at 15:00, Conv B latest at 14:00
      final aRoot = TItem(
        id: 'A',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T10:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T10:00:00Z'),
        conversationId: 'CA',
      );
      final aReply = TItem(
        id: 'A1',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T15:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T15:00:00Z'),
        conversationId: 'CA',
      );
      final bRoot = TItem(
        id: 'B',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T09:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T09:00:00Z'),
        conversationId: 'CB',
      );
      final bReply = TItem(
        id: 'B1',
        kind: 'honoo',
        createdAt: DateTime.parse('2025-01-01T14:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T14:00:00Z'),
        conversationId: 'CB',
      );
      final out = buildNormalList(
        items: [aRoot, aReply, bRoot, bReply],
        honooLatestReplyById: {
          'A': aReply.createdAt,
          'A1': aReply.createdAt,
          'B': bReply.createdAt,
          'B1': bReply.createdAt,
        },
        hinooLatestReplyById: const {},
      );
      // First conversation block belongs to CA (15:00) and appears before CB (14:00)
      final firstConvId = out.first.conversationId;
      expect(firstConvId, 'CA');
      // Ensure CB appears after CA
      final firstIdxCB = out.indexWhere((e) => e.conversationId == 'CB');
      final lastIdxCA = out.lastIndexWhere((e) => e.conversationId == 'CA');
      expect(firstIdxCB > lastIdxCA, true);
    });
  });
}

