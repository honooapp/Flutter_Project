import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dice_result.dart';

/// Widget che gestisce esclusivamente:
/// - animazioni del dado
/// - blocco click
/// - timing (fade + visibilità risultato)
///
/// NON contiene logica di dispatch o random.
class DiceAnimator extends StatefulWidget {
  const DiceAnimator({
    super.key,
    required this.options,
    required this.onPick,
    required this.diceChild,
    this.fadeDuration = const Duration(milliseconds: 1500),
    this.resultVisibleDuration = const Duration(seconds: 3),
    this.resultTextStyle,
    this.resultImageFit = BoxFit.contain,
  });

  /// Opzioni già pronte.
  /// Se vuote → l’animazione non parte.
  final List<DiceResult> options;

  /// Funzione che seleziona un risultato dalle opzioni
  final DiceResult Function(List<DiceResult> options) onPick;

  /// Widget grafico del dado (SVG, Icon, Image, ecc.)
  final Widget diceChild;

  final Duration fadeDuration;
  final Duration resultVisibleDuration;

  /// Stile del testo risultato (es. Arvo bold)
  final TextStyle? resultTextStyle;

  final BoxFit resultImageFit;

  @override
  State<DiceAnimator> createState() => _DiceAnimatorState();
}

enum _DicePhase {
  idle,
  fadingOutDice,
  showingResult,
  fadingOutResult,
  fadingInDice,
}

class _DiceAnimatorState extends State<DiceAnimator> {
  _DicePhase _phase = _DicePhase.idle;
  DiceResult? _currentResult;

  bool get _isLocked => _phase != _DicePhase.idle;

  Future<void> _runSequence() async {
    if (widget.options.isEmpty) return;
    if (_isLocked) return;

    setState(() => _phase = _DicePhase.fadingOutDice);

    await Future.delayed(widget.fadeDuration);
    if (!mounted) return;

    final picked = widget.onPick(widget.options);
    setState(() {
      _currentResult = picked;
      _phase = _DicePhase.showingResult;
    });

    await Future.delayed(widget.fadeDuration);
    if (!mounted) return;

    await Future.delayed(widget.resultVisibleDuration);
    if (!mounted) return;

    setState(() => _phase = _DicePhase.fadingOutResult);
    await Future.delayed(widget.fadeDuration);
    if (!mounted) return;

    setState(() {
      _currentResult = null;
      _phase = _DicePhase.fadingInDice;
    });
    await Future.delayed(widget.fadeDuration);
    if (!mounted) return;

    setState(() => _phase = _DicePhase.idle);
  }

  @override
  Widget build(BuildContext context) {
    double diceOpacity;
    switch (_phase) {
      case _DicePhase.idle:
      case _DicePhase.fadingInDice:
        diceOpacity = 1.0;
        break;
      default:
        diceOpacity = 0.0;
    }

    double resultOpacity;
    switch (_phase) {
      case _DicePhase.showingResult:
        resultOpacity = 1.0;
        break;
      default:
        resultOpacity = 0.0;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // RISULTATO
        IgnorePointer(
          ignoring: true,
          child: AnimatedOpacity(
            opacity: resultOpacity,
            duration: widget.fadeDuration,
            child: _ResultView(
              result: _currentResult,
              textStyle: widget.resultTextStyle ??
                  Theme.of(context).textTheme.headlineSmall,
              imageFit: widget.resultImageFit,
            ),
          ),
        ),

        // DADO
        GestureDetector(
          onTap: _runSequence,
          behavior: HitTestBehavior.opaque,
          child: AbsorbPointer(
            absorbing: _isLocked,
            child: AnimatedOpacity(
              opacity: diceOpacity,
              duration: widget.fadeDuration,
              child: widget.diceChild,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.textStyle,
    required this.imageFit,
  });

  final DiceResult? result;
  final TextStyle? textStyle;
  final BoxFit imageFit;

  @override
  Widget build(BuildContext context) {
    final DiceResult? r0 = result;
    if (r0 == null) return const SizedBox.shrink();

    // TESTO
    if (r0 is TextDiceResult) {
      return Text(
        r0.text,
        textAlign: TextAlign.center,
        style: textStyle,
      );
    }

    // IMMAGINE (SVG)
    if (r0 is AssetImageDiceResult) {
      return SvgPicture.asset(
        r0.assetPath,
        fit: imageFit,
      );
    }

    return const SizedBox.shrink();
  }
}
