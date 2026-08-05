import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Pages/moon_page.dart';
import 'package:honoo/Services/admin_service.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/UI/hinoo_typography.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/honoo_scaffold.dart';
import 'package:honoo/Widgets/loading_spinner.dart';

class AdminMoonSearchPage extends StatefulWidget {
  const AdminMoonSearchPage({super.key});

  @override
  State<AdminMoonSearchPage> createState() => _AdminMoonSearchPageState();
}

class _AdminMoonSearchPageState extends State<AdminMoonSearchPage> {
  final AdminService _adminService = AdminService();
  late final Future<bool> _adminCheck;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String _query = '';
  List<_MoonSearchItem> _results = const [];

  @override
  void initState() {
    super.initState();
    _adminCheck = _adminService.isCurrentUserAdmin();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _search(value.trim());
    });
  }

  Future<void> _search(String q) async {
    setState(() {
      _query = q;
      _loading = true;
    });
    try {
      if (q.isEmpty) {
        setState(() {
          _results = const [];
          _loading = false;
        });
        return;
      }
      final client = SupabaseProvider.client;
      // Prova filtro server-side su testo honoo e json pages (fallback client-side se non supportato)
      List rows;
      try {
        rows = await client
            .from('moon_public')
            .select(
              'id,user_id,kind,pages,text,image_url,recipient_tag,created_at',
            )
            .or('text.ilike.%$q%,pages.ilike.%$q%')
            .order('created_at', ascending: false)
            .limit(250);
      } catch (_) {
        // Fallback: carica ultimi N e filtra lato client
        final raw = await client
            .from('moon_public')
            .select(
              'id,user_id,kind,pages,text,image_url,recipient_tag,created_at',
            )
            .order('created_at', ascending: false)
            .limit(250);
        rows = (raw as List)
            .where((e) => _matchesQuery(e as Map<String, dynamic>, q))
            .toList();
      }

      final List<_MoonSearchItem> items = [];
      for (final row in rows) {
        if (row is! Map) continue;
        final String kind = row['kind']?.toString() ?? '';
        final created =
            DateTime.tryParse((row['created_at'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (kind == 'honoo') {
          final honoo = Honoo.fromMap(row.cast<String, dynamic>());
          items.add(_MoonSearchItem.honoo(honoo, created));
        } else if (kind == 'hinoo') {
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
            final String? id = row['id']?.toString();
            final String? ownerId = row['user_id']?.toString();
            items.add(
              _MoonSearchItem.hinoo(
                draft,
                created,
                hinooId: id,
                ownerId: ownerId,
              ),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _results = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showHonooToast(context, message: 'Errore ricerca: $e');
    }
  }

  bool _matchesQuery(Map<String, dynamic> row, String q) {
    final qq = q.toLowerCase();
    final kind = row['kind']?.toString() ?? '';
    if (kind == 'honoo') {
      final t = (row['text']?.toString() ?? '').toLowerCase();
      return t.contains(qq);
    }
    if (kind == 'hinoo') {
      final pages = row['pages'];
      if (pages is List) {
        for (final p in pages) {
          if (p is Map &&
              (p['text']?.toString().toLowerCase() ?? '').contains(qq)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      hintText: 'Cerca sulla Luna (parole)…',
      hintStyle: GoogleFonts.lora(color: Colors.white70, fontSize: 16),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white60),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );

    return FutureBuilder<bool>(
      future: _adminCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const HonooScaffold(
            body: Center(child: LoadingSpinner(color: Colors.white)),
          );
        }
        final isAdmin = snapshot.data == true;
        if (!isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }

        return HonooScaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cerca sulla Luna',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.arvo(
                    color: HonooColor.onBackground,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(color: Colors.white, fontSize: 16),
                  cursorColor: Colors.white,
                  decoration: inputDecoration.copyWith(
                    suffixIcon: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: LoadingSpinner(
                              size: 16,
                              color: Colors.white,
                            ),
                          )
                        : (_query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Pulisci',
                                  onPressed: () {
                                    _controller.clear();
                                    _onQueryChanged('');
                                  },
                                  icon: SvgPicture.asset(
                                    'assets/icons/cancella.svg',
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      HonooColor.onBackground,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                )),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildResultsList()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsList() {
    if (_query.isEmpty) {
      return Center(
        child: Text(
          'Digita per cercare honoo e hinoo pubblici',
          style: GoogleFonts.libreFranklin(
            color: HonooColor.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_loading) {
      return const Center(child: LoadingSpinner(color: Colors.white));
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'Nessun risultato',
          style: GoogleFonts.libreFranklin(
            color: HonooColor.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isNarrow = w < 700;
        final double maxTileW = isNarrow
            ? w
            : (w / 3).clamp(300.0, 420.0).toDouble();
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxTileW,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final item = _results[index];
            return _buildTile(item);
          },
        );
      },
    );
  }

  Widget _buildTile(_MoonSearchItem item) {
    final Widget inner = item.when(
      honoo: (h) => Center(child: HonooCard(honoo: h)),
      hinoo: (draft) {
        return LayoutBuilder(
          builder: (ctx, c) {
            final size = _fitAspect(
              c.maxWidth,
              c.maxHeight,
              HinooTypography.aspectRatio,
            );
            return Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: HinooViewer(
                  draft: draft,
                  maxHeight: size.height,
                  maxWidth: size.width,
                ),
              ),
            );
          },
        );
      },
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final String? id = item.when(
            honoo: (h) => h.dbId,
            hinoo: (_) => item.hinooId,
          );
          if (id == null || id.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MoonPage(initialItemId: id)),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(padding: const EdgeInsets.all(8.0), child: inner),
        ),
      ),
    );
  }

  ui.Size _fitAspect(double maxW, double maxH, double aspect) {
    double w = maxW;
    double h = w / aspect;
    if (h > maxH) {
      h = maxH;
      w = h * aspect;
    }
    return ui.Size(w, h);
  }
}

class _MoonSearchItem {
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final String? hinooId;
  final String? ownerId;
  final DateTime createdAt;

  const _MoonSearchItem._(
    this.honoo,
    this.hinoo,
    this.createdAt,
    this.hinooId,
    this.ownerId,
  );

  factory _MoonSearchItem.honoo(Honoo h, DateTime createdAt) =>
      _MoonSearchItem._(h, null, createdAt, null, null);

  factory _MoonSearchItem.hinoo(
    HinooDraft d,
    DateTime createdAt, {
    String? hinooId,
    String? ownerId,
  }) => _MoonSearchItem._(null, d, createdAt, hinooId, ownerId);

  T when<T>({
    required T Function(Honoo h) honoo,
    required T Function(HinooDraft d) hinoo,
  }) {
    if (this.honoo != null) return honoo(this.honoo!);
    return hinoo(this.hinoo!);
  }
}
