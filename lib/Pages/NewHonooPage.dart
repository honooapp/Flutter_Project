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
import '../../Pages/ComingSoonPage.dart';
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
    }

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

      // ✅ Vai subito allo scrigno
      Navigator.pushReplacementNamed(context, '/chest'); // oppure: MaterialPageRoute(builder: (_) => ChestPage())
    } catch (e) {
      print("Errore durante il salvataggio dell'honoo: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Column(
        children: [
          SizedBox(
            height: 60,
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
          Row(
            children: [
              Expanded(child: Container()),
              Container(
                constraints: DeviceController().isPhone()
                    ? BoxConstraints(maxWidth: 100.w, maxHeight: 100.h - 60)
                    : BoxConstraints(maxWidth: 50.w, maxHeight: 100.h - 60),
                child: Column(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 70.h,
                        // MOCK: prima versione statica
                        // child: const HonooBuilder(),

                        // REALE: builder con callback
                        child: HonooBuilder(
                          onHonooChanged: _onHonooChanged,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 60,
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
                              }),
                          Padding(padding: EdgeInsets.only(left: 20.w)),
                          IconButton(
                              icon: SvgPicture.asset(
                                "assets/icons/ok.svg",
                                semanticsLabel: 'Home',
                              ),
                              iconSize: 60,
                              splashRadius: 25,
                              onPressed: () {
                                // MOCK: logica temporanea
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => ComingSoonPage(
                                //       header: Utility().honooInsertTemporary,
                                //       quote: Utility().shakespeare,
                                //       bibliography: Utility().bibliography,
                                //     ),
                                //   ),
                                // );

                                // REALE: invio a Supabase
                                _submitHonoo();
                              }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ],
      ),
    );
  }
}
