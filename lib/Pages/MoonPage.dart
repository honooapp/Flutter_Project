import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../Entities/Honoo.dart';
import '../Entities/Hinoo.dart';
import 'ComingSoonPage.dart';
import '../Controller/DeviceController.dart';
import '../Services/HonooService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../UI/HonooCard.dart';
import '../UI/HinooViewer.dart';
import '../Utility/HonooColors.dart';
import '../Utility/Utility.dart';

class MoonPage extends StatefulWidget {
  const MoonPage({super.key});

  @override
  State<MoonPage> createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {
  List<Honoo> _moonHonoo = [];
  List<_MoonItem> _items = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMoonHonoo();
  }

  Future<void> _loadMoonHonoo() async {
    try {
      final dataHonoo = await HonooService.fetchPublicHonoo();

      // Fetch HINOO pubblici: type='moon'
      final client = Supabase.instance.client;
      final rows = await client
          .from('hinoo')
          .select('pages,type,recipient_tag,created_at')
          .eq('type', 'moon')
          .order('created_at', ascending: false);

      final List<_MoonItem> items = [];
      for (final h in dataHonoo) {
        final created = DateTime.tryParse(h.created_at) ?? DateTime.fromMillisecondsSinceEpoch(0);
        items.add(_MoonItem.honoo(h, created));
      }

      for (final r in (rows as List)) {
        final pages = r['pages'];
        if (pages is List) {
          final draft = HinooDraft(
            pages: pages
                .whereType<Map<String, dynamic>>()
                .map((e) => HinooSlide.fromJson(e))
                .toList(),
            type: HinooType.moon,
            recipientTag: r['recipient_tag'] as String?,
          );
          final created = DateTime.tryParse((r['created_at'] ?? '').toString()) ?? DateTime.now();
          items.add(_MoonItem.hinoo(draft, created));
        }
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _moonHonoo = dataHonoo;
        _items = items;
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
                          : (_items.isEmpty
                          ? Center(
                            child: Text(
                          'Nessun contenuto sulla Luna',
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
                          itemCount: _items.length,
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
                              child: _buildMoonItem(_items[index], centerH, maxW),
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

class _MoonItem {
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final DateTime createdAt;
  const _MoonItem._(this.honoo, this.hinoo, this.createdAt);
  factory _MoonItem.honoo(Honoo h, DateTime createdAt) => _MoonItem._(h, null, createdAt);
  factory _MoonItem.hinoo(HinooDraft d, DateTime createdAt) => _MoonItem._(null, d, createdAt);

  T when<T>({required T Function(Honoo h) honoo, required T Function(HinooDraft d) hinoo}) {
    if (this.honoo != null) return honoo(this.honoo!);
    return hinoo(this.hinoo!);
  }
}

Widget _buildMoonItem(_MoonItem item, double maxH, double maxW) {
  return item.when(
    honoo: (h) => HonooCard(honoo: h),
    hinoo: (d) => HinooViewer(draft: d, maxHeight: maxH, maxWidth: maxW),
  );
}
