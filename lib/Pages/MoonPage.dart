import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../Entities/Honoo.dart';
import 'ComingSoonPage.dart';
import '../Controller/DeviceController.dart';
import '../Services/HonooService.dart';
import '../UI/HonooCard.dart';
import '../Utility/HonooColors.dart';
import '../Utility/Utility.dart';

class MoonPage extends StatefulWidget {
  const MoonPage({super.key});

  @override
  State<MoonPage> createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {
  List<Honoo> _moonHonoo = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMoonHonoo();
  }

  Future<void> _loadMoonHonoo() async {
    try {
      final data = await HonooService.fetchPublicHonoo();
      setState(() {
        _moonHonoo = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Errore caricamento Moon Honoo: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceController().isPhone();
    final size = MediaQuery.of(context).size;

    const titleH = 60.0;
    const footerH = 60.0;

    return Scaffold(
      backgroundColor: HonooColor.tertiary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availH = constraints.maxHeight;
            final centerH =
            (availH - titleH - footerH).clamp(0.0, double.infinity);
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

                // CENTRO: carosello orizzontale con layout “HonooCard”
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                      BoxConstraints(maxWidth: maxW, maxHeight: centerH),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : (_moonHonoo.isEmpty
                          ? Center(
                        child: Text(
                          'Nessun honoo sulla Luna',
                          style: GoogleFonts.libreFranklin(
                            color: HonooColor.onTertiary,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                          : Padding(
                        // gutter esterno per non toccare mai i bordi
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        child: cs.CarouselSlider.builder(
                          itemCount: _moonHonoo.length,
                          options: cs.CarouselOptions(
                            height: centerH,
                            viewportFraction: 1.0, // no peek
                            enableInfiniteScroll: false,
                            padEnds: true, // margine su primo/ultimo
                            enlargeCenterPage:
                            false, // nessun enlarge orizzontale
                            scrollPhysics:
                            const BouncingScrollPhysics(),
                            onPageChanged: (i, _) =>
                                setState(() => _currentIndex = i),
                          ),
                          itemBuilder: (context, index, realIdx) {
                            return Padding(
                              // gutter interno per pagina
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: HonooCard(
                                honoo: _moonHonoo[index],
                              ),
                            );
                          },
                        ),
                      )),
                    ),
                  ),
                ),

                // FOOTER
                SizedBox(
                  height: footerH,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          "assets/icons/home_onTertiary.svg",
                          semanticsLabel: 'Home',
                        ),
                        iconSize: 60,
                        splashRadius: 25,
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 5.w),
                      IconButton(
                        icon: SvgPicture.asset(
                          "assets/icons/heart.svg",
                          semanticsLabel: 'Heart',
                        ),
                        iconSize: 60,
                        splashRadius: 25,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComingSoonPage(
                                header: Utility().heartMoonHeader,
                                quote: Utility().shakespeare,
                                bibliography: Utility().bibliography,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 5.w),
                      IconButton(
                        icon: SvgPicture.asset(
                          "assets/icons/reply.svg",
                          semanticsLabel: 'Reply',
                        ),
                        iconSize: 60,
                        splashRadius: 25,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComingSoonPage(
                                header: Utility().replyMoonHeader,
                                quote: Utility().shakespeare,
                                bibliography: Utility().bibliography,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
