import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../Controller/DeviceController.dart';
// MOCK: HonooController().getChestHonoo() era usato per simulare i dati locali
// Ora i dati reali vengono caricati da Supabase attraverso HonooService.fetchUserHonoo(...)
import '../Controller/HonooController.dart';

import '../Entites/Honoo.dart';
import '../Services/HonooService.dart';
import '../UI/HonooCard.dart';
import '../Utility/HonooColors.dart';
import '../Utility/Utility.dart';
import 'ComingSoonPage.dart';

class ChestPage extends StatefulWidget {
  const ChestPage({super.key});

  @override
  State<ChestPage> createState() => _ChestPageState();
}

class _ChestPageState extends State<ChestPage> {
  int currentCarouselIndex = 0;

  List<Honoo> _personalHonoo = [];
  List<Honoo> _receivedHonoo = [];
  bool _isLoading = true;

  final String _userTag = 'anonimo'; // da sostituire se si vuole rendere dinamico

  @override
  void initState() {
    super.initState();
    _loadChestHonoo();
  }

  Future<void> _loadChestHonoo() async {
    try {
      final personal = await HonooService.fetchUserHonoo(_userTag, 'chest');
      final received = await HonooService.fetchRepliesForUser(_userTag);
      setState(() {
        _personalHonoo = personal;
        _receivedHonoo = received;
        _isLoading = false;
      });
    } catch (e) {
      print("Errore caricamento honoo da Supabase: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget get moreButton => IconButton(
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
            header: "Honoo ricevuti",
            quote: "Un giorno anche tu riceverai un honoo.",
            bibliography: "",
          ),
        ),
      );
    },
  );

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
                      child: PageView.builder(
                        itemCount: _personalHonoo.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentCarouselIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return HonooCard(honoo: _personalHonoo[index]);
                        },
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: FractionalOffset.bottomCenter,
                        child: SizedBox(
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
                                },
                              ),
                              currentCarouselIndex >= _personalHonoo.length - 1
                                  ? Padding(padding: EdgeInsets.only(left: 5.w))
                                  : Container(),
                              currentCarouselIndex >= _personalHonoo.length - 1
                                  ? moreButton
                                  : Container(),
                              currentCarouselIndex < _personalHonoo.length - 1
                                  ? Padding(padding: EdgeInsets.only(left: 5.w))
                                  : Container(),
                              currentCarouselIndex < _personalHonoo.length - 1
                                  ? Container()
                                  : Container(),
                            ],
                          ),
                        ),
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
