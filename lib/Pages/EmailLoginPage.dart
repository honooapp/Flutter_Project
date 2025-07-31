// EmailLoginPage.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'EmailVerifyPage.dart';

class EmailLoginPage extends StatefulWidget {
  final String? pendingHonooText;
  final String? pendingImageUrl;

  const EmailLoginPage({super.key, this.pendingHonooText, this.pendingImageUrl});

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
      await Supabase.instance.client.auth.signInWithOtp(email: email);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerifyPage(
              email: email,
              pendingHonooText: widget.pendingHonooText,
              pendingImageUrl: widget.pendingImageUrl,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _sendOtp,
              child: const Text('Invia codice'),
            ),
          ],
        ),
      ),
    );
  }
}
