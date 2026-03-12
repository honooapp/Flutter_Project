import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';

enum ConversationEntryKind { honoo, hinoo }

class ConversationEntry {
  final ConversationEntryKind kind;
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final String? ownerId;
  final bool isFromMoonSaved;

  ConversationEntry._(this.kind, {this.honoo, this.hinoo, this.ownerId, this.isFromMoonSaved = false});

  factory ConversationEntry.honoo(Honoo h) => ConversationEntry._(
        ConversationEntryKind.honoo,
        honoo: h,
        ownerId: h.userId,
        isFromMoonSaved: h.isFromMoonSaved,
      );

  factory ConversationEntry.hinoo(HinooDraft d, {String? ownerId, bool isFromMoonSaved = false}) =>
      ConversationEntry._(
        ConversationEntryKind.hinoo,
        hinoo: d,
        ownerId: ownerId,
        isFromMoonSaved: isFromMoonSaved,
      );
}

