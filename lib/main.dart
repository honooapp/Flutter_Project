import 'package:flutter/material.dart';
import 'package:honoo/IsolaDelleStorie/Controller/ExerciseController.dart';
import 'package:honoo/IsolaDelleStorie/Utility/NotionAPI.dart';
import 'package:honoo/Pages/HomePage.dart';
import 'package:honoo/Pages/PlaceholderPage.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() {
  //final notionApi = dotenv.env['NOTION_API_TOKEN'] ?? '';
  //final databaseId = dotenv.env['NOTION_DATABASE_ID'] ?? '';
  final notionApi = 'secret_xUNRbof4rEOCTaBb2Q5N2E0A5hmwXz8D8ivevH9ZULv';
  final databaseId = '666abc4e50e6478d980a9a8086943075';
  //NotionApi(notionApi, databaseId);
  //NotionApi.instance?.getAllExercises();
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