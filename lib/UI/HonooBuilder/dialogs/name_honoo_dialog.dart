import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';

class NameHonooDialog extends StatefulWidget {
  const NameHonooDialog({super.key, this.initialValue});

  final String? initialValue;

  @override
  State<NameHonooDialog> createState() => _NameHonooDialogState();
}

class _NameHonooDialogState extends State<NameHonooDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canConfirm = _controller.text.trim().isNotEmpty;

    return HonooDialogShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Come vuoi chiamare il tuo honoo?',
              style: HonooDialogStyles.title(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Se è per il mio corso, sei il numero 25 ed è il tuo primo lavoro, chiamalo 25.1. Se è il tuo secondo lavoro 25.2',
              style: HonooDialogStyles.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.lora(color: Colors.white, fontSize: 16),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Es. 25.1',
                hintStyle:
                    GoogleFonts.lora(color: Colors.white38, fontSize: 16),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canConfirm
                    ? () {
                        Navigator.of(context)
                            .pop<String>(_controller.text.trim());
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white38,
                ),
                child:
                    Text('Conferma', style: HonooDialogStyles.primaryAction()),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: Text('Annulla', style: HonooDialogStyles.tertiaryAction()),
            ),
          ],
        ),
      ),
    );
  }
}
