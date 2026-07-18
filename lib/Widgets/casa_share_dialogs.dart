import 'package:flutter/material.dart';

import '../Entities/casa_share_mode.dart';
import 'honoo_dialogs.dart';

class CasaMultiShareDialog extends StatefulWidget {
  const CasaMultiShareDialog({super.key, required this.onConfirm});

  final Future<void> Function(Set<CasaShareMode> modes) onConfirm;

  @override
  State<CasaMultiShareDialog> createState() => _CasaMultiShareDialogState();
}

class _CasaMultiShareDialogState extends State<CasaMultiShareDialog> {
  final Set<CasaShareMode> _selected = {};
  bool _saving = false;

  void _toggle(CasaShareMode mode) {
    setState(() {
      if (_selected.contains(mode)) {
        _selected.remove(mode);
      } else {
        _selected.add(mode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HonooDialogShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cosa vuoi condividere?',
              style: HonooDialogStyles.title(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...CasaShareMode.values.map(
              (mode) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _toggle(mode),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selected.contains(mode)
                          ? Colors.white
                          : Colors.transparent,
                      foregroundColor: Colors.black,
                      side: BorderSide(
                        color: _selected.contains(mode)
                            ? Colors.white
                            : Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selected.contains(mode))
                          const Icon(Icons.check, size: 18),
                        if (_selected.contains(mode)) const SizedBox(width: 8),
                        Text(
                          mode.label,
                          style: HonooDialogStyles.primaryAction(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (_saving)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null,
                  style: _primaryStyle(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Salvo...',
                        style: HonooDialogStyles.primaryAction(),
                      ),
                    ],
                  ),
                ),
              )
            else if (_selected.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    setState(() => _saving = true);
                    try {
                      await widget.onConfirm(_selected);
                      if (!mounted) return;
                      nav.pop(_selected);
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
                  style: _primaryStyle(),
                  child: Text(
                    'Condividi',
                    style: HonooDialogStyles.primaryAction(),
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: Text(
                'Annulla',
                style: HonooDialogStyles.tertiaryAction(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _primaryStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    );
  }
}

class VisitorShareChoiceDialog extends StatelessWidget {
  const VisitorShareChoiceDialog({
    super.key,
    required this.modes,
  });

  final Set<CasaShareMode> modes;

  @override
  Widget build(BuildContext context) {
    return HonooDialogShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cosa vuoi aprire?',
              style: HonooDialogStyles.title(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...modes.map(
              (mode) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(mode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      mode.label,
                      style: HonooDialogStyles.primaryAction(),
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: Text(
                'Chiudi',
                style: HonooDialogStyles.tertiaryAction(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
