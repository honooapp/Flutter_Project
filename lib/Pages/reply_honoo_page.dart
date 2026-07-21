import 'package:flutter/material.dart';
import 'package:honoo/Services/honoo_service.dart';
import 'package:honoo/UI/honoo_builder.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:sizer/sizer.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import '../Entities/honoo.dart';
import '../Entities/conversation_link.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Controller/honoo_controller.dart';
import 'home_page.dart';

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
  bool _sentOnce = false;

  void _onHonooChanged(String text, String? imageUrl) {
    setState(() {
      _text = text;
      _imageUrl = imageUrl;
    });
  }

  Future<void> _sendReply() async {
    if (_sentOnce) {
      if (!mounted) return;
      await showHonooMessageDialog(
        context,
        message: 'Risposta già inviata',
        duration: const Duration(milliseconds: 1400),
      );
      return;
    }
    if (_text.trim().isEmpty) return;

    setState(() => _isSending = true);

    final now = DateTime.now().toIso8601String();

    final String replyTarget =
        widget.originalHonoo.dbId ?? widget.originalHonoo.id.toString();
    final link = ConversationLink.fromParent(
      parentId: replyTarget,
      parentConversationId: widget.originalHonoo.conversationId,
      recipientId: widget.originalHonoo.userId,
    );
    final newHonoo = Honoo(
        0,
        _text,
        _imageUrl ?? '',
        now,
        now,
        SupabaseProvider.client.auth.currentUser!.id,
        HonooType.answer,
        link.replyTo,
        link.recipientId)
      ..conversationId = link.conversationId;

    try {
      // Assicura che il root sia nello Scrigno se arriviamo dalla Luna
      if (widget.originalHonoo.type == HonooType.moon) {
        try {
          await HonooController()
              .saveToChest(widget.originalHonoo.copyWith(isFromMoonSaved: true));
        } catch (_) {}
      }

      await HonooService.publishHonoo(newHonoo);

      if (!mounted) return;

      _sentOnce = true;
      await showHonooMessageDialog(
        context,
        message:
            "L'honoo adesso è nel tuo Scrigno,\n e,\n soprattutto,\nnello Scrigno di qualcun altro.",
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
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
            const SizedBox(
              height: 52,
              child: Center(child: HonooAppTitle()),
            ),
            Expanded(
              child: HonooBuilder(
                onHonooChanged: _onHonooChanged,
                initialText: null,
                textHint: widget.initialHintText,
                imageHint: widget.initialImageHint,
              ),
            ),
            SizedBox(height: 2.h),
            ResponsiveFooterBar(
              useSafeArea: true,
              bottomPadding: 8,
              desiredGap: 28,
              minGap: 16,
              height: 44,
              actions: [
                ResponsiveFooterAction(
                  asset: "assets/icons/honoo_logo.svg",
                  semanticsLabel: 'Indietro',
                  size: 44,
                  splashRadius: 28,
                  tooltip: 'Indietro',
                  onPressed: () => Navigator.pop(context, false),
                ),
                ResponsiveFooterAction(
                  asset: "assets/icons/reply.svg",
                  semanticsLabel: 'Invia risposta',
                  size: 44,
                  splashRadius: 28,
                  tooltip: 'Invia risposta',
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  onPressed: _isSending ? null : _sendReply,
                ),
              ],
            ),
            if (_isSending)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LoadingSpinner(),
              ),
          ],
        ),
      ),
    );
  }
}
