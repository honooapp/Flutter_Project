import 'package:flutter/material.dart';
import 'package:honoo/IsolaDelleStorie/Controller/ExerciseController.dart';
import 'package:honoo/Pages/HomePage.dart';
import 'package:honoo/Pages/PlaceholderPage.dart';
import 'package:sizer/sizer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    ExerciseController().init();

    return Sizer(
      builder: (context, orientation, deviceType) {
        return const SafeArea(
          child: MaterialApp(
                  title: 'honoo',
                  home: PlaceholderPage(),
                ),
        );
      },
    );
  }
}