import 'package:flutter/material.dart';
import 'package:honoo/IsolaDelleStorie/Controller/ExerciseController.dart';
import 'package:honoo/IsolaDelleStorie/Utility/NotionAPI.dart';
import 'package:honoo/Pages/HomePage.dart';
import 'package:honoo/Pages/PlaceholderPage.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Pages/AuthGate.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mulardcrjecwmohlheuz.supabase.co',       // 🔁 Sostituisci con il tuo URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11bGFyZGNyamVjd21vaGxoZXV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MDgxNDYsImV4cCI6MjA2OTM4NDE0Nn0.wt0CJD8XHkGoX2qLlmQgwG6RHLUfxx6JKO9EMnpTAsc', // 🔁 Chiave anonima

  );

  // Notion config (puoi lasciare hardcoded o usare dotenv se preferisci)
  final notionApi = 'secret_xUNRbof4rEOCTaBb2Q5N2E0A5hmwXz8D8ivevH9ZULv';
  final databaseId = '666abc4e50e6478d980a9a8086943075';

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
                  home: AuthGate(),
                ),
        );
      },
    );
  }
}