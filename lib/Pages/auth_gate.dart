// auth_gate.dart (per supabase_flutter 1.x)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:honoo/Pages/placeholder_page.dart';
import 'home_page.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _authSub = SupabaseProvider.client.auth.onAuthStateChange.listen((state) {
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
    final Session? session = SupabaseProvider.client.auth.currentSession;
    return session != null ? const HomePage() : const PlaceholderPage();
  }
}
