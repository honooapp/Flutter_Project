import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Controller/DeviceController.dart';
import '../Entities/Hinoo.dart';
import '../Entities/Honoo.dart';
import 'ComingSoonPage.dart';
import '../Services/HonooService.dart';
import '../UI/HinooViewer.dart';
import '../UI/HonooCard.dart';
import '../Utility/HonooColors.dart';
import '../Utility/Utility.dart';

class MoonPage extends StatefulWidget {
  const MoonPage({super.key});

  @override
  State<MoonPage> createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {
  final PageController _pageController = PageController();
  bool _isLoading = true;
  List<_MoonItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadMoonContent();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMoonContent() async {
    try {
      final honoo = await HonooService.fetchPublicHonoo();

      final rows = await Supabase.instance.client
          .from('hinoo')
          .select('pages,recipient_tag,created_at')
          .eq('type', 'moon')
          .order('created_at', ascending: false);

      final List<_MoonItem> items = [];

      for (final h in honoo) {
        final created = DateTime.tryParse(h.created_at) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        items.add(_MoonItem.honoo(h, created));
      }

      for (final row in (rows as List)) {
        final pages = row['pages'];
        if (pages is List) {
          final draft = HinooDraft(
            pages: pages
                .whereType<Map<String, dynamic>>()
                .map(HinooSlide.fromJson)
                .toList(),
            type: HinooType.moon,
            recipientTag: row['recipient_tag'] as String?,
          );
          final created = DateTime.tryParse((row['created_at'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          items.add(_MoonItem.hinoo(draft, created));
        }
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Errore caricamento Moon: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento Moon: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 60;
    const double footerHeight = 60;
    final bool isPhone = DeviceController().isPhone();
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availHeight = constraints.maxHeight;
            final double centerHeight =
                (availHeight - headerHeight - footerHeight).clamp(0.0, double.infinity);
            final double maxWidth = isPhone ? size.width * 0.96 : size.width * 0.5;

            return Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Center(
                    child: Text(
                      Utility().appName,
                      style: GoogleFonts.libreFranklin(
                        color: HonooColor.secondary,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                        maxHeight: centerHeight,
                      ),
                      child: _buildBody(centerHeight, maxWidth),
                    ),
                  ),
                ),
                SizedBox(
                  height: footerHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/home_onTertiary.svg',
                          semanticsLabel: 'Home',
                        ),
                        iconSize: 60,
                        splashRadius: 25,
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 5.w),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/heart.svg',
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
                          'assets/icons/reply.svg',
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

  Widget _buildBody(double maxHeight, double maxWidth) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Nessun contenuto sulla Luna',
          style: GoogleFonts.libreFranklin(
            color: HonooColor.onTertiary,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      width: maxWidth,
      height: maxHeight,
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: _buildMoonItem(item, maxHeight, maxWidth),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoonItem(_MoonItem item, double maxHeight, double maxWidth) {
    if (item.honoo != null) {
      return HonooCard(honoo: item.honoo!);
    }

    final draft = item.hinoo!;
    return HinooViewer(
      draft: draft,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      gapColor: Colors.white,
    );
  }
}

class _MoonItem {
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final DateTime createdAt;

  const _MoonItem._(this.honoo, this.hinoo, this.createdAt);

  factory _MoonItem.honoo(Honoo h, DateTime createdAt) =>
      _MoonItem._(h, null, createdAt);

  factory _MoonItem.hinoo(HinooDraft h, DateTime createdAt) =>
      _MoonItem._(null, h, createdAt);
}
