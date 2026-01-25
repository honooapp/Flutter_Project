import 'package:flutter/material.dart';
import 'package:honoo/Controller/nim_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Utility/responsive_layout.dart';

import '../Controller/device_controller.dart';
import '../Widgets/honoo_app_title.dart';
import 'package:sizer/sizer.dart';

import 'home_page.dart';
import 'placeholder_page.dart';

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
    final double viewWidth = MediaQuery.of(context).size.width;
    final ResponsiveLayoutMode layoutMode =
        ResponsiveLayout.modeForWidth(viewWidth);
    final double footerIconSize =
        ResponsiveLayout.footerIconSizeForMode(layoutMode);
    final double footerBottomPadding =
        ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final double footerSpacing = footerBottomPadding + safeBottom;
    final double footerTopSpacing = footerSpacing / 2;
    final double footerBottomSpacing = footerSpacing - footerTopSpacing;
    final double footerGap = ResponsiveLayout.footerGapForMode(layoutMode);

    return Scaffold(
      backgroundColor: const Color(0xFF000026),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: Center(
              child: HonooAppTitle(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const PlaceholderPage()),
                    (route) => false,
                  );
                },
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
                            foregroundColor: const Color(0xFF000026),
                            backgroundColor: const Color(0xFF9E172F),
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
                              foregroundColor: const Color(0xFF000026),
                              backgroundColor: const Color(0xFF9E172F),
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
                              NimController().playerMove(
                                  int.parse(
                                      removeTextController.text.split(' ')[0]),
                                  removeTextController.text
                                      .split(' ')[1]
                                      .split(',')
                                      .map(int.parse)
                                      .toList());
                              NimController().changePlayer();
                              NimController().aiMove();
                              _controller.text = NimController().drawGame();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFF000026),
                            backgroundColor: const Color(0xFF9E172F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: const Text("Togli"),
                        ),
                      ],
                    ),
                    SizedBox(height: footerTopSpacing),
                    ResponsiveFooterBar(
                      useSafeArea: false,
                      bottomPadding: footerBottomSpacing,
                      desiredGap: footerGap,
                      minGap: 16,
                      height: footerIconSize,
                      mainAxisAlignment: MainAxisAlignment.start,
                      alignment: Alignment.centerLeft,
                      actions: [
                        ResponsiveFooterAction(
                          asset: "assets/icons/home.svg",
                          semanticsLabel: 'Home',
                          size: footerIconSize,
                          tooltip: 'Home',
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const HomePage()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
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
