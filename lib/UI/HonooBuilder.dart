import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';

import '../Utility/HonooColors.dart';
import '../Utility/LineLengthLimitingTextInputFormatter.dart';

class HonooBuilder extends StatefulWidget {
  final void Function(String text, String imagePath)? onHonooChanged; // ✅ CALLBACK AGGIUNTA

  const HonooBuilder({super.key, this.onHonooChanged});

  @override
  State<HonooBuilder> createState() => _HonooBuilderState();
}

class _HonooBuilderState extends State<HonooBuilder> {
  XFile? image;
  final TextEditingController _textFieldController = TextEditingController();
  ImageProvider? imageProvider;

  void _emitChange() {
    if (widget.onHonooChanged != null && image != null) {
      widget.onHonooChanged!.call(_textFieldController.text, image!.path);
    } else if (widget.onHonooChanged != null) {
      widget.onHonooChanged!.call(_textFieldController.text, '');
    }
  }

  @override
  void initState() {
    super.initState();
    _textFieldController.addListener(_emitChange); // ascolta il testo
  }

  @override
  void dispose() {
    _textFieldController.removeListener(_emitChange);
    _textFieldController.dispose();
    super.dispose();
  }

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
                borderRadius: BorderRadius.circular(5),
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
                            LineLengthLimitingTextInputFormatter(
                                maxLineLength: 31, maxLines: 5),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Scrivi qui il tuo testo',
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
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          '${144 - _textFieldController.text.length}',
                          style: GoogleFonts.arvo(
                            color: HonooColor.onTertiary,
                            fontSize: 9,
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
          Expanded(
            child: Padding(
              padding:
              const EdgeInsets.only(bottom: 15.0, left: 15.0, right: 15.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  decoration: image == null
                      ? BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(0, 255, 255, 255),
                      width: 1.0,
                    ),
                    color: HonooColor.tertiary,
                    borderRadius: BorderRadius.circular(5),
                  )
                      : BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: imageProvider!,
                    ),
                  ),
                  width: 100.w,
                  child: image == null
                      ? Column(
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
                      IconButton(
                        iconSize: 50,
                        icon: const Icon(
                          Icons.photo,
                          color: HonooColor.primary,
                        ),
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? selectedImage = await picker
                              .pickImage(source: ImageSource.gallery);
                          if (selectedImage != null) {
                            setState(() {
                              image = selectedImage;
                              if (kIsWeb) {
                                imageProvider =
                                    NetworkImage(image!.path);
                              } else {
                                imageProvider =
                                    FileImage(File(image!.path));
                              }
                            });
                            _emitChange(); // aggiorna callback
                          }
                        },
                      ),
                    ],
                  )
                      : Column(
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
                            image = null;
                            imageProvider = null;
                          });
                          _emitChange(); // resetta anche nella callback
                        },
                      ),
                    ],
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
