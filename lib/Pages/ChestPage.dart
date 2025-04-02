import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:honoo/Controller/HonooController.dart';
import 'package:honoo/Pages/ConversationPage.dart';
import 'package:honoo/UI/HonooCard.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../Controller/DeviceController.dart';
import '../Entites/Honoo.dart';
import '../Utility/Utility.dart';


class ChestPage extends StatefulWidget {
  const ChestPage({super.key});


  @override
  State<ChestPage> createState() => _ChestPageState();
}

class _ChestPageState extends State<ChestPage> {

  cs.CarouselController carouselController = cs.CarouselController();
  List<Honoo> allHonooList = [];
  int currentCaruselIndex = 0;
  bool isFirstBuild = true;
  GlobalKey globalKey = GlobalKey();

  Future<void> captureAndShare() async {
    try {
      RenderRepaintBoundary? boundary = globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      ui.Image image = await boundary!.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      //share image
      //await Share.shareFiles(['data:image/png;base64,${base64Encode(pngBytes)}']);
      Share.shareXFiles([XFile('data:image/png;base64,${base64Encode(pngBytes)}')], text: 'Great picture');
      //await Share.shareXFiles([XFile.fromData(pngBytes)]);

    } catch (e) {
      print('Failed to capture and share screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    //Initialize the current index
    if (isFirstBuild) {
      currentCaruselIndex = HonooController().getPersonalHonoo().length;
      isFirstBuild = false;
    }

    IconButton moreButton = IconButton(
      icon: const Icon(Icons.expand_more),
      color: HonooColor.onBackground,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ConversationPage(honoo: allHonooList[currentCaruselIndex])),
        );
      },
    ); 

    IconButton chestHomeButton = IconButton(
      icon: SvgPicture.asset(
        "assets/icons/chest_home.svg",
        semanticsLabel: 'Chest Home',
      ),
      color: HonooColor.onBackground,
      onPressed: () { 

      }
    ); 

    IconButton shareButton = IconButton(
      icon: SvgPicture.asset(
        "assets/icons/share.svg",
        semanticsLabel: 'Share',
      ),
      onPressed: () { 
        captureAndShare();
      }
    );

    Card mainCard = Card(
      color: HonooColor.background,
      child: SizedBox(
        width: 100.w,
        height: 70.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(padding: EdgeInsets.only(top: 20),),
              Text(
                Utility().chestHeader,
                style: GoogleFonts.libreFranklin(
                  color: HonooColor.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              Expanded(
                  child: Stack(
                  children: [
                    Positioned(
                      top: 5.h,
                      left: MediaQuery.of(context).size.width/2 - 30,
                      child: Column(
                        children: [
                          Text(
                            Utility().chestSubHeader1,
                            style: GoogleFonts.libreFranklin(
                              color: HonooColor.onBackground,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Padding(padding: EdgeInsets.only(top: 20),),
                          SvgPicture.asset(
                            'assets/icons/honoo_chest_white.svg',
                            semanticsLabel: 'Icon',
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 35.h,
                      left: MediaQuery.of(context).size.width/2 - 30,
                      child: Column(
                        children: [
                          Text(
                            Utility().chestSubHeader3,
                            style: GoogleFonts.libreFranklin(
                              color: HonooColor.onBackground,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Padding(padding: EdgeInsets.only(top: 20),),
                          SvgPicture.asset(
                            'assets/icons/honoo_chest_red.svg',
                            semanticsLabel: 'Icon',
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 20.h,
                      right: MediaQuery.of(context).size.width/2 - 10,
                      child: Column(
                        children: [
                          Text(
                            Utility().chestSubHeader2,
                            style: GoogleFonts.libreFranklin(
                              color: HonooColor.onBackground,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Padding(padding: EdgeInsets.only(top: 20),),
                          SvgPicture.asset(
                            'assets/icons/honoo_chest_blue.svg',
                            semanticsLabel: 'Icon',
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: DeviceController().getHeight()/2 - 200,
                      right: 0,
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/arrow_right.svg',
                          semanticsLabel: 'Icon',
                        ), 
                        onPressed: () { 
                          setState(() {
                            carouselController.nextPage();
                          });
                        }
                      ),
                    ),
                    Positioned(
                      top: DeviceController().getHeight()/2 - 200,
                      left: 0,
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/arrow_left.svg',
                          semanticsLabel: 'Icon',
                        ), 
                        onPressed: () { 
                          setState(() {
                            carouselController.previousPage();
                          });
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    List<List<Honoo>> honooList = HonooController().getChestHonoo();
    
    List<Honoo> personalHonoo = honooList[0];
    List<Honoo> answerHonoo = honooList[1];

    List<Widget> honooCards = [];
    List<Widget> personalHonooCards = [];
    List<Widget> answerHonooCards = [];
    for (int i = 0; i < personalHonoo.length; i++) {
      personalHonooCards.add(HonooCard(honoo: personalHonoo[i]));
      allHonooList.add(personalHonoo[i]);
    }
    //Add a dummy honoo to allHonooList to make the retrieve function work -- FIX THIS LATER
    allHonooList.add(Honoo(0, "", "","","","",HonooType.answer));
    for (int i = 0; i < answerHonoo.length; i++) {
      answerHonooCards.add(HonooCard(honoo: answerHonoo[i]));
      allHonooList.add(answerHonoo[i]);
    }
    honooCards.insertAll(0, personalHonooCards);
    honooCards.insert(honooCards.length, mainCard);
    honooCards.insertAll(honooCards.length, answerHonooCards);


    return Scaffold(
      backgroundColor: HonooColor.background,
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
                constraints: DeviceController().isPhone() ? BoxConstraints(maxWidth: 100.w, maxHeight: 100.h -120) : BoxConstraints(maxWidth: 50.w, maxHeight: 100.h - 120),
                child:Column(
                  children: [
                    Expanded(
                      child: cs.CarouselSlider(
                        carouselController: carouselController,
                        options: cs.CarouselOptions(
                          initialPage: personalHonoo.length,
                          height: 70.h,
                          aspectRatio: 9/16,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              currentCaruselIndex = index;
                            });
                          },
                        ),
                        items: honooCards,
                      ),
                    ),
                    SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(icon: SvgPicture.asset(
                            color: HonooColor.onBackground,
                            "assets/icons/home.svg",
                            semanticsLabel: 'Home',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: () {
                            Navigator.pop(context);
                          }),
                          currentCaruselIndex <= personalHonoo.length ? Container() : Padding(padding: EdgeInsets.only(left: 5.w)),
                          currentCaruselIndex <= personalHonoo.length ? Container() : moreButton,
                          currentCaruselIndex == personalHonoo.length ? Container() : Padding(padding: EdgeInsets.only(left: 5.w)),
                          currentCaruselIndex == personalHonoo.length ? Container() : chestHomeButton,
                          shareButton,
                          /*
                          Padding(padding: EdgeInsets.only(left: 5.w)),
                          IconButton(icon: SvgPicture.asset(
                            "assets/icons/heart.svg",
                            semanticsLabel: 'Heart',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: () {
                            //TODO: Add to favorites
                          }),
                          Padding(padding: EdgeInsets.only(left: 5.w)),
                          IconButton(icon: SvgPicture.asset(
                            color: HonooColor.onBackground,
                            "assets/icons/reply.svg",
                            semanticsLabel: 'Reply',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: () {
                            //TODO: reply
                          }),
                          */
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
