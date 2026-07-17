import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';

enum ConversationEntryKind { honoo, hinoo }

class ConversationEntry {
  final ConversationEntryKind kind;
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final String? ownerId;
  final bool isFromMoonSaved;
  final DateTime createdAt;

  ConversationEntry._(this.kind, {
    required this.createdAt,
    this.honoo,
    this.hinoo,
    this.ownerId,
    this.isFromMoonSaved = false,
  });

  factory ConversationEntry.honoo(Honoo h) => ConversationEntry._(
        ConversationEntryKind.honoo,
        honoo: h,
        createdAt: DateTime.tryParse(h.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        ownerId: h.userId,
        isFromMoonSaved: h.isFromMoonSaved,
      );

  factory ConversationEntry.hinoo(
    HinooDraft d, {
    required DateTime createdAt,
    String? ownerId,
    bool isFromMoonSaved = false,
  }) =>
      ConversationEntry._(
        ConversationEntryKind.hinoo,
        hinoo: d,
        createdAt: createdAt,
        ownerId: ownerId,
        isFromMoonSaved: isFromMoonSaved,
      );
}
