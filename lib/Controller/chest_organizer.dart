class ChestOrganization<T> {
  const ChestOrganization({
    required this.items,
    required this.conversationItemCount,
  });

  final List<T> items;
  final int conversationItemCount;
}

/// Regole pure di ordinamento e raggruppamento dello Scrigno.
class ChestOrganizer {
  const ChestOrganizer._();

  static ChestOrganization<T> organize<T>({
    required List<T> items,
    required DateTime Function(T item) createdAtOf,
    required String Function(T item) stableIdOf,
    required DateTime? Function(T item) latestReplyOf,
    required String? Function(T item) conversationIdOf,
  }) {
    int compareCreatedAt(T a, T b) {
      final byCreated = createdAtOf(b).compareTo(createdAtOf(a));
      if (byCreated != 0) return byCreated;
      return stableIdOf(a).compareTo(stableIdOf(b));
    }

    DateTime activityOf(T item) {
      final createdAt = createdAtOf(item);
      final latestReply = latestReplyOf(item);
      return latestReply != null && latestReply.isAfter(createdAt)
          ? latestReply
          : createdAt;
    }

    final ordered = List<T>.of(items)
      ..sort((a, b) {
        final byActivity = activityOf(b).compareTo(activityOf(a));
        return byActivity != 0 ? byActivity : compareCreatedAt(a, b);
      });
    final regrouped = <T>[];
    final consumed = <int>{};

    for (var i = 0; i < ordered.length; i++) {
      if (consumed.contains(i)) continue;
      final item = ordered[i];
      final conversationId = conversationIdOf(item);
      if (conversationId == null || conversationId.isEmpty) {
        regrouped.add(item);
        consumed.add(i);
        continue;
      }

      final group = <T>[];
      final groupIndexes = <int>[];
      for (var j = i; j < ordered.length; j++) {
        if (consumed.contains(j)) continue;
        final candidate = ordered[j];
        if (conversationIdOf(candidate) == conversationId) {
          group.add(candidate);
          groupIndexes.add(j);
        }
      }

      if (group.length <= 1) {
        regrouped.add(item);
        consumed.add(i);
        continue;
      }

      group.sort((a, b) {
        final byActivity = activityOf(b).compareTo(activityOf(a));
        return byActivity != 0 ? byActivity : compareCreatedAt(a, b);
      });
      // Ogni conversazione occupa una sola slide del carosello. La slide
      // renderizza poi l'intero thread tramite UnifiedThreadView.
      regrouped.add(group.first);
      consumed.addAll(groupIndexes);
    }

    return ChestOrganization<T>(
      items: List.unmodifiable(regrouped),
      conversationItemCount: items
          .where((item) => latestReplyOf(item) != null)
          .length,
    );
  }
}
