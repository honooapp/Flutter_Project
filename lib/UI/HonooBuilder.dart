import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';


import '../Entites/Honoo.dart';
import '../Utility/LineLengthLimitingTextInputFormatter.dart';

class HonooBuilder extends StatefulWidget {
  const HonooBuilder({super.key});


  @override
  State<HonooBuilder> createState() => _HonooBuilderState();
}

class _HonooBuilderState extends State<HonooBuilder> {

  XFile? image;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF20205A),
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
                  color: Color(0xFFFFFFFF),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(20)
              ),
              child: SizedBox(
                width: 100.w,
                height: 25.h,
                child: Center(
                  child:TextField(
                    textAlignVertical: TextAlignVertical.center,
                    textAlign: TextAlign.center,
                    maxLines: null,
                    inputFormatters: [
                      LineLengthLimitingTextInputFormatter(maxLineLength: 27, maxLines: 5),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Componi qui il tuo honoo',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Color(0x88FFFFFF),
                        fontSize: 18,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
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
                  decoration: image == null ? BoxDecoration(
                    border: Border.all(
                      color: Color(0xFFFFFFFF),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(20)
                  ) : BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(File(image!.path)),
                    ),
                  ),
                  width: 100.w,
                  child: image == null ? 
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Aggiungi un\'immagine',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.arvo(
                          color: const Color(0x88FFFFFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 30)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 50,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFFFFFFFF),
                            ),
                            onPressed: () async {
                              final ImagePicker _picker = ImagePicker();
                              final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                              if (image != null) {
                                setState(() {
                                  this.image = image;
                                });
                              }
                            },
                          ),
                          const Padding(padding: EdgeInsets.only(right: 20)),
                          IconButton(
                            iconSize: 50,
                            icon: const Icon(
                              Icons.photo,
                              color: Color(0xFFFFFFFF),
                            ),
                            onPressed: () async {
                              final ImagePicker _picker = ImagePicker();
                              final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setState(() {
                                  this.image = image;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ) : 
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          iconSize: 30,
                          icon: const Icon(
                            Icons.delete,
                            color: Color(0xFFFFFFFF),
                          ),
                          onPressed: () {
                            setState(() {
                              //destroy image
                              image = null;
                            });
                          },
                        ),
                      ],
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
