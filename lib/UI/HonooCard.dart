import 'package:flutter/material.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


import '../Entites/Honoo.dart';

class HonooCard extends StatelessWidget {

  final Honoo honoo;

  const HonooCard({super.key, required this.honoo});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: honoo.type == HonooType.moon ? HonooColor.tertiary : honoo.type == HonooType.answer ? HonooColor.secondary : honoo.type == HonooType.personal ? HonooColor.background : HonooColor.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      child:
        // Padding(
        // padding: const EdgeInsets.only(left: 38.0, right: 38.0),
        // child:
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: honoo.type == HonooType.moon ? HonooColor.tertiary : honoo.type == HonooType.answer ? HonooColor.secondary : honoo.type == HonooType.personal ? HonooColor.background : HonooColor.tertiary,
                    border: Border.all(
                      color: Colors.transparent,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: const Offset(7, 3), // changes the position of the shadow
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 100.w,
                    height: 30.h,
                    child: Center(
                      child:Text(
                        honoo.text,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.arvo(
                          color: honoo.type == HonooType.moon ? HonooColor.onTertiary : honoo.type == HonooType.answer ? HonooColor.onBackground : honoo.type == HonooType.personal ? HonooColor.onBackground : HonooColor.onBackground,
                          fontSize: 18,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Expanded(child:Padding(
              //   padding: const EdgeInsets.only(bottom: 15.0, left: 15.0, right: 15.0),
              //     child: ClipRRect(
              //       borderRadius: BorderRadius.circular(5.0),
              //       child: Container(
              //         width: 100.w,
              //         decoration: BoxDecoration(
              //           image: DecorationImage(
              //             fit: BoxFit.cover,
              //             image: NetworkImage(honoo.image),
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15.0, left: 15.0, right: 15.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: AspectRatio(
                      aspectRatio: 1, // Ensures the widget is always a square
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(honoo.image),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        // ),
    );
  }
}
