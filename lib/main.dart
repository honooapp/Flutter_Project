import 'package:flutter/material.dart';
import 'package:honoo/IsolaDelleStorie/Controller/ExerciseController.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Pages/AuthGate.dart';
import 'Pages/ChestPage.dart';
import 'Utility/HonooColors.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mulardcrjecwmohlheuz.supabase.co',       // 🔁 Sostituisci con il tuo URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11bGFyZGNyamVjd21vaGxoZXV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MDgxNDYsImV4cCI6MjA2OTM4NDE0Nn0.wt0CJD8XHkGoX2qLlmQgwG6RHLUfxx6JKO9EMnpTAsc', // 🔁 Chiave anonima

  );

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
        return SafeArea(
          child: MaterialApp(
                  title: 'honoo',
                  theme: ThemeData(
                    tooltipTheme: TooltipThemeData(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [HonooColor.wave1, HonooColor.primary],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(color: Colors.white),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  home: const AuthGate(),
          // 🔑 routes nominate (qui puoi aggiungerne altre in futuro)
          routes: {
            '/chest': (context) => const ChestPage(),
          },
          ),
        );
      },
    );
  }
}
