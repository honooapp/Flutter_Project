import 'package:flutter/material.dart';
import 'package:honoo/IsolaDelleStorie/Controller/exercise_controller.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Pages/auth_gate.dart';
import 'Pages/chest_page.dart';
import 'Utility/honoo_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  bool _initStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAsync());
  }

  Future<void> _bootstrapAsync() async {
    if (_initStarted) return;
    _initStarted = true;

    await Supabase.initialize(
      url: 'https://mulardcrjecwmohlheuz.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11bGFyZGNyamVjd21vaGxoZXV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MDgxNDYsImV4cCI6MjA2OTM4NDE0Nn0.wt0CJD8XHkGoX2qLlmQgwG6RHLUfxx6JKO9EMnpTAsc',
    );

    ExerciseController().init();

    if (!mounted) return;
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            home: _initialized ? const AuthGate() : const _BootPlaceholder(),
            routes: {
              '/chest': (context) => const ChestPage(),
            },
          ),
        );
      },
    );
  }
}

class _BootPlaceholder extends StatelessWidget {
  const _BootPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
