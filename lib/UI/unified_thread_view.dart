import 'package:flutter/material.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Entities/conversation_entry.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Services/conversation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Utility/download_capture.dart';
// rendering a lista con separatori; rimosso carousel verticale

class UnifiedThreadView extends StatefulWidget {
  const UnifiedThreadView({
    super.key,
    required this.conversationId,
    required this.maxWidth,
    required this.maxHeight,
    this.onSelect,
    this.highlightLatest = false,
    this.isActive = false,
    this.onDownloadTap,
  });

  final String conversationId;
  final double maxWidth;
  final double maxHeight;
  final ValueChanged<ConversationEntry>? onSelect;
  final bool highlightLatest;
  final bool isActive;
  final VoidCallback? onDownloadTap;

  @override
  State<UnifiedThreadView> createState() => _UnifiedThreadViewState();
}

class _UnifiedThreadViewState extends State<UnifiedThreadView> with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<ConversationEntry> _entries = const [];
  RealtimeChannel? _chan;
  bool _didHighlight = false;
  bool _hasPlayedReveal = false;
  final PageController _pageController = PageController();
  late AnimationController _controller;
  late Animation<double> _liftAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _liftAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _load();
    _syncSubscription();
  }

  void _syncSubscription() {
    if (!widget.isActive) {
      _chan?.unsubscribe();
      _chan = null;
      return;
    }
    _chan ??= ConversationService.subscribeConversation(
      widget.conversationId,
      _load,
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await ConversationService.fetchConversation(widget.conversationId);

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
      _showLatestReceivedAndReveal();
      if (widget.highlightLatest && !_didHighlight && _entries.isNotEmpty) {
        _didHighlight = true;
        widget.onSelect?.call(_entryToShowFirst);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void didUpdateWidget(covariant UnifiedThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _chan?.unsubscribe();
      _chan = null;
      _didHighlight = false;
      _hasPlayedReveal = false;
      _load();
    }
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.conversationId != widget.conversationId) {
      _syncSubscription();
      if (widget.isActive && !oldWidget.isActive) {
        _load();
      } else if (!widget.isActive && oldWidget.isActive) {
        _hasPlayedReveal = false;
        _controller.reset();
      }
    }
    if (widget.isActive) _showLatestReceivedAndReveal();
  }

  ConversationEntry get _entryToShowFirst {
    for (final entry in _entries.reversed) {
      if (_shouldReveal(entry)) return entry;
    }
    return _entries.last;
  }

  int get _pageToShowFirst {
    final reversed = _entries.reversed.toList(growable: false);
    final receivedIndex = reversed.indexWhere(_shouldReveal);
    return receivedIndex < 0 ? 0 : receivedIndex;
  }

  void _showLatestReceivedAndReveal() {
    if (!widget.isActive || _entries.isEmpty || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isActive || _entries.isEmpty) return;
      final targetPage = _pageToShowFirst;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetPage);
      }
      final entry = _entries.reversed.elementAt(targetPage);
      if (!_hasPlayedReveal && _shouldReveal(entry)) {
        _hasPlayedReveal = true;
        _controller.forward(from: 0);
      }
    });
  }

  bool _shouldReveal(ConversationEntry e) {
    final String? myId = SupabaseProvider.client.auth.currentUser?.id;
    // Moon-saved: non rivelare
    final bool isMoon = e.isFromMoonSaved == true || (e.honoo != null && (e.honoo!.isFromMoonSaved == true));
    if (isMoon) return false;

    // Creato da me: non rivelare
    if (e.ownerId != null && myId != null && e.ownerId == myId) return false;

    // Reply?
    final bool isReply = e.honoo != null ? (e.honoo!.type == HonooType.answer) : (e.hinoo != null && e.hinoo!.type == HinooType.answer);

    return isReply;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: LoadingSpinner());
    return SizedBox(
      width: widget.maxWidth,
      height: widget.maxHeight,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        pageSnapping: true,
        physics: const PageScrollPhysics(),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          // Ordine inverso: ultimo (più recente) in cima
          final revIndex = _entries.length - 1 - index;
          final e = _entries[revIndex];
          final GlobalKey repaintKey = GlobalKey();
          final card = e.kind == ConversationEntryKind.honoo
              ? RepaintBoundary(
              key: repaintKey,
              child: HonooCard(
                honoo: e.honoo!,
                onDownloadTap: () => _downloadFromBoundary(
                  repaintKey: repaintKey,
                  baseName: 'honoo',
                ),
              ),
            )
              : RepaintBoundary(
              key: repaintKey,
              child: HinooViewer(
                draft: e.hinoo!,
                maxHeight: widget.maxHeight,
                maxWidth: widget.maxWidth,
                isReply: e.hinoo!.type == HinooType.answer,
                authorId: e.ownerId,
                onDownloadTap: () => _downloadFromBoundary(
                  repaintKey: repaintKey,
                  baseName: 'hinoo',
                ),
              ),
            );
          final Widget page = SizedBox.expand(child: card);
          if (index == _pageToShowFirst && _shouldReveal(e)) {
            final screenH = MediaQuery.of(context).size.height;
            return AnimatedBuilder(
              animation: _liftAnimation,
              builder: (context, childWidget) {
                final double offsetY = _liftAnimation.value * (screenH * 0.4);
                return Transform.translate(offset: Offset(0, offsetY), child: childWidget);
              },
              child: page,
            );
          }
          return page;
        },
      ),
    );
  }

  // Tile helpers non più utilizzati con il rendering a lista separata

  @override
  void dispose() {
    _chan?.unsubscribe();
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // mapping handled by service
}

extension on _UnifiedThreadViewState {
  Future<void> _downloadFromBoundary({
    required GlobalKey repaintKey,
    required String baseName,
  }) async {
    if (!mounted) return;
    await captureAndSave(context, repaintKey: repaintKey, baseName: baseName);
  }
}

// ConversationEntry now lives in lib/Entities/conversation_entry.dart
