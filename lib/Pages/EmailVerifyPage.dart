import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Entities/Hinoo.dart';
import '../Entities/Honoo.dart';
import '../Services/HinooService.dart';
import '../Services/HonooService.dart';
import '../Widgets/loading_spinner.dart';
import 'ChestPage.dart';

class EmailVerifyPage extends StatefulWidget {
  final String email;
  final String? pendingHonooText;
  final String? pendingImageUrl;
  final Map<String, dynamic>? pendingHinooDraft;

  const EmailVerifyPage({
    super.key,
    required this.email,
    this.pendingHonooText,
    this.pendingImageUrl,
    this.pendingHinooDraft,
  });

  @override
  State<EmailVerifyPage> createState() => _EmailVerifyPageState();
}

class _EmailVerifyPageState extends State<EmailVerifyPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    // 🎯 Ascolta magic link / cambi di stato
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // ✅ Login completato (magic link o OTP)
        // Se c'è un honoo in sospeso, salvalo
        if (widget.pendingHonooText != null && widget.pendingImageUrl != null) {
          final honoo = Honoo(
            0,
            widget.pendingHonooText!,
            widget.pendingImageUrl!,
            DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
            session.user.id,
            HonooType.personal, // Scrigno
            null,
            null,
          );

          // Debug facoltativo:
          // print('🟨 Honoo.toMap: ${honoo.toMap()}');
          await HonooService.publishHonoo(honoo);
        }

        // Se c'è un hinoo in sospeso, salvalo nello scrigno (type personal)
        if (widget.pendingHinooDraft != null) {
          try {
            final map = widget.pendingHinooDraft!;
            final draft = HinooDraft.fromJson(map);
            await HinooService.publishHinoo(draft);
          } catch (e) {
            // Non bloccare il flusso di login; mostra feedback opzionale
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Errore salvataggio Hinoo: $e')),
              );
            }
          }
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ChestPage()),
              (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    setState(() => _isVerifying = true);
    final code = _codeController.text.trim();

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.email,
        email: widget.email,
        token: code,
      );

      // Se la verifica va a buon fine, onAuthStateChange scatterà.
      if (response.user == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Codice non valido.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore verifica: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inserisci il codice')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Ti abbiamo inviato una mail.\n'
                  'Inserisci il codice.\n',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Codice di verifica'),
            ),
            const SizedBox(height: 20),
            _isVerifying
                ? const LoadingSpinner()
                : ElevatedButton(
              onPressed: _verifyCode,
              child: const Text('Verifica'),
            ),
          ],
        ),
      ),
    );
  }
}
