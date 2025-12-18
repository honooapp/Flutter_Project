// email_login_page.dart
import 'package:flutter/material.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Widgets/honoo_scaffold.dart';
import '../Widgets/luna_fissa.dart';
import 'email_verify_page.dart';

class EmailLoginPage extends StatefulWidget {
  final String? pendingHonooText;
  final String? pendingImageUrl;
  final Map<String, dynamic>? pendingHinooDraft;

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

    if (email.isEmpty) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Inserisci prima la tua email',
      );
      return;
    }

    try {
      await SupabaseProvider.client.auth.signInWithOtp(
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
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      labelText: 'Email',
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
      key: const Key('email_send_code_btn'),
      onPressed: _isLoading ? null : _sendOtp,
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
        _isLoading ? 'Invio in corso…' : 'Invia codice',
        style: GoogleFonts.libreFranklin(
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );

    final w = MediaQuery.of(context).size.width;
    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;

    const double margin = 8.0;

    final iconSize = LunaFissa.iconSizeForWidth(w);

    final bottomLeftBackButton = Positioned(
      bottom: bottomSafe + margin,
      left: margin,
      child: Material(
        color: Colors.transparent,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(
            width: iconSize * 1.2,
            height: iconSize * 1.2,
          ),
          icon: SvgPicture.asset(
            "assets/icons/arrow_left.svg",
            width: iconSize * 0.6,
            height: iconSize * 0.6,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              HonooColor.onBackground,
              BlendMode.srcIn,
            ),
          ),
          tooltip: 'torna indietro',
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ),
    );

    final scrollContent = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),
              Text(
                'Accedi con la tua email',
                style: GoogleFonts.arvo(
                  color: HonooColor.onBackground,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Ti invieremo un codice di verifica.\nInserisci la tua email\ne premi “Invia codice”.',
                style: GoogleFonts.lora(
                  color: HonooColor.onBackground.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.lora(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                cursorWidth: 3,
                cursorRadius: const Radius.circular(0),
                decoration: inputDecoration,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(
                      child: LoadingSpinner(color: Colors.white),
                    )
                  : button,
            ],
          ),
        ),
      ),
    );

    final content = Stack(
      children: [
        scrollContent,
        bottomLeftBackButton,
      ],
    );

    return HonooScaffold(body: content);
  }
}
