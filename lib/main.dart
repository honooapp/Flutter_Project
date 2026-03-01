import 'package:flutter/material.dart';
import 'dart:async';
import 'package:honoo/IsolaDelleStorie/Controller/exercise_controller.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env/env.dart';

import 'Pages/auth_gate.dart';
import 'Pages/chest_page.dart';
import 'Utility/honoo_colors.dart';
import 'Widgets/global_invite_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final supabaseUrl = readEnv('SUPABASE_URL');
    final supabaseAnon = readEnv('SUPABASE_ANON_KEY');
    if (supabaseUrl.isEmpty || supabaseAnon.isEmpty) {
      throw 'SUPABASE_URL/SUPABASE_ANON_KEY non configurati';
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnon,
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
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Guard globale: se la sessione diventa nulla (refresh fallito/expired), torna al Placeholder.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (!mounted) return;
      if (session == null) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

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
