import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';


import '../Utility/HonooColors.dart';
import '../Utility/LineLengthLimitingTextInputFormatter.dart';

class HonooBuilder extends StatefulWidget {
  const HonooBuilder({super.key});

  @override
  State<HonooBuilder> createState() => _HonooBuilderState();
}

class _HonooBuilderState extends State<HonooBuilder> {

  XFile? image;
  final TextEditingController _textFieldController = TextEditingController();
  ImageProvider? imageProvider;


  @override
  Widget build(BuildContext context) {
    return Card(
      color: HonooColor.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              decoration: BoxDecoration(
                color: HonooColor.tertiary,
                border: Border.all(
                  //color: HonooColor.wave3,
                  //width: 1.0,
                ),
                borderRadius: BorderRadius.circular(5)
              ),
              child: SizedBox(
                width: 100.w,
                height: 25.h,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: TextField(
                          controller: _textFieldController,
                          textAlignVertical: TextAlignVertical.center,
                          textAlign: TextAlign.center,
                          maxLines: null,
                          inputFormatters: [
                            LineLengthLimitingTextInputFormatter(maxLineLength: 31, maxLines: 5),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Scrivi qui in tuo testo',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: HonooColor.wave3,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: GoogleFonts.arvo(
                            color: HonooColor.onTertiary,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          '${144-_textFieldController.text.length}',
                          style: GoogleFonts.arvo(
                            color: HonooColor.onTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child:Padding(
            padding: const EdgeInsets.only(bottom: 15.0, left: 15.0, right: 15.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  decoration: image == null ? BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(0, 255, 255, 255),
                      width: 1.0,
                    ),
                    color: HonooColor.tertiary,
                    borderRadius: BorderRadius.circular(5)
                  ) : BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: imageProvider!,
                    ),
                  ),
                  width: 100.w,
                  child: image == null ? 
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Carica qui la tua immagine',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.arvo(
                          color: HonooColor.onSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
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
                              color: HonooColor.primary,
                            ),
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.camera);
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
                              color: HonooColor.primary,
                            ),
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setState(() {
                                  this.image = image;
                                  if (kIsWeb) {
                                    imageProvider = NetworkImage(image.path);
                                  } else {
                                    imageProvider = FileImage(File(image.path));
                                  }
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
                            color: HonooColor.onBackground,
                          ),
                          onPressed: () {
                            setState(() {
                              //destroy image
                              image = null;
                              imageProvider = null;
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
