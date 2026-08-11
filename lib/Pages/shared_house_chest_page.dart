import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Entities/chest_item.dart';
import '../Services/house_shared_content_service.dart';
import '../UI/hinoo_viewer.dart';
import '../UI/honoo_card.dart';
import '../Utility/honoo_colors.dart';
import '../Widgets/honoo_app_title.dart';
import '../Widgets/loading_spinner.dart';

class SharedHouseChestPage extends StatefulWidget {
  const SharedHouseChestPage({super.key, required this.ownerId});

  final String ownerId;

  @override
  State<SharedHouseChestPage> createState() => _SharedHouseChestPageState();
}

class _SharedHouseChestPageState extends State<SharedHouseChestPage> {
  final HouseSharedContentService _service = HouseSharedContentService();
  final PageController _pageController = PageController();
  List<ChestItem> _items = const [];
  bool _loading = true;
  Object? _error;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.fetch(widget.ownerId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: HonooAppTitle(onTap: () => Navigator.of(context).pop()),
            ),
            Expanded(child: _body()),
            if (_items.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${_index + 1} / ${_items.length}',
                  style: GoogleFonts.arvo(color: Colors.white70, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: LoadingSpinner(color: Colors.white));
    }
    if (_error != null) {
      return _message('Non riesco ad aprire lo scrigno. Riprova.');
    }
    if (_items.isEmpty) {
      return _message('Non ci sono ancora contenuti da mostrare.');
    }
    return LayoutBuilder(
      builder: (context, constraints) => PageView.builder(
        key: const ValueKey('shared-house-content'),
        controller: _pageController,
        itemCount: _items.length,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (context, index) {
          final item = _items[index];
          return item.when(
            honoo: (honoo) => Center(
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: HonooCard(honoo: honoo),
              ),
            ),
            hinoo: (hinoo) => Center(
              child: HinooViewer(
                draft: hinoo.draft,
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
                authorId: hinoo.ownerId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _message(String value) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: GoogleFonts.arvo(color: Colors.white, fontSize: 18),
      ),
    ),
  );
}
