import 'package:flutter/material.dart';

import '../Entities/chest_item.dart';
import '../Entities/conversation_entry.dart';
import '../Entities/hinoo.dart';
import '../Entities/honoo.dart';
import 'honoo_colors.dart';

@immutable
class ChestContentStyle {
  const ChestContentStyle._({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.logoColor,
  });

  static const ChestContentStyle own = ChestContentStyle._(
    backgroundColor: HonooColor.background,
    foregroundColor: HonooColor.onBackground,
    logoColor: HonooColor.secondary,
  );

  static const ChestContentStyle moon = ChestContentStyle._(
    backgroundColor: HonooColor.tertiary,
    foregroundColor: HonooColor.onTertiary,
    logoColor: HonooColor.secondary,
  );

  static const ChestContentStyle receivedReply = ChestContentStyle._(
    backgroundColor: HonooColor.secondary,
    foregroundColor: Colors.white,
    logoColor: Colors.white,
  );

  final Color backgroundColor;
  final Color foregroundColor;
  final Color logoColor;

  static ChestContentStyle forHonoo(Honoo honoo, {String? viewerUserId}) {
    final isOwn = viewerUserId != null && honoo.userId == viewerUserId;
    if (honoo.type == HonooType.answer && !isOwn) return receivedReply;
    if (honoo.isFromMoonSaved && honoo.type != HonooType.answer) return moon;
    return own;
  }

  static ChestContentStyle forHinoo(
    HinooDraft draft, {
    String? authorId,
    String? viewerUserId,
    bool? isReply,
    bool? isFromMoonSaved,
  }) {
    final reply = isReply ?? draft.type == HinooType.answer;
    final fromMoon = isFromMoonSaved ?? draft.isFromMoonSaved;
    final isOwn = viewerUserId != null && authorId == viewerUserId;
    if (reply && !isOwn) return receivedReply;
    if (fromMoon && !reply) return moon;
    return own;
  }

  static ChestContentStyle forEntry(
    ConversationEntry entry, {
    String? viewerUserId,
  }) {
    switch (entry.kind) {
      case ConversationEntryKind.honoo:
        return forHonoo(entry.honoo!, viewerUserId: viewerUserId);
      case ConversationEntryKind.hinoo:
        return forHinoo(
          entry.hinoo!,
          authorId: entry.ownerId,
          viewerUserId: viewerUserId,
          isFromMoonSaved: entry.isFromMoonSaved,
        );
      case ConversationEntryKind.deleted:
        return own;
    }
  }

  /// Nella conversazione un contenuto proveniente dalla Luna identifica
  /// sempre il contenuto dell'altro autore, anche per i salvataggi storici.
  static ChestContentStyle forConversationEntry(
    ConversationEntry entry, {
    String? viewerUserId,
  }) {
    final isFromMoon = switch (entry.kind) {
      ConversationEntryKind.honoo =>
        entry.isFromMoonSaved ||
            entry.honoo!.isFromMoonSaved ||
            entry.honoo!.type == HonooType.moon,
      ConversationEntryKind.hinoo =>
        entry.isFromMoonSaved ||
            entry.hinoo!.isFromMoonSaved ||
            entry.hinoo!.type == HinooType.moon,
      ConversationEntryKind.deleted => false,
    };
    if (isFromMoon) return receivedReply;
    return forEntry(entry, viewerUserId: viewerUserId);
  }

  static ChestContentStyle forItem(ChestItem item, {String? viewerUserId}) {
    return item.when(
      honoo: (honoo) => forHonoo(honoo, viewerUserId: viewerUserId),
      hinoo: (hinoo) => forHinoo(
        hinoo.draft,
        authorId: hinoo.ownerId,
        viewerUserId: viewerUserId,
        isFromMoonSaved: hinoo.isFromMoonSaved,
      ),
    );
  }
}
