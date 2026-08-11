import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Entities/campanelli_view_data.dart';
import '../UI/hinoo_typography.dart';
import '../Utility/honoo_colors.dart';
import 'text_box_download_button.dart';

class CampanelloCard extends StatelessWidget {
  const CampanelloCard({
    super.key,
    required this.data,
    required this.width,
    required this.height,
    this.onRequestTap,
    this.onEditTap,
  });

  final CampanelloPageData data;
  final double width;
  final double height;
  final VoidCallback? onRequestTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final double verticalPadding = HinooTypography.verticalPadding(width);
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

    final Widget savedText = Padding(
      padding: EdgeInsets.fromLTRB(
        HinooTypography.horizontalPadding,
        HinooTypography.editorTextTopPadding(width),
        HinooTypography.horizontalPadding,
        HinooTypography.editorTextBottomPadding,
      ),
      child: Align(
        key: const ValueKey('campanello-saved-text-position'),
        alignment: Alignment.topCenter,
        child: _buildText(textStyle),
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: data.campanello!.backgroundImage, fit: BoxFit.cover),
          savedText,
          if (onEditTap != null)
            Positioned(
              top: 6,
              right: 6,
              child: TextBoxDownloadButton(
                key: const ValueKey('edit-own-campanello'),
                onPressed: onEditTap!,
                tooltip: 'Modifica campanello',
                asset: 'assets/icons/immagine.svg',
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
      return Text(raw, style: textStyle, textAlign: TextAlign.center);
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
