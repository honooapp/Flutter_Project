// AuthGate.dart (per supabase_flutter 1.x)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:honoo/Pages/PlaceholderPage.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'EmailLoginPage.dart';
import 'HomePage.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSub;
  bool _navigated = false;

  Future<Session?> _resolveSession() async {
    // piccolo respiro per dare tempo all'idratazione da localStorage
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return Supabase.instance.client.auth.currentSession; // 1.x
  }

  @override
  void initState() {
    super.initState();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (!mounted || _navigated) return;
      final session = state.session;

      if (session != null) {
        _navigated = true;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        _navigated = true;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PlaceholderPage()),
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
    return FutureBuilder<Session?>(
      future:
          _resolveSession(), // la tua funzione che fa un piccolo delay e poi legge currentSession
      builder: (context, snap) {
        // ⛳ 1) Finché la Future NON è terminata → spinner
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: LoadingSpinner()),
          );
        }

        // ⛳ 2) La Future è terminata → sessione presente?
        final session = snap.data; // può essere null
        if (session != null) {
          return const HomePage(); // utente loggato
        } else {
          return const PlaceholderPage(); // utente NON loggato
        }
      },
    );
  }
}
