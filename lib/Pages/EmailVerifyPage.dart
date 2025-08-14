import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Entites/Honoo.dart';
import '../Services/HonooService.dart';
import 'ChestPage.dart';

class EmailVerifyPage extends StatefulWidget {
  final String email;
  final String? pendingHonooText;
  final String? pendingImageUrl;

  const EmailVerifyPage({
    super.key,
    required this.email,
    this.pendingHonooText,
    this.pendingImageUrl,
  });

  @override
  State<EmailVerifyPage> createState() => _EmailVerifyPageState();
}

class _EmailVerifyPageState extends State<EmailVerifyPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();

    // 🎯 Ascolta magic link
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        print('✅ Login completato con magic link');

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

          print('🟨 Honoo.toMap: ${honoo.toMap()}');
          await HonooService.publishHonoo(honoo);
        }

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ChestPage()),
                (route) => false,
          );
        }
      }
    });
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

      final user = response.user;

      if (user != null) {
        print('✅ Codice OTP verificato');
        // Non serve navigare: se il login riesce, onAuthStateChange lo intercetta
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Codice non valido.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      setState(() => _isVerifying = false);
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
            Text(
              'Ti abbiamo inviato una mail.\n'
                  'Se è la prima volta, inserisci il codice.\n'
                  'Se sei già registrato, clicca sul link.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Codice di verifica'),
            ),
            const SizedBox(height: 20),
            _isVerifying
                ? const CircularProgressIndicator()
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
