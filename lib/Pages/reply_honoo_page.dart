import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Services/honoo_service.dart';
import 'package:honoo/UI/honoo_builder.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:sizer/sizer.dart';
import '../Entities/honoo.dart';
import 'package:honoo/Services/supabase_provider.dart';

class ReplyHonooPage extends StatefulWidget {
  final Honoo originalHonoo;

  final String initialHintText;
  final String initialImageHint;

  const ReplyHonooPage({
    super.key,
    required this.originalHonoo,
    this.initialHintText = 'Scrivi la tua risposta...',
    this.initialImageHint = 'Aggiungi un’immagine (opzionale)',
  });

  @override
  State<ReplyHonooPage> createState() => _ReplyHonooPageState();
}

class _ReplyHonooPageState extends State<ReplyHonooPage> {
  String _text = '';
  String? _imageUrl;

  bool _isSending = false;

  void _onHonooChanged(String text, String? imageUrl) {
    setState(() {
      _text = text;
      _imageUrl = imageUrl;
    });
  }

  Future<void> _sendReply() async {
    if (_text.trim().isEmpty) return;

    setState(() => _isSending = true);

    final now = DateTime.now().toIso8601String();

    final newHonoo = Honoo(
        0, // ID locale, ignorato da Supabase
        _text, // text
        _imageUrl ?? '', // image
        now, // created_at
        now, // updated_at
        SupabaseProvider.client.auth.currentUser!.id,
        HonooType.answer, // destination: reply
        widget.originalHonoo.id.toString(), // replyTo
        widget.originalHonoo.recipientTag);

    try {
      await HonooService.publishHonoo(newHonoo);

      if (!mounted) return;

      showHonooToast(
        context,
        message: 'La tua risposta è partita.',
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Errore invio reply: $e');
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Errore. Riprova più tardi.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 10.h,
              child: Center(
                child: Text(
                  "Rispondi a un honoo",
                  style: GoogleFonts.libreFranklin(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: HonooColor.secondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: HonooBuilder(
                onHonooChanged: _onHonooChanged,
                initialText: widget.initialHintText,
                imageHint: widget.initialImageHint,
              ),
            ),
            if (!_isSending)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: ElevatedButton(
                  onPressed: _sendReply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HonooColor.secondary,
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.5.h),
                  ),
                  child: Text(
                    "Invia risposta",
                    style: GoogleFonts.libreFranklin(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HonooColor.background,
                    ),
                  ),
                ),
              ),
            if (_isSending)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LoadingSpinner(),
              ),
          ],
        ),
      ),
    );
  }
}
