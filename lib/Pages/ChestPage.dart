import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../Controller/HonooController.dart';
import '../Entites/Honoo.dart';
import '../UI/HonooThreadView.dart';
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

  @override
  void initState() {
    super.initState();
    ctrl.loadChest(); // carica dallo scrigno (DB)
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
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

  Widget _footerFor(Honoo? current) {
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
            final personal = ctrl.personal;
            final Honoo? current = personal.isEmpty ? null : personal[_currentIndex];

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
                                  child: personal.isEmpty
                                      ? Center(
                                    child: Text(
                                      'Nessun honoo nello scrigno',
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
                                      itemCount: personal.length,
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
                                          child: HonooThreadView(root: personal[index]),
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
                        _footerFor(current),
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
