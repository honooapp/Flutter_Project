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
    required this.onReplyToConversationEntry,
    required this.onSendConversationEntryToMoon,
    this.foregroundColor = HonooColor.onBackground,
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
  final ValueChanged<ConversationEntry> onReplyToConversationEntry;
  final ValueChanged<ConversationEntry> onSendConversationEntryToMoon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final actions = <ResponsiveFooterAction>[
      _action(
        asset: 'assets/icons/home.svg',
        label: 'Home',
        tooltip: 'Home',
        onPressed: onHome,
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

    final selectedEntry = selectedConversationEntry;
    if (_canReplyTo(selectedEntry) &&
        !actions.any((action) => action.tooltip == 'Rispondi')) {
      actions.add(
        _replyAction(() => onReplyToConversationEntry(selectedEntry!)),
      );
    }

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
    final isOnMoon = honoo.isOnMoon == true;
    final selectedEntryToPublish = _selectedEntryToPublish(honoo);

    if (isPersonal &&
        !hasReplies &&
        !isFromMoonSaved &&
        !isOnMoon &&
        selectedEntryToPublish == null) {
      actions.add(_moonAction(() => onSendHonooToMoon(honoo)));
    } else if (isFromMoonSaved) {
      actions.add(_replyAction(() => onReplyToHonoo(honoo)));
    }

    actions.add(_deleteAction(() => onDeleteHonoo(honoo)));

    if (selectedEntryToPublish != null) {
      actions.add(
        _moonAction(
          () => onSendConversationEntryToMoon(selectedEntryToPublish),
        ),
      );
    }
  }

  ConversationEntry? _selectedEntryToPublish(Honoo honoo) {
    final entry = selectedConversationEntry;
    final conversationId = honoo.conversationId;
    if (entry == null ||
        conversationId == null ||
        conversationId.isEmpty ||
        entry.kind == ConversationEntryKind.deleted) {
      return null;
    }
    final isMine =
        entry.ownerId != null &&
        currentUserId != null &&
        entry.ownerId == currentUserId;
    final isPersonalEntry = entry.kind == ConversationEntryKind.honoo
        ? entry.honoo!.type == HonooType.personal
        : entry.hinoo!.type == HinooType.personal;
    return isMine && isPersonalEntry && !entry.isFromMoonSaved ? entry : null;
  }

  bool _canReplyTo(ConversationEntry? entry) =>
      entry != null &&
      entry.kind != ConversationEntryKind.deleted &&
      entry.id != null &&
      entry.id!.isNotEmpty;

  void _addHinooActions(
    List<ResponsiveFooterAction> actions,
    ChestHinooItem hinoo,
  ) {
    final isPersonal = hinoo.draft.type == HinooType.personal;
    final isFromMoonSaved = hinoo.isFromMoonSaved;
    if (isPersonal && !isFromMoonSaved && !hinoo.isOnMoon) {
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

  ResponsiveFooterAction _replyAction(VoidCallback onPressed, {Color? color}) =>
      _action(
        asset: 'assets/icons/reply.svg',
        label: 'Rispondi',
        tooltip: 'Rispondi',
        onPressed: onPressed,
        color: color,
      );

  ResponsiveFooterAction _deleteAction(VoidCallback onPressed) => _action(
    asset: 'assets/Cestino.svg',
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
    Color? color,
  }) => ResponsiveFooterAction(
    asset: asset,
    semanticsLabel: label,
    colorFilter: applyColorFilter
        ? ColorFilter.mode(color ?? foregroundColor, BlendMode.srcIn)
        : null,
    size: iconSize,
    splashRadius: 25,
    tooltip: tooltip,
    onPressed: onPressed,
  );
}
