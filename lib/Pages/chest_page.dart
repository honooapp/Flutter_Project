
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../Controller/honoo_controller.dart';
import '../Controller/hinoo_controller.dart';
import '../Entities/honoo.dart';
import '../Entities/hinoo.dart';
import 'package:honoo/Services/supabase_provider.dart';
import '../UI/honoo_thread_view.dart';
import '../UI/hinoo_viewer.dart';
import '../Utility/honoo_colors.dart';
import '../Utility/utility.dart';
import '../Utility/responsive_layout.dart';
import '../Widgets/honoo_dialogs.dart';
import '../Widgets/loading_spinner.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;

// 👇 aggiunto per allineare il padding top come in NewHonooPage
import '../Widgets/luna_fissa.dart';

class ChestPage extends StatefulWidget {
  const ChestPage({super.key});

  @override
  State<ChestPage> createState() => _ChestPageState();
}

class _ChestPageState extends State<ChestPage> {
  final _pageCtrl = PageController();
  final HonooController ctrl = HonooController();
  final HinooController _hinooController = HinooController();

  int _currentIndex = 0;
  List<_ChestItem> _items = const [];
  List<_HinooRow> _hinoo = const [];
  bool _isHinooLoading = true;

  @override
  void initState() {
    super.initState();
    ctrl.loadChest(); // carica HONOO dallo scrigno (DB)
    _loadHinoo(); // carica HINOO dallo scrigno (DB)
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHinoo() async {
    final uid = SupabaseProvider.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() {
        _isHinooLoading = false;
      });
      return;
    }
    setState(() {
      _isHinooLoading = true;
    });
    try {
      final client = SupabaseProvider.client;
      final rows = await client
          .from('hinoo')
          .select('id,pages,type,recipient_tag,created_at')
          .eq('user_id', uid)
          .eq('type', 'personal')
          .order('created_at', ascending: false);

      final list = <_HinooRow>[];
      for (final r in (rows as List)) {
        final pages = r['pages'];
        if (pages is List) {
          final draft = HinooDraft(
            pages: pages
                .whereType<Map<String, dynamic>>()
                .map((e) => HinooSlide.fromJson(e))
                .toList(),
            type: HinooType.personal,
            recipientTag: r['recipient_tag'] as String?,
          );
          final created =
              DateTime.tryParse((r['created_at'] ?? '').toString()) ??
                  DateTime.now();
          final dynamic rawId = r['id'];
          final String? id = rawId?.toString();
          if (id != null && id.isNotEmpty) {
            list.add(_HinooRow(id: id, draft: draft, createdAt: created));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _hinoo = list;
        _isHinooLoading = false;
        _rebuildItems();
      });
    } catch (_) {
      // ignora errori silenziosamente per ora
      if (mounted) {
        setState(() {
          _isHinooLoading = false;
        });
      }
    }
  }

