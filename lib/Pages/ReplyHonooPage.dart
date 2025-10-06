import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Services/HonooService.dart';
import 'package:honoo/UI/HonooBuilder.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Entities/Honoo.dart';

class ReplyHonooPage extends StatefulWidget {
  final Honoo originalHonoo;

  const ReplyHonooPage({super.key, required this.originalHonoo});

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
        Supabase.instance.client.auth.currentUser!.id,
        HonooType.answer, // destination: reply
        widget.originalHonoo.id.toString(), // replyTo
        widget.originalHonoo.recipientTag);

    try {
      await HonooService.publishHonoo(newHonoo);

      if (context.mounted) {
        showHonooToast(
          context,
          message: 'La tua risposta è partita.',
        );
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
      }
    } catch (e) {
      print('Errore invio reply: $e');
      if (context.mounted) {
        showHonooToast(
          context,
          message: 'Errore. Riprova più tardi.',
        );
      }
    } finally {
      setState(() => _isSending = false);
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
