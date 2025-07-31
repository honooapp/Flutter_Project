import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Entites/Honoo.dart';
import '../Services/HonooService.dart';
import 'package:honoo/Pages/ChestPage.dart';

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
        // ✅ Salva l’honoo solo se esiste del contenuto pending
        if (widget.pendingHonooText != null && widget.pendingImageUrl != null) {
          final honoo = Honoo(
            0,
            widget.pendingHonooText!,
            widget.pendingImageUrl!,
            DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
            user.id,
            HonooType.personal, // Scrigno
            null,
            null,
          );

          await HonooService.publishHonoo(honoo);
        }

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ChestPage()),
                (route) => false,
          );
        }
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
            Text('Abbiamo inviato un codice a: ${widget.email}'),
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
