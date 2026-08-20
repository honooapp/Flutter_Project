import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Entities/campanelli_view_data.dart';
import '../UI/hinoo_typography.dart';
import '../Utility/honoo_colors.dart';
import '../Utility/inline_text_formatting.dart';
import 'cover_transform_image.dart';
import 'text_box_download_button.dart';

class CampanelloCard extends StatelessWidget {
  const CampanelloCard({
    super.key,
    required this.data,
    required this.width,
    required this.height,
    this.onRequestTap,
    this.onEditTap,
    this.onEditImageTap,
    this.onEditTextTap,
  });

  final CampanelloPageData data;
  final double width;
  final double height;
  final VoidCallback? onRequestTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onEditImageTap;
  final VoidCallback? onEditTextTap;

  @override
  Widget build(BuildContext context) {
    final double verticalPadding = HinooTypography.verticalPadding(width);
    final double textCanvasHeight = math.min(
      height,
      width / HinooTypography.aspectRatio,
    );
    final TextStyle textStyle = GoogleFonts.lora(
      fontSize: 18,
      height: HinooTypography.lineHeight,
      color: HonooColor.onBackground,
      fontWeight: FontWeight.w400,
    );

    final Widget introText = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: HinooTypography.horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Center(child: _buildText(textStyle)),
    );

    if (data.isIntro) {
      return Center(
        child: SizedBox(width: width, height: height, child: introText),
      );
    }

    final Widget savedText = Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        key: const ValueKey('campanello-text-canvas'),
        width: width,
        height: textCanvasHeight,
        child: Padding(
          padding: HinooTypography.campanelloTextViewportPadding(width),
          child: Align(
            key: const ValueKey('campanello-saved-text-position'),
            alignment: Alignment.topCenter,
            child: _buildText(textStyle),
          ),
        ),
      ),
    );

    final rawTransform = data.campanello!.bgTransform;
    Matrix4? transform;
    if (rawTransform != null && rawTransform.length == 16) {
      final values = List<double>.from(rawTransform);
      values[12] *= width / HinooTypography.baselineCanvasWidth;
      values[13] *= height / HinooTypography.baselineCanvasHeight;
      transform = Matrix4.fromList(values);
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (transform != null)
            CoverTransformImage.transformed(
              image: data.campanello!.backgroundImage,
              transform: transform,
            )
          else
            Image(image: data.campanello!.backgroundImage, fit: BoxFit.cover),
          savedText,
          if (onEditTap != null || onEditImageTap != null)
            Positioned(
              top: 6,
              left: 6,
              child: TextBoxDownloadButton(
                key: const ValueKey('edit-own-campanello-image'),
                onPressed: onEditImageTap ?? onEditTap!,
                tooltip: 'Modifica immagine',
                asset: 'assets/icons/immagine.svg',
              ),
            ),
          if (onEditTextTap != null || onEditTap != null)
            Positioned(
              top: 6,
              right: 6,
              child: TextBoxDownloadButton(
                key: const ValueKey('edit-own-campanello-text'),
                onPressed: onEditTextTap ?? onEditTap!,
                tooltip: 'Modifica testo',
                asset: 'assets/icons/modifica testo.svg',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildText(TextStyle textStyle) {
    final String raw = data.text;
    final idx = raw.toLowerCase().lastIndexOf('clicca qui');
    if (idx < 0 || onRequestTap == null) {
      return FormattedText(
        raw,
        style: textStyle,
        textAlign: TextAlign.center,
        softWrap: false,
      );
    }

    final String before = raw.substring(0, idx);
    final String link = raw.substring(idx, idx + 'clicca qui'.length);
    final String after = raw.substring(idx + 'clicca qui'.length);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: InkWell(
              onTap: onRequestTap,
              child: Text(
                link,
                style: textStyle.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: textStyle.color,
                  decorationThickness: 2.5,
                ),
              ),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
