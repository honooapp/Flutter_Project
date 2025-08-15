import 'package:flutter/material.dart';
import '../Entites/Honoo.dart';
import '../Services/HonooService.dart';
import '../UI/HonooCard.dart';
import '../Utility/HonooColors.dart';

class MoonPage extends StatefulWidget {
  const MoonPage({Key? key}) : super(key: key);

  @override
  State<MoonPage> createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {
  List<Honoo> _moonHonoo = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isEmpty = false;

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
        _hasError = false;
        _isEmpty = data.isEmpty;
      });
    } catch (e) {
      print("Errore caricamento Moon Honoo: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: HonooColor.background,
        body: Center(
          child: CircularProgressIndicator(
            color: HonooColor.primary,
          ),
        ),
      );
    }

    if (_hasError) {
      return const Scaffold(
        backgroundColor: HonooColor.background,
        body: Center(
          child: Text(
            'Errore nel caricamento degli honoo.',
            style: TextStyle(color: HonooColor.onBackground),
          ),
        ),
      );
    }

    if (_isEmpty) {
      return const Scaffold(
        backgroundColor: HonooColor.background,
        body: Center(
          child: Text(
            'Nessun honoo disponibile.',
            style: TextStyle(color: HonooColor.onBackground),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: ListView.builder(
        itemCount: _moonHonoo.length,
        itemBuilder: (context, index) {
          final honoo = _moonHonoo[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: HonooCard(honoo: honoo),
          );
        },
      ),
    );
  }
}
