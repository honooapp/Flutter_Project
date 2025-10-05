// EmailLoginPage.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'EmailVerifyPage.dart';

class EmailLoginPage extends StatefulWidget {
  final String? pendingHonooText;
  final String? pendingImageUrl;
  final Map<String, dynamic>? pendingHinooDraft; // nuova: bozza Hinoo


  const EmailLoginPage({
    super.key,
    this.pendingHonooText,
    this.pendingImageUrl,
    this.pendingHinooDraft,
  });



  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,

      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerifyPage(
            email: email,
            pendingHonooText: widget.pendingHonooText,
            pendingImageUrl: widget.pendingImageUrl,
            pendingHinooDraft: widget.pendingHinooDraft,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Errore invio OTP: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accedi con la tua email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const LoadingSpinner()
                : ElevatedButton(
              key: const Key('email_send_code_btn'),
              onPressed: _sendOtp,
              child: const Text('Invia codice'),
            ),
          ],
        ),
      ),
    );
  }
}
