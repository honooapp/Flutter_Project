import 'dart:typed_data';
import 'package:flutter/material.dart';

class AnteprimaPNG extends StatelessWidget {
  const AnteprimaPNG({
    super.key,
    required this.previewBytes,
    required this.filenameHint,
    required this.onSavePng,
    required this.onClose,
  });

  final Uint8List? previewBytes;
  final String? filenameHint;
  final Future<void> Function() onSavePng;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(filenameHint ?? 'Anteprima'),
      content: SizedBox(
        width: 360,
        child: previewBytes == null
            ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(child: Image.memory(previewBytes!)),
      ),
      actions: [
        TextButton(onPressed: onClose, child: const Text('Chiudi')),
        ElevatedButton(
          onPressed: () async {
            await onSavePng();
          },
          child: const Text('Salva PNG'),
        ),
      ],
    );
  }
}

