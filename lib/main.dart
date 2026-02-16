import 'package:flutter/material.dart';
import 'package:honoo/IsolaDelleStorie/Controller/exercise_controller.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Pages/auth_gate.dart';
import 'Pages/chest_page.dart';
import 'Utility/honoo_colors.dart';
import 'Widgets/global_invite_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: 'https://mulardcrjecwmohlheuz.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11bGFyZGNyamVjd21vaGxoZXV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MDgxNDYsImV4cCI6MjA2OTM4NDE0Nn0.wt0CJD8XHkGoX2qLlmQgwG6RHLUfxx6JKO9EMnpTAsc',
    ).timeout(const Duration(seconds: 5));
    try {
      await Supabase.instance.client.auth
          .refreshSession()
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
    ExerciseController().init();
    runApp(const MyApp());
  } catch (e) {
    runApp(_BootErrorApp(message: 'Errore inizializzazione: $e'));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        final Widget app = MaterialApp(
          navigatorKey: _navigatorKey,
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
          routes: {
            '/chest': (context) => const ChestPage(),
          },
        );
        return SafeArea(
          child: GlobalInviteListener(
            navigatorKey: _navigatorKey,
            enabled: true,
            child: app,
          ),
        );
      },
    );
  }
}

class _BootErrorApp extends StatelessWidget {
  const _BootErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
