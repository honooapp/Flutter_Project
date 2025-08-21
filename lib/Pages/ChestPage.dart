import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../Controller/DeviceController.dart';
import '../Controller/HonooController.dart';
import '../Entites/Honoo.dart';
import '../UI/HonooCard.dart';
import '../UI/HonooThreadView.dart';
import '../Utility/HonooColors.dart';
import '../Utility/Utility.dart';
import 'dart:math' as math;
import 'package:carousel_slider/carousel_slider.dart' as cs;


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

  Widget _footerFor(Honoo? current) {
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
      // Spedisci sulla Luna
      actions.add(
        IconButton(
          icon: const Icon(Icons.rocket_launch_outlined),
          iconSize: 32,
          splashRadius: 25,
          color: HonooColor.onBackground,
          tooltip: 'Spedisci sulla Luna',
          onPressed: () async {
            final ok = await ctrl.sendToMoon(current);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok ? 'Spedito sulla Luna ✨' : 'Errore nella spedizione.'),
              ),
            );

            // opzionale: se rimuovi l’item, scorri alla pagina precedente se serve
            if (ok && _currentIndex >= ctrl.personal.length && _currentIndex > 0) {
              setState(() => _currentIndex = ctrl.personal.length - 1);
            }
          },
        ),
      );
    } else if (_hasReplies(current) && !_isFromMoonSaved(current)) {
      // Vedi risposte (apri thread, ma qui il thread è già verticale nella pagina)
      actions.add(
        IconButton(
          icon: SvgPicture.asset("assets/icons/reply.svg", semanticsLabel: 'Reply'),
          iconSize: 60,
          splashRadius: 25,
          tooltip: 'Vedi risposte',
          onPressed: () {
            // opzionale: potresti scrollare subito in alto nel verticale
            // (vedi HonooThreadView per gestire animateToPage)
          },
        ),
      );
    } else if (_isFromMoonSaved(current)) {
      // Rispondi a honoo salvato dalla Luna
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

    // Cancella (sempre)
    actions.addAll([
      SizedBox(width: 5.w),
      IconButton(
        icon: const Icon(Icons.delete_outline),
        iconSize: 32,
        splashRadius: 25,
        color: HonooColor.onBackground,
        tooltip: 'Cancella',
        onPressed: () => ctrl.deleteHonoo(current), // collega al tuo service
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
    final isPhone = DeviceController().isPhone();
    final size = MediaQuery.of(context).size;

    const titleH = 60.0;
    const footerH = 60.0;

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([ctrl.isLoading, ctrl.version]),
          builder: (context, _) {
            final personal = ctrl.personal; // include anche quelli salvati dalla luna (flag)
            final Honoo? current = personal.isEmpty ? null : personal[_currentIndex];

            return LayoutBuilder(
              builder: (context, constraints) {
                final availH = constraints.maxHeight;
                final centerH = (availH - titleH - footerH).clamp(0.0, double.infinity);
                final maxW = isPhone ? size.width * 0.96 : size.width * 0.5;

                return Column(
                  children: [
                    // HEADER
                    SizedBox(
                      height: titleH,
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

                    // --- CENTRO: carosello orizzontale senza peek + gutter esterno + gutter interno ---
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxW, maxHeight: centerH),
                          child: ctrl.isLoading.value
                              ? const Center(child: CircularProgressIndicator())
                              : (personal.isEmpty
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
                            // GUTTER ESTERNO: distanzia il carosello dal bordo schermo
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: cs.CarouselSlider.builder(
                              itemCount: personal.length,
                              options: cs.CarouselOptions(
                                height: centerH,
                                viewportFraction: 1.0,                  // nessun peek
                                enableInfiniteScroll: false,
                                padEnds: true,                          // margine primo/ultimo
                                enlargeCenterPage: false,               // no enlarge orizzontale
                                scrollPhysics: const BouncingScrollPhysics(),
                                onPageChanged: (i, _) => setState(() => _currentIndex = i),
                              ),
                              itemBuilder: (context, index, realIdx) {
                                return Padding(
                                  // GUTTER INTERNO: margine garantito per ogni pagina
                                  // (anche se il carosello è strettissimo)
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: HonooThreadView(root: personal[index]),
                                );
                              },
                            ),
                          )),
                        ),
                      ),
                    ),


                    // FOOTER dinamico in base all'honoo corrente
                    _footerFor(current),
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
