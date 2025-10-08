
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import 'package:honoo/Controller/device_controller.dart';
import 'package:honoo/Controller/honoo_controller.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/utility.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';

import '../Entities/honoo.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key, required this.honoo});

  final Honoo honoo;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final cs.CarouselController _carouselController = cs.CarouselController();

  bool _isLoading = true;
  List<Honoo> _thread = []; // padre + reply in ordine cronologico

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await HonooController().getHonooHistory(widget.honoo);
      if (!mounted) return;
      setState(() {
        _thread = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('getHonooHistory error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      showHonooToast(
        context,
        message: 'Errore nel caricamento conversazione: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceController().isPhone();

    final constraints = isPhone
        ? BoxConstraints(maxWidth: 85.w, maxHeight: 100.h - 120)
        : BoxConstraints(maxWidth: 50.w, maxHeight: 100.h - 120);

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Column(
        children: [
          // HEADER
          SizedBox(
            height: 52,
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

          // CONTENUTO
          Row(
            children: [
              const Expanded(child: SizedBox()),
              Container(
                constraints: constraints,
                child: Column(
                  children: [
                    Expanded(
                      child: _isLoading
                          ? const Center(child: LoadingSpinner())
                          : (_thread.isEmpty
                              ? Center(
                                  child: Text(
                                    'Nessuna conversazione',
                                    style: GoogleFonts.libreFranklin(
                                      color: HonooColor.onBackground,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                )
                              : cs.CarouselSlider(
                                  carouselController: _carouselController,
                                  options: cs.CarouselOptions(
                                    scrollDirection: Axis.vertical,
                                    height: 100.h,
                                    aspectRatio: 9 / 16,
                                    enlargeCenterPage: true,
                                    enableInfiniteScroll: false,
                                  ),
                                  items: _thread
                                      .map((h) => HonooCard(honoo: h))
                                      .toList(),
                                )),
                    ),

                    // FOOTER
                    SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: SvgPicture.asset(
                              "assets/icons/home.svg",
                              colorFilter: const ColorFilter.mode(
                                HonooColor.onBackground,
                                BlendMode.srcIn,
                              ),
                              semanticsLabel: 'Home',
                            ),
                            iconSize: 60,
                            splashRadius: 25,
                            tooltip: 'Indietro',
                            onPressed: () => Navigator.pop(context),
                          ),
                          SizedBox(width: 5.w),
                          IconButton(
                            icon: SvgPicture.asset(
                              "assets/icons/broken_heart.svg",
                              semanticsLabel: 'Broken heart',
                            ),
                            iconSize: 60,
                            splashRadius: 25,
                            tooltip: 'Cuore spezzato',
                            onPressed: () {
                              // TODO: azione "broken heart" (se prevista)
                            },
                          ),
                          SizedBox(width: 5.w),
                          IconButton(
                            icon: SvgPicture.asset(
                              "assets/icons/reply.svg",
                              colorFilter: const ColorFilter.mode(
                                HonooColor.onBackground,
                                BlendMode.srcIn,
                              ),
                              semanticsLabel: 'Reply',
                            ),
                            iconSize: 60,
                            splashRadius: 25,
                            tooltip: 'Rispondi',
                            onPressed: () {
                              // TODO: apri composer risposta partendo da widget.honoo o dall'elemento corrente del carosello
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}
