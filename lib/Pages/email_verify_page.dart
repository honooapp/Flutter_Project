import 'dart:async';
import 'package:flutter/material.dart';
import '../Entities/hinoo.dart';
import '../Entities/honoo.dart';
import '../Services/hinoo_service.dart';
import '../Services/honoo_service.dart';
import '../Widgets/honoo_dialogs.dart';
import '../Widgets/loading_spinner.dart';
import '../Widgets/honoo_scaffold.dart';
import 'chest_page.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';

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
    _authSub =
        SupabaseProvider.client.auth.onAuthStateChange.listen((data) async {
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
              showHonooToast(
                context,
                message: 'Errore salvataggio hinoo: $e',
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
      final response = await SupabaseProvider.client.auth.verifyOTP(
        type: OtpType.email,
        email: widget.email,
        token: code,
      );

      // Se la verifica va a buon fine, onAuthStateChange scatterà.
      if (response.user == null && mounted) {
        showHonooToast(
          context,
          message: 'Codice non valido.',
        );
      }
    } catch (e) {
      if (mounted) {
        showHonooToast(
          context,
          message: 'Errore verifica: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      labelText: 'Codice di verifica',
      labelStyle: GoogleFonts.lora(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white60),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );

    final button = ElevatedButton(
      onPressed: _isVerifying ? null : _verifyCode,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        disabledBackgroundColor: Colors.white10,
        disabledForegroundColor: Colors.white38,
      ),
      child: Text(
        _isVerifying ? 'Verifica in corso…' : 'Verifica',
        style: GoogleFonts.libreFranklin(
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );

    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Inserisci il codice',
                style: GoogleFonts.libreFranklin(
                  color: HonooColor.onBackground,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Controlla la posta in arrivo all’indirizzo ${widget.email}. '
                'Inserisci qui il codice a sei cifre per completare l’accesso.',
                style: GoogleFonts.arvo(
                  color: HonooColor.onBackground.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.lora(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                cursorWidth: 3,
                cursorRadius: const Radius.circular(0),
                decoration: inputDecoration,
              ),
              const SizedBox(height: 24),
              _isVerifying
                  ? const Center(
                      child: LoadingSpinner(color: Colors.white),
                    )
                  : button,
            ],
          ),
        ),
      ),
    );

    return HonooScaffold(body: content);
  }
}
