import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../Controller/HonooController.dart';
import '../Entities/Honoo.dart';
import '../Entities/Hinoo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../UI/HonooThreadView.dart';
import '../UI/HinooViewer.dart';
import '../Utility/HonooColors.dart';
import '../Utility/Utility.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;

// 👇 aggiunto per allineare il padding top come in NewHonooPage
import '../Widgets/LunaFissa.dart';

class ChestPage extends StatefulWidget {
  const ChestPage({super.key});

  @override
  State<ChestPage> createState() => _ChestPageState();
}

class _ChestPageState extends State<ChestPage> {
  final _pageCtrl = PageController();
  final HonooController ctrl = HonooController();

  int _currentIndex = 0;
  List<_ChestItem> _items = const [];
  List<_HinooRow> _hinoo = const [];

  @override
  void initState() {
    super.initState();
    ctrl.loadChest(); // carica HONOO dallo scrigno (DB)
    _loadHinoo();     // carica HINOO dallo scrigno (DB)
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHinoo() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('hinoo')
          .select('pages,type,recipient_tag,created_at')
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
          final created = DateTime.tryParse((r['created_at'] ?? '').toString()) ?? DateTime.now();
          list.add(_HinooRow(draft: draft, createdAt: created));
        }
      }

      if (!mounted) return;
      setState(() {
        _hinoo = list;
        _rebuildItems();
      });
    } catch (_) {
      // ignora errori silenziosamente per ora
    }
  }

  void _rebuildItems() {
    final honoo = ctrl.personal.map<_ChestItem>((h) {
      final dt = DateTime.tryParse(h.created_at) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _ChestItem.honoo(h, dt);
    }).toList();

    final hinoo = _hinoo.map<_ChestItem>((r) => _ChestItem.hinoo(r.draft, r.createdAt)).toList();

    _items = [...honoo, ...hinoo]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // più recenti prima
    if (_currentIndex >= _items.length) _currentIndex = _items.isEmpty ? 0 : _items.length - 1;
  }

  // --- helper menu dinamico
  bool _isPersonal(Honoo h) => h.type == HonooType.personal;
  bool _hasReplies(Honoo h) => h.hasReplies == true;
  bool _isFromMoonSaved(Honoo h) => h.isFromMoonSaved == true;

  // === stessa funzione “breakpoints morbidi” usata in NewHonooPage ===
  double _contentMaxWidth(double w) {
    if (w < 480) return w * 0.94;
    if (w < 768) return w * 0.92;
    if (w < 1024) return w * 0.84;
    if (w < 1440) return w * 0.70;
    return w * 0.58;
  }

  Widget _footerForHonoo(Honoo? current) {
    // footer invariato (come tuo file attuale) :contentReference[oaicite:1]{index=1}
    if (current == null) {
      return SizedBox(
        height: 60,
        child: Center(
          child: IconButton(
            icon: SvgPicture.asset("assets/icons/home.svg", semanticsLabel: 'Home'),
            iconSize: 60,
            splashRadius: 25,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    }

    final actions = <Widget>[
      IconButton(
        icon: SvgPicture.asset("assets/icons/home.svg", semanticsLabel: 'Home'),
        iconSize: 60,
        splashRadius: 25,
        color: HonooColor.onBackground,
        onPressed: () => Navigator.pop(context),
      ),
      SizedBox(width: 5.w),
    ];

    if (_isPersonal(current) && !_hasReplies(current) && !_isFromMoonSaved(current)) {
      actions.add(
        IconButton(
          icon: SvgPicture.asset(
            "assets/icons/moon.svg",
            semanticsLabel: 'Luna',
          ),
          iconSize: 32,
          splashRadius: 25,
          color: HonooColor.onBackground,
          tooltip: 'Spedisci sulla Luna',
          onPressed: () async {
            final ok = await HonooController().sendToMoon(current);
            final text = ok ? 'Spedito sulla Luna' : 'Già presente sulla Luna';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

            if (ok && _currentIndex >= ctrl.personal.length && _currentIndex > 0) {
              setState(() => _currentIndex = ctrl.personal.length - 1);
            }
          },
        ),
      );
    } else if (_hasReplies(current) && !_isFromMoonSaved(current)) {
      actions.add(
        IconButton(
          icon: SvgPicture.asset("assets/icons/reply.svg", semanticsLabel: 'Reply'),
          iconSize: 60,
          splashRadius: 25,
          tooltip: 'Vedi risposte',
          onPressed: () {},
        ),
      );
    } else if (_isFromMoonSaved(current)) {
      actions.add(
        IconButton(
          icon: SvgPicture.asset("assets/icons/reply.svg", semanticsLabel: 'Rispondi'),
          iconSize: 60,
          splashRadius: 25,
          color: HonooColor.onBackground,
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
        icon: SvgPicture.asset("assets/icons/cancella.svg", semanticsLabel: 'Cancella'),
        iconSize: 60,
        splashRadius: 25,
        color: HonooColor.onBackground,
        tooltip: 'Cancella',
        onPressed: () async {
          final String? id = (current.dbId ?? current.id) as String?;
          if (id == null || id.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Impossibile cancellare: id mancante.')),
            );
            return;
          }

          await ctrl.deleteHonooById(id); // accetta String?
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Honoo eliminato.')),
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

  Widget _buildChestItem(_ChestItem item, double availableCenterH, double targetMaxW) {
    return item.when(
      honoo: (h) => HonooThreadView(root: h),
      hinoo: (d) => HinooViewer(draft: d, maxHeight: availableCenterH, maxWidth: targetMaxW),
    );
  }

  @override
  Widget build(BuildContext context) {

    const headerH = 60.0; // lasciamo il tuo titolo a 60 per “non cambiare altro”
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
            final _ChestItem? current = _items.isEmpty ? null : _items[_currentIndex];

            return LayoutBuilder(
              builder: (context, constraints) {
                final availH = constraints.maxHeight;

                // === stesse regole di NewHonooPage ===
                final double targetMaxW = _contentMaxWidth(constraints.maxWidth);
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
                                fontSize: 30,
                                fontWeight: FontWeight.w500,
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
                              footerH,           // spazio per footer (come prima)
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 90),
                                curve: Curves.easeOutCubic,
                                constraints: BoxConstraints(maxWidth: targetMaxW),
                                child: SizedBox(
                                  height: availableCenterH,
                                  width: double.infinity,
                                  child: _items.isEmpty
                                      ? Center(
                                        child: Text(
                                      'Nessun contenuto nello scrigno',
                                          style: GoogleFonts.libreFranklin(
                                            color: HonooColor.onBackground,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      )
                                      : Padding(
                                        // gutter esterno
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: cs.CarouselSlider.builder(
                                      itemCount: _items.length,
                                          options: cs.CarouselOptions(
                                            height: availableCenterH,     // ← come NewHonooPage (riempi tutto)
                                            viewportFraction: 1.0,
                                            enableInfiniteScroll: false,
                                            padEnds: true,
                                            enlargeCenterPage: false,
                                            scrollPhysics: const BouncingScrollPhysics(),
                                            onPageChanged: (i, _) =>
                                                setState(() => _currentIndex = i),
                                          ),
                                          itemBuilder: (context, index, realIdx) {
                                            return Padding(
                                              // gutter interno
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: _buildChestItem(_items[index], availableCenterH, targetMaxW),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),

                        // FOOTER (invariato)
                        _footerForHonoo(current?.honoo),
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
  final HinooDraft? hinoo;
  final DateTime createdAt;
  const _ChestItem._(this.honoo, this.hinoo, this.createdAt);
  factory _ChestItem.honoo(Honoo h, DateTime createdAt) => _ChestItem._(h, null, createdAt);
  factory _ChestItem.hinoo(HinooDraft d, DateTime createdAt) => _ChestItem._(null, d, createdAt);

  T when<T>({required T Function(Honoo h) honoo, required T Function(HinooDraft d) hinoo}) {
    if (this.honoo != null) return honoo(this.honoo!);
    return hinoo(this.hinoo!);
  }
}


class _HinooRow {
  final HinooDraft draft;
  final DateTime createdAt;
  const _HinooRow({required this.draft, required this.createdAt});
}
