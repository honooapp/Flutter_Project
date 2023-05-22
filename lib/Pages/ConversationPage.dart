import 'package:flutter/material.dart';
import 'package:honoo/Controller/HonooController.dart';
import 'package:honoo/UI/HonooCard.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';


import '../Controller/DeviceController.dart';
import '../Entites/Honoo.dart';
import '../Utility/Utility.dart';
import 'package:sizer/sizer.dart';


class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key, required this.honoo});
  
  final Honoo honoo;
  
  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {

  CarouselController carouselController = CarouselController();

  List<Widget> honooCards = [];

  void buildHonooHistoryCards() {
    HonooController().getHonooHistory(widget.honoo).forEach((element) {
      honooCards.add(HonooCard(honoo: element));
    });
  }


  @override
  Widget build(BuildContext context) {

    buildHonooHistoryCards();

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
                constraints: DeviceController().isPhone() ? BoxConstraints(maxWidth: 85.w, maxHeight: 100.h -120) : BoxConstraints(maxWidth: 50.w, maxHeight: 100.h - 120),
                child:Column(
                  children: [
                    Expanded(
                      child: CarouselSlider(
                        carouselController: carouselController,
                        options: CarouselOptions(
                          scrollDirection: Axis.vertical,
                          height: 100.h,
                          aspectRatio: 9/16,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
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
                          Padding(padding: EdgeInsets.only(left: 5.w)),
                          IconButton(icon: SvgPicture.asset(
                            "assets/icons/broken_heart.svg",
                            semanticsLabel: 'Broken heart',
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