  void _rebuildItems() {
    final honoo = ctrl.personal.map<_ChestItem>((h) {
      final dt = DateTime.tryParse(h.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return _ChestItem.honoo(h, dt);
    }).toList();

    final hinoo = _hinoo.map<_ChestItem>((r) => _ChestItem.hinoo(r)).toList();

    _items = [...honoo, ...hinoo]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // più recenti prima
    if (_currentIndex >= _items.length) {
      _currentIndex = _items.isEmpty ? 0 : _items.length - 1;
    }
  }

  // --- helper menu dinamico
  bool _isPersonal(Honoo h) => h.type == HonooType.personal;
  bool _hasReplies(Honoo h) => h.hasReplies == true;
  bool _isFromMoonSaved(Honoo h) => h.isFromMoonSaved == true;

  Widget _footerForHonoo(Honoo? current) {
    // footer invariato (come tuo file attuale) :contentReference[oaicite:1]{index=1}
    if (current == null) {
      return SizedBox(
        height: 60,
        child: Center(
          child: IconButton(
            icon: SvgPicture.asset("assets/icons/home.svg",
                semanticsLabel: 'Home'),
            iconSize: 60,
            splashRadius: 25,
            tooltip: 'Indietro',
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    }

    final actions = <Widget>[
      IconButton(
        icon: SvgPicture.asset(
          "assets/icons/home.svg",
          semanticsLabel: 'Home',
          colorFilter: const ColorFilter.mode(
            HonooColor.onBackground,
            BlendMode.srcIn,
          ),
        ),
        iconSize: 60,
        splashRadius: 25,
        tooltip: 'Indietro',
        onPressed: () => Navigator.pop(context),
      ),
      SizedBox(width: 5.w),
    ];

    if (_isPersonal(current) &&
        !_hasReplies(current) &&
        !_isFromMoonSaved(current)) {
      actions.add(
        IconButton(
          icon: SvgPicture.asset(
            "assets/icons/moon.svg",
            semanticsLabel: 'Luna',
            colorFilter: const ColorFilter.mode(
              HonooColor.onBackground,
              BlendMode.srcIn,
            ),
          ),
          iconSize: 32,
          splashRadius: 25,
          tooltip: 'Spedisci sulla Luna',
          onPressed: () async {
            final ok = await HonooController().sendToMoon(current);
            if (!mounted) return;

            final text = ok ? 'Spedito sulla Luna' : 'Già presente sulla Luna';
            showHonooToast(
              context,
              message: text,
            );

            if (ok &&
                _currentIndex >= ctrl.personal.length &&
                _currentIndex > 0) {
              setState(() => _currentIndex = ctrl.personal.length - 1);
            }
          },
        ),
      );
    } else if (_hasReplies(current) && !_isFromMoonSaved(current)) {
      actions.add(
        IconButton(
          icon: SvgPicture.asset("assets/icons/reply.svg",
              semanticsLabel: 'Reply'),
          iconSize: 60,
          splashRadius: 25,
          tooltip: 'Vedi risposte',
          onPressed: () {},
        ),
      );
    } else if (_isFromMoonSaved(current)) {
      actions.add(
        IconButton(
          icon: SvgPicture.asset("assets/icons/reply.svg",
              semanticsLabel: 'Rispondi',
              colorFilter: const ColorFilter.mode(
                HonooColor.onBackground,
                BlendMode.srcIn,
              )),
          iconSize: 60,
          splashRadius: 25,
          tooltip: 'Rispondi',
          onPressed: () {
            // TODO: apri composer risposta (NewHonooPage) con replyTo=current.dbId
          },
        ),
      );
    }

    actions.addAll([
      SizedBox(width: 5.w),
      IconButton(
        icon: SvgPicture.asset(
          "assets/icons/cancella.svg",
          semanticsLabel: 'Cancella',
          colorFilter: const ColorFilter.mode(
            HonooColor.onBackground,
            BlendMode.srcIn,
          ),
        ),
        iconSize: 60,
        splashRadius: 25,
        tooltip: 'Cancella',
        onPressed: () async {
          final bool? confirmed = await showHonooDeleteDialog(
            context,
            target: HonooDeletionTarget.honoo,
          );
          if (!mounted) return;
          if (confirmed != true) return;

          final String? id = (current.dbId ?? current.id) as String?;
          if (id == null || id.isEmpty) {
            showHonooToast(
              context,
              message: 'Impossibile cancellare: id mancante.',
            );
            return;
          }

          await ctrl.deleteHonooById(id); // accetta String?
          if (!mounted) return;
          showHonooToast(
            context,
            message: 'Honoo eliminato.',
          );
        },
      ),
    ]);

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: actions,
      ),
    );
  }

  Widget _buildChestItem(
      _ChestItem item, double availableCenterH, double targetMaxW) {
    final String identity = item.when(
      honoo: (h) {
        final String? dbId = h.dbId;
        final int localId = h.id;
        final String fallback = localId != 0
            ? localId.toString()
            : item.createdAt.toIso8601String();
        return 'honoo_${dbId ?? fallback}';
      },
      hinoo: (row) => 'hinoo_${row.id}',
    );

    final Widget content = item.when(
      honoo: (h) => HonooThreadView(root: h),
      hinoo: (row) => HinooViewer(
        draft: row.draft,
        maxHeight: availableCenterH,
        maxWidth: targetMaxW,
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(identity),
        child: content,
      ),
    );
  }

  Widget _footerForHinoo(_HinooRow? current) {
    if (current == null) return _footerForHonoo(null);

    final HinooDraft draft = current.draft;
    final bool isPersonal = draft.type == HinooType.personal;
    final bool isFromMoonSaved = draft.type == HinooType.moon;

    final actions = <Widget>[
      IconButton(
        icon: SvgPicture.asset(
          "assets/icons/home.svg",
          semanticsLabel: 'Home',
          colorFilter: const ColorFilter.mode(
            HonooColor.onBackground,
            BlendMode.srcIn,
          ),
        ),
        iconSize: 60,
        splashRadius: 25,
        tooltip: 'Indietro',
        onPressed: () => Navigator.pop(context),
      ),
      SizedBox(width: 5.w),
    ];

    if (isPersonal && !isFromMoonSaved) {
      actions.add(
        IconButton(
          icon: SvgPicture.asset(
            "assets/icons/moon.svg",
            semanticsLabel: 'Luna',
            colorFilter: const ColorFilter.mode(
              HonooColor.onBackground,
              BlendMode.srcIn,
            ),
          ),
          iconSize: 32,
          splashRadius: 25,
          tooltip: 'Spedisci sulla Luna',
          onPressed: () async {
            try {
              final result = await _hinooController.sendToMoon(draft);
              if (!mounted) return;
              final text = result == HinooMoonResult.published
                  ? 'Hinoo spedito sulla Luna.'
                  : 'Hinoo già presente sulla Luna.';
              showHonooToast(
                context,
                message: text,
              );
            } catch (e) {
              if (!mounted) return;
              showHonooToast(
                context,
                message: 'Errore: $e',
              );
            }
          },
        ),
      );
    } else if (isFromMoonSaved) {
      actions.add(
        IconButton(
          icon: SvgPicture.asset(
            "assets/icons/reply.svg",
            semanticsLabel: 'Rispondi',
            colorFilter: const ColorFilter.mode(
              HonooColor.onBackground,
              BlendMode.srcIn,
            ),
          ),
          iconSize: 60,
          splashRadius: 25,
          tooltip: 'Rispondi',
          onPressed: () {
            // TODO: implementare risposta a Hinoo lunare
          },
        ),
      );
    }

    actions.addAll([
      SizedBox(width: 5.w),
      IconButton(
        icon: SvgPicture.asset(
          "assets/icons/cancella.svg",
          semanticsLabel: 'Cancella',
          colorFilter: const ColorFilter.mode(
            HonooColor.onBackground,
            BlendMode.srcIn,
          ),
        ),
        iconSize: 60,
        splashRadius: 25,
        tooltip: 'Cancella',
        onPressed: () => _deleteHinoo(current),
      ),
    ]);

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: actions,
      ),
    );
  }

