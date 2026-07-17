import 'package:flutter/material.dart';

import '../Entities/chest_item.dart';
import '../Entities/conversation_entry.dart';
import '../Entities/hinoo.dart';
import '../Entities/honoo.dart';
import '../Utility/honoo_colors.dart';
import 'responsive_footer_bar.dart';

class ChestFooter extends StatelessWidget {
  const ChestFooter({
    super.key,
    required this.item,
    required this.selectedConversationEntry,
    required this.currentUserId,
    required this.iconSize,
    required this.gap,
    required this.bottomPadding,
    required this.onHome,
    required this.onInfo,
    required this.onSendHonooToMoon,
    required this.onReplyToHonoo,
    required this.onDeleteHonoo,
    required this.onSendHinooToMoon,
    required this.onReplyToHinoo,
    required this.onDeleteHinoo,
    required this.onSendConversationEntryToMoon,
  });

  final ChestItem? item;
  final ConversationEntry? selectedConversationEntry;
  final String? currentUserId;
  final double iconSize;
  final double gap;
  final double bottomPadding;
  final VoidCallback onHome;
  final VoidCallback onInfo;
  final ValueChanged<Honoo> onSendHonooToMoon;
  final ValueChanged<Honoo> onReplyToHonoo;
  final ValueChanged<Honoo> onDeleteHonoo;
  final ValueChanged<ChestHinooItem> onSendHinooToMoon;
  final ValueChanged<ChestHinooItem> onReplyToHinoo;
  final ValueChanged<ChestHinooItem> onDeleteHinoo;
  final ValueChanged<ConversationEntry> onSendConversationEntryToMoon;

  @override
  Widget build(BuildContext context) {
    final actions = <ResponsiveFooterAction>[
      _action(
        asset: 'assets/icons/home.svg',
        label: 'Home',
        tooltip: 'Home',
        onPressed: onHome,
        applyColorFilter: item != null,
      ),
      _action(
        asset: 'assets/icons/info.svg',
        label: 'Info',
        tooltip: 'Info',
        onPressed: onInfo,
      ),
    ];

    item?.when(
      honoo: (honoo) => _addHonooActions(actions, honoo),
      hinoo: (hinoo) => _addHinooActions(actions, hinoo),
    );

    return ResponsiveFooterBar(
      useSafeArea: false,
      bottomPadding: bottomPadding,
      desiredGap: gap,
      minGap: 16,
      height: iconSize,
      actions: actions,
    );
  }

  void _addHonooActions(List<ResponsiveFooterAction> actions, Honoo honoo) {
    final isPersonal = honoo.type == HonooType.personal;
    final hasReplies = honoo.hasReplies == true;
    final isFromMoonSaved = honoo.isFromMoonSaved == true;

    if (isPersonal && !hasReplies && !isFromMoonSaved) {
      actions.add(_moonAction(() => onSendHonooToMoon(honoo)));
    } else if (hasReplies && !isFromMoonSaved) {
      actions.add(
        _action(
          asset: 'assets/icons/reply.svg',
          label: 'Reply',
          tooltip: 'Vedi risposte',
          onPressed: () {},
          applyColorFilter: false,
        ),
      );
    } else if (isFromMoonSaved) {
      actions.add(_replyAction(() => onReplyToHonoo(honoo)));
    }

    actions.add(_deleteAction(() => onDeleteHonoo(honoo)));

    final entry = selectedConversationEntry;
    final conversationId = honoo.conversationId;
    if (entry == null || conversationId == null || conversationId.isEmpty) {
      return;
    }
    final isMine = entry.ownerId != null &&
        currentUserId != null &&
        entry.ownerId == currentUserId;
    final isPersonalEntry = entry.kind == ConversationEntryKind.honoo
        ? entry.honoo!.type == HonooType.personal
        : entry.hinoo!.type == HinooType.personal;
    if (isMine && isPersonalEntry) {
      actions.add(
        _moonAction(() => onSendConversationEntryToMoon(entry)),
      );
    }
  }

  void _addHinooActions(
    List<ResponsiveFooterAction> actions,
    ChestHinooItem hinoo,
  ) {
    final isPersonal = hinoo.draft.type == HinooType.personal;
    final isFromMoonSaved = hinoo.draft.type == HinooType.moon;
    if (isPersonal && !isFromMoonSaved) {
      actions.add(_moonAction(() => onSendHinooToMoon(hinoo)));
    } else if (isFromMoonSaved) {
      actions.add(_replyAction(() => onReplyToHinoo(hinoo)));
    }
    actions.add(_deleteAction(() => onDeleteHinoo(hinoo)));
  }

  ResponsiveFooterAction _moonAction(VoidCallback onPressed) => _action(
        asset: 'assets/icons/moon.svg',
        label: 'Luna',
        tooltip: 'Spedisci sulla Luna',
        onPressed: onPressed,
      );

  ResponsiveFooterAction _replyAction(VoidCallback onPressed) => _action(
        asset: 'assets/icons/reply.svg',
        label: 'Rispondi',
        tooltip: 'Rispondi',
        onPressed: onPressed,
      );

  ResponsiveFooterAction _deleteAction(VoidCallback onPressed) => _action(
        asset: 'assets/icons/cancella.svg',
        label: 'Cancella',
        tooltip: 'Cancella',
        onPressed: onPressed,
      );

  ResponsiveFooterAction _action({
    required String asset,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
    bool applyColorFilter = true,
  }) =>
      ResponsiveFooterAction(
        asset: asset,
        semanticsLabel: label,
        colorFilter: applyColorFilter
            ? const ColorFilter.mode(
                HonooColor.onBackground,
                BlendMode.srcIn,
              )
            : null,
        size: iconSize,
        splashRadius: 25,
        tooltip: tooltip,
        onPressed: onPressed,
      );
}
