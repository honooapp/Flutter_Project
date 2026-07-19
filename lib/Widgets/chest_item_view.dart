import 'package:flutter/material.dart';

import '../Entities/chest_item.dart';
import '../Entities/conversation_entry.dart';
import '../Entities/hinoo_thread_entry.dart';
import '../Entities/honoo.dart';
import '../UI/hinoo_thread_view.dart';
import '../UI/hinoo_typography.dart';
import '../UI/hinoo_viewer.dart';
import '../UI/honoo_thread_view.dart';
import '../UI/unified_thread_view.dart';
import '../Utility/responsive_layout.dart';

class ChestItemView extends StatelessWidget {
  const ChestItemView({
    super.key,
    required this.item,
    required this.availableHeight,
    required this.maxWidth,
    required this.honooMetrics,
    required this.repaintKey,
    required this.hinooRepliesByRoot,
    required this.isNormalMode,
    required this.isActive,
    required this.highlightLatest,
    required this.focusConversationId,
    required this.onSelectConversationEntry,
    required this.onDownload,
  });

  final ChestItem item;
  final double availableHeight;
  final double maxWidth;
  final HonooBuilderMetrics honooMetrics;
  final GlobalKey repaintKey;
  final Map<String, List<HinooThreadEntry>> hinooRepliesByRoot;
  final bool isNormalMode;
  final bool isActive;
  final bool highlightLatest;
  final String? focusConversationId;
  final ValueChanged<ConversationEntry> onSelectConversationEntry;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final identity = item.when(
      honoo: (honoo) {
        final fallback = honoo.id != 0
            ? honoo.id.toString()
            : item.createdAt.toIso8601String();
        return 'honoo_${honoo.dbId ?? fallback}';
      },
      hinoo: (hinoo) => 'hinoo_${hinoo.id}',
    );
    final isHonoo = item.honoo != null;
    final hinooSize = ResponsiveLayout.fitAspectRatio(
      maxWidth,
      availableHeight,
      HinooTypography.aspectRatio,
    );
    final cardWidth = isHonoo ? honooMetrics.width : hinooSize.width;
    final cardHeight = isHonoo ? honooMetrics.height : hinooSize.height;
    final content = item.when(
      honoo: (honoo) => _buildHonoo(honoo),
      hinoo: (hinoo) => _buildHinoo(hinoo, cardWidth, cardHeight),
    );
    final isThread = item.when(
      honoo: (_) => true,
      hinoo: (hinoo) => hinooRepliesByRoot[hinoo.id]?.isNotEmpty ?? false,
    );
    final card = isThread
        ? RepaintBoundary(key: repaintKey, child: content)
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: cardWidth,
              child: RepaintBoundary(key: repaintKey, child: content),
            ),
          );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(
        key: ValueKey(identity),
        child: SizedBox(
          width: maxWidth,
          height: availableHeight,
          child: card,
        ),
      ),
    );
  }

  Widget _buildHonoo(Honoo honoo) {
    final conversationId = honoo.conversationId;
    if (isNormalMode && conversationId != null && conversationId.isNotEmpty) {
      return _unifiedThread(conversationId);
    }
    final effectiveRoot = honoo.type == HonooType.answer &&
            honoo.replyTo != null &&
            honoo.replyTo!.isNotEmpty
        ? honoo.copyWith(dbId: honoo.replyTo)
        : honoo;
    return SizedBox(
      width: maxWidth,
      height: availableHeight,
      child: HonooThreadView(root: effectiveRoot, onDownloadTap: onDownload),
    );
  }

  Widget _buildHinoo(
    ChestHinooItem hinoo,
    double cardWidth,
    double cardHeight,
  ) {
    final conversationId = hinoo.conversationId ?? hinoo.draft.conversationId;
    if (isNormalMode && conversationId != null && conversationId.isNotEmpty) {
      return _unifiedThread(conversationId);
    }
    final replies = hinooRepliesByRoot[hinoo.id] ?? const [];
    if (replies.isEmpty) {
      return HinooViewer(
        draft: hinoo.draft,
        maxHeight: availableHeight,
        maxWidth: maxWidth,
        authorId: hinoo.ownerId,
        onDownloadTap: onDownload,
      );
    }
    return HinooThreadView(
      root: hinoo.draft,
      rootAuthorId: hinoo.ownerId,
      replies: replies,
      maxHeight: cardHeight,
      maxWidth: cardWidth,
      onDownloadTap: onDownload,
    );
  }

  Widget _unifiedThread(String conversationId) => UnifiedThreadView(
        conversationId: conversationId,
        maxWidth: maxWidth,
        maxHeight: availableHeight,
        isActive: isActive,
        onSelect: onSelectConversationEntry,
        highlightLatest:
            highlightLatest && focusConversationId == conversationId,
        onDownloadTap: onDownload,
      );

}