  Widget _footerForItem(_ChestItem? item) {
    if (item == null) return _footerForHonoo(null);
    return item.when(
      honoo: (h) => _footerForHonoo(h),
      hinoo: (row) => _footerForHinoo(row),
    );
  }

  Future<void> _deleteHinoo(_HinooRow current) async {
    final bool? confirmed = await showHonooDeleteDialog(
      context,
      target: HonooDeletionTarget.hinoo,
    );
    if (confirmed != true) return;

    try {
      final client = SupabaseProvider.client;
      await client.from('hinoo').delete().eq('id', current.id);
      if (!mounted) return;
      setState(() {
        _hinoo = _hinoo.where((r) => r.id != current.id).toList();
        _rebuildItems();
      });
      showHonooToast(
        context,
        message: 'Hinoo eliminato.',
      );
    } catch (e) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Errore durante l\'eliminazione: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const headerH = 52.0;
    const footerH = 60.0;

    // 👇 come in NewHonooPage: riserva top solo oltre l’header per non far coprire la Luna
    final double lunaReserve = LunaFissa.reserveTopPadding(context);
    final double extraTop = (lunaReserve - headerH);
    final double contentTopPadding = extraTop > 0 ? extraTop : 0;

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([ctrl.isLoading, ctrl.version]),
          builder: (context, _) {
            _rebuildItems();
            final _ChestItem? current =
                _items.isEmpty ? null : _items[_currentIndex];

            return LayoutBuilder(
              builder: (context, constraints) {
                final availH = constraints.maxHeight;

                // === stesse regole di NewHonooPage ===
                final double targetMaxW =
                    ResponsiveLayout.contentMaxWidth(constraints.maxWidth);
                final double availableCenterH =
                    (availH - headerH - contentTopPadding - footerH)
                        .clamp(0.0, double.infinity);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // CONTENUTO PRINCIPALE (identico, ma con misure allineate a NewHonooPage)
                    Column(
                      children: [
                        // HEADER
                        SizedBox(
                          height: headerH,
                          child: Center(
                            child: Text(
                              Utility().appName,
                              style: GoogleFonts.libreFranklin(
                                color: HonooColor.secondary,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // CENTRO: il carosello riempie tutta l’altezza disponibile,
                        // con larghezza massima fluida come in NewHonooPage
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              0,
                              contentTopPadding, // ← come NewHonooPage
                              0,
                              footerH, // spazio per footer (come prima)
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 90),
                                curve: Curves.easeOutCubic,
                                constraints:
                                    BoxConstraints(maxWidth: targetMaxW),
                                child: SizedBox(
                                  height: availableCenterH,
                                  width: double.infinity,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 350),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: () {
                                      if (ctrl.isLoading.value ||
                                          _isHinooLoading) {
                                        return const Center(
                                          key: ValueKey('chest_loading'),
                                          child: LoadingSpinner(
                                              color: Colors.white),
                                        );
                                      }

                                      if (_items.isEmpty) {
                                        return Center(
                                          key: const ValueKey('chest_empty'),
                                          child: Text(
                                            'Nessun contenuto nello scrigno',
                                            style: GoogleFonts.libreFranklin(
                                              color: HonooColor.onBackground,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        );
                                      }

                                      return Padding(
                                        key: ValueKey(
                                            'chest_content_${_items.length}'),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: cs.CarouselSlider.builder(
                                          itemCount: _items.length,
                                          options: cs.CarouselOptions(
                                            height: availableCenterH,
                                            viewportFraction: 1.0,
                                            enableInfiniteScroll: false,
                                            padEnds: true,
                                            enlargeCenterPage: false,
                                            scrollPhysics:
                                                const BouncingScrollPhysics(),
                                            onPageChanged: (i, _) => setState(
                                                () => _currentIndex = i),
                                          ),
                                          itemBuilder:
                                              (context, index, realIdx) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                              child: _buildChestItem(
                                                _items[index],
                                                availableCenterH,
                                                targetMaxW,
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // FOOTER (invariato)
                        _footerForItem(current),
                      ],
                    ),

                    // 🌙 LUNA FISSA (overlay come in NewHonooPage)
                    const LunaFissa(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Unione semplice per elementi dello scrigno
class _ChestItem {
  final Honoo? honoo;
  final _HinooRow? hinoo;
  final DateTime createdAt;
  const _ChestItem._({this.honoo, this.hinoo, required this.createdAt});
  factory _ChestItem.honoo(Honoo h, DateTime createdAt) =>
      _ChestItem._(honoo: h, createdAt: createdAt);
  factory _ChestItem.hinoo(_HinooRow row) =>
      _ChestItem._(hinoo: row, createdAt: row.createdAt);

  T when<T>(
      {required T Function(Honoo h) honoo,
      required T Function(_HinooRow row) hinoo}) {
    if (this.honoo != null) return honoo(this.honoo!);
    return hinoo(this.hinoo!);
  }
}

class _HinooRow {
  final String id;
  final HinooDraft draft;
  final DateTime createdAt;
  const _HinooRow(
      {required this.id, required this.draft, required this.createdAt});
}
