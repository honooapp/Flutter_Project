import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


import '../Entites/Honoo.dart';

class HonooCard extends StatelessWidget {

  final Honoo honoo;

  const HonooCard({super.key, required this.honoo});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF20205A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFFFFFF),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(20)
              ),
              child: SizedBox(
                width: 100.w,
                height: 25.h,
                child: Center(
                  child:Text(
                    honoo.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.arvo(
                      color: const Color(0xFFFFFFFF),
                      fontSize: 18,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child:Padding(
            padding: const EdgeInsets.only(bottom: 15.0, left: 15.0, right: 15.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  width: 100.w,
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
        ],
      ),
    );
  }
}
