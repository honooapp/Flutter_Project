import 'package:flutter/material.dart';
import 'package:honoo/Controller/NimController.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Controller/DeviceController.dart';
import '../Utility/HonooColors.dart';
import '../Utility/Utility.dart';
import 'package:sizer/sizer.dart';

import 'HomePage.dart';


class NimPage extends StatefulWidget {
  const NimPage({super.key});


  @override
  State<NimPage> createState() => _NimPageState();
}

class _NimPageState extends State<NimPage> {

  final TextEditingController _controller = TextEditingController();
  TextEditingController removeTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    _controller.text = NimController().drawGame();

    return Scaffold(
      backgroundColor: const Color(0xFF000026),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: Center( 
              child:Text(
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
                constraints: DeviceController().isPhone() ? BoxConstraints(maxWidth: 100.w, maxHeight: 100.h -60) : BoxConstraints(maxWidth: 50.w, maxHeight: 100.h - 60),
                child:Column(
                  children: [
                    TextField(
                        controller: _controller,
                        style: GoogleFonts.arvo(
                          color: const Color(0xFF9E172F),
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlignVertical: TextAlignVertical.center,
                        maxLines: 4,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "",
                          hintStyle: GoogleFonts.arvo(
                            color: const Color(0xFF9E172F),
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    const Padding(padding: EdgeInsets.all(30)),
                    //button to start the game
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              NimController().startGame();
                              _controller.text = NimController().drawGame();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFF000026), backgroundColor: const Color(0xFF9E172F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: const Text("Gioca"),
                        ),
                        //reset button
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                NimController().resetGame();
                                _controller.text = "";
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: const Color(0xFF000026), backgroundColor: const Color(0xFF9E172F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                            child: const Text("Reset"),
                          ),
                        ),
                        //input to insert the number of matches to remove
                        SizedBox(
                            width: 50,
                            child: TextField(
                              controller: removeTextController,
                              style: GoogleFonts.arvo(
                                color: const Color(0xFF9E172F),
                                fontSize: 40,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "",
                                hintStyle: GoogleFonts.arvo(
                                  color: const Color(0xFF9E172F),
                                  fontSize: 40,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        //button to remove the matches
                        ElevatedButton(
                            onPressed: () {
                              setState(() {
                                NimController().playerMove(int.parse(removeTextController.text.split(' ')[0]), removeTextController.text.split(' ')[1].split(',').map(int.parse).toList());
                                NimController().changePlayer();
                                NimController().aiMove();
                                _controller.text = NimController().drawGame();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: const Color(0xFF000026), backgroundColor: const Color(0xFF9E172F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                            child: const Text("Togli"),
                          ),
                      ],
                    ),
                    SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: SvgPicture.asset(
                              "assets/icons/home.svg",
                              semanticsLabel: 'Home',
                            ),
                            iconSize: 60,
                            tooltip: 'Indietro',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                              );
                            },
                          ),
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
