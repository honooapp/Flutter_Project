import 'package:flutter/material.dart';
import 'package:honoo/Utility/responsive_layout.dart';

/// ThreadLayoutScaffold
///
/// Layout wrapper riutilizzabile che replica l'assetto di Campanelli:
/// - Header fisso (52px)
/// - Area centrale full-width e altezza calcolata (availableH)
/// - Footer responsivo senza restringimenti
///
/// Nessun maxWidth o ConstrainedBox viene applicato all'area centrale.
class ThreadLayoutScaffold extends StatelessWidget {
  const ThreadLayoutScaffold({
    super.key,
    required this.backgroundColor,
    required this.header,
    required this.bodyBuilder,
    required this.footerBuilder,
    this.overlayBuilder,
    this.bodyTopInsetBuilder,
  });

  final Color backgroundColor;
  final Widget header;

  /// Costruisce il corpo centrale con dimensioni già calcolate:
  /// - viewW: larghezza viewport
  /// - availableH: altezza area centrale
  /// - mode: modalità responsive corrente
  final Widget Function(
    BuildContext context,
    double viewW,
    double availableH,
    ResponsiveLayoutMode mode,
  ) bodyBuilder;

  /// Costruisce il footer responsivo con spaziature già calcolate.
  final Widget Function(
    BuildContext context,
    ResponsiveLayoutMode mode,
    double footerIconSize,
    double footerGap,
    double footerTopSpacing,
    double footerBottomSpacing,
  ) footerBuilder;

  /// Overlay opzionale (es. LunaFissa) posizionato sopra header/body/footer
  final Widget Function(BuildContext context, ResponsiveLayoutMode mode)?
      overlayBuilder;

  /// Spazio da sottrarre alla parte alta del corpo per overlay persistenti.
  /// Il valore viene applicato prima di comunicare [availableH] al body.
  final double Function(
    BuildContext context,
    ResponsiveLayoutMode mode,
  )? bodyTopInsetBuilder;

  static const double headerHeight = 52;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewW = constraints.maxWidth;
          final double viewH = constraints.maxHeight;
          final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
          final ResponsiveLayoutMode mode =
              ResponsiveLayout.modeForWidth(viewW);

          final double footerIconSize =
              ResponsiveLayout.footerIconSizeForMode(mode);
          final double footerGap = ResponsiveLayout.footerGapForMode(mode);
          final double footerBottomPadding =
              ResponsiveLayout.footerBottomPaddingForMode(mode);
          final double footerSpacing = footerBottomPadding + safeBottom;
          final double footerTopSpacing = footerSpacing / 2;
          final double footerBottomSpacing = footerSpacing - footerTopSpacing;
          const double headerH = headerHeight;
          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double bodySlotH =
              (viewH - headerH - footerReserved).clamp(0.0, double.infinity);
          final double requestedTopInset =
              bodyTopInsetBuilder?.call(context, mode) ?? 0;
          final double bodyTopInset = requestedTopInset.clamp(0.0, bodySlotH);
          final double availableH =
              (bodySlotH - bodyTopInset).clamp(0.0, double.infinity);

          final column = Column(
            children: [
              SizedBox(height: headerH, child: Center(child: header)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: bodyTopInset),
                  child: SizedBox(
                    width: viewW,
                    height: availableH,
                    child: bodyBuilder(context, viewW, availableH, mode),
                  ),
                ),
              ),
              SizedBox(height: footerTopSpacing),
              footerBuilder(context, mode, footerIconSize, footerGap,
                  footerTopSpacing, footerBottomSpacing),
            ],
          );
          if (overlayBuilder == null) return column;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              column,
              overlayBuilder!(context, mode),
            ],
          );
        },
      ),
    );
  }
}
