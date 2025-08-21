import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Controller/DeviceController.dart';
import '../Entites/Honoo.dart';
import '../Services/HonooImageUploader.dart';
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
    }

    // Risolve in URL pubblica (web: rifiuta blob; mobile: da path fa upload)
    final String? finalImageUrl = await _resolveFinalImageUrl(_imageUrl);

    // 👮‍♀️ Guardia: immagine OBBLIGATORIA
    if (finalImageUrl == null || finalImageUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devi caricare un’immagine (URL pubblico).')),
        );
      }
      return;
    }

    final newHonoo = Honoo(
      0,
      _text,
      finalImageUrl, // ✅ ora è sempre una https pubblica
      DateTime.now().toIso8601String(),
      DateTime.now().toIso8601String(),
      user.id,
      HonooType.personal,
      null,
      null,
    );

    try {
      await HonooService.publishHonoo(newHonoo);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/chest');
    } catch (e, st) {
      debugPrint('publishHonoo failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  /// Normalizza l'immagine per il salvataggio:
  /// - se è HTTPS pubblico, la usa così com'è
  /// - se è path locale (mobile), la carica su Supabase e ritorna la public URL
  /// - se è blob: (web), non è utilizzabile qui → ritorna null con avviso
  Future<String?> _resolveFinalImageUrl(String raw) async {
    final s = (raw).trim();
    if (s.isEmpty) return null;

    // già una URL http/https → usala
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return s;
    }

    // blob: su Web non è caricabile da qui (servono i bytes a monte)
    if (kIsWeb && s.startsWith('blob:')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Immagine locale (blob) non caricabile dal browser.')),
        );
      }
      return null;
    }

    // Mobile: path locale → carica su Storage e ottieni public URL
    final uploaded = await HonooImageUploader.uploadImageFromPath(s);
    return uploaded; // può essere null in caso di errore
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

