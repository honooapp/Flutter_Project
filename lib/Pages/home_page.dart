import 'package:flutter/material.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Controller/device_controller.dart';
import '../Utility/utility.dart';
import '../Widgets/honoo_app_title.dart';
import 'placeholder_page.dart';
import 'package:sizer/sizer.dart';

// Widgets riutilizzabili
import '../Widgets/sea_footer_bar.dart';
import '../Widgets/luna_fissa.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // CONTENUTO PRINCIPALE
          Column(
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
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 100.w,
                    child: Row(
                      children: [
                        Expanded(child: Container()),
                        Container(
                          constraints: DeviceController().isPhone()
                              ? BoxConstraints(maxWidth: 100.w)
                              : BoxConstraints(maxWidth: 50.w),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 80.h,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      top: 0,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 32),
                                              Text(
                                                Utility().textHome1,
                                                style: GoogleFonts.arvo(
                                                  color:
                                                      HonooColor.onBackground,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                Utility().textHome2,
                                                style: GoogleFonts.arvo(
                                                  color:
                                                      HonooColor.onBackground,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
                  ),
                ),
              ),

              // FOOTER sostituito col widget riutilizzabile
              const SeaFooterBar(),
            ],
          ),

          // 🌙 LUNA FISSA (riutilizzabile ovunque)
          const LunaFissa(),
        ],
      ),
    );
  }
}
