import 'package:flutter/material.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Controller/DeviceController.dart';
import '../Entites/Honoo.dart';
import '../UI/HonooBuilder.dart';
import '../Utility/Utility.dart';
import 'package:sizer/sizer.dart';
import 'package:honoo/Services/HonooService.dart';
import 'EmailLoginPage.dart';


class NewHonooPage extends StatefulWidget {
  const NewHonooPage({super.key});

  @override
  State<NewHonooPage> createState() => _NewHonooPageState();
}

class _NewHonooPageState extends State<NewHonooPage> {
  String _text = '';
  String _imageUrl = '';
  HonooType _selectedType = HonooType.personal; // default = Scrigno

  void _onHonooChanged(String text, String imageUrl) {
    setState(() {
      _text = text;
      _imageUrl = imageUrl;
    });
  }

  Future<void> _submitHonoo() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      // 👣 Utente non loggato → vai al login e poi torna qui
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailLoginPage(
            pendingHonooText: _text,
            pendingImageUrl: _imageUrl,
          ),
        ),
      );
      return;
    } else {
      // 👤 Utente loggato → crea e salva l'honoo
      final newHonoo = Honoo(
        0,
        _text,
        _imageUrl,
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
        user.id,
        HonooType.personal, // salviamo nello scrigno
        null,
        null,
      );

      try {
        await HonooService.publishHonoo(newHonoo);

        if (!mounted) return; // evita usare context se la pagina è stata smontata
        // ✅ Vai subito allo scrigno
        Navigator.pushReplacementNamed(context, '/chest');
      } catch (e, st) {
        debugPrint('publishHonoo failed: $e\n$st'); // stampa il messaggio reale
        if (mounted) {
          final msg = e.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $msg')),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceController().isPhone();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: SafeArea( // <-- gestisce padding di sistema e notch
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Spazio verticale disponibile dentro SafeArea
            final double availH = constraints.maxHeight;

            // Altezza del titolo (fissa) e del footer (fissa)
            const double titleH = 60;
            const double footerH = 60;

            // Altezza residua per il blocco centrale (HonooBuilder)
            final double centerH = (availH - titleH - footerH).clamp(0.0, double.infinity);

            // Larghezza massima del blocco centrale
            final double maxW = isPhone ? size.width * 0.96 : size.width * 0.5;

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

                // CENTRO: contenitore del builder, centrato e con vincoli puliti
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxW,
                        // diamo un'altezza finita al builder: occupa tutto il centro
                        maxHeight: centerH,
                      ),
                      child: Column(
                        children: [
                          // HonooBuilder prende TUTTA l’altezza residua del centro
                          Expanded(
                            child: HonooBuilder(
                              onHonooChanged: _onHonooChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // FOOTER (bottoni)
                SizedBox(
                  height: footerH,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          "assets/icons/home.svg",
                          semanticsLabel: 'Home',
                        ),
                        iconSize: 60,
                        splashRadius: 25,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 32), // spaziatura orizzontale
                      IconButton(
                        icon: SvgPicture.asset(
                          "assets/icons/ok.svg",
                          semanticsLabel: 'OK',
                        ),
                        iconSize: 60,
                        splashRadius: 25,
                        onPressed: _submitHonoo,
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

