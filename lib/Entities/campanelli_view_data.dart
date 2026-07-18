import 'package:flutter/widgets.dart';

class CampanelloData {
  const CampanelloData({
    required this.id,
    required this.campanelloHinooId,
    required this.ownerId,
    required this.backgroundImage,
    required this.text,
    required this.linkedHouseId,
  });

  final String id;
  final String? campanelloHinooId;
  final String? ownerId;
  final ImageProvider backgroundImage;
  final String text;
  final String linkedHouseId;
}

class CasaData {
  const CasaData({
    required this.id,
    required this.backgroundImage,
    this.bgTransform,
    required this.bgScale,
    required this.bgOffsetX,
    required this.bgOffsetY,
  });

  final String id;
  final ImageProvider backgroundImage;
  final List<double>? bgTransform;
  final double bgScale;
  final double bgOffsetX;
  final double bgOffsetY;
}

class CampanelloPageData {
  const CampanelloPageData._({
    required this.isIntro,
    required this.text,
    this.campanello,
  });

  factory CampanelloPageData.intro(String text) {
    return CampanelloPageData._(isIntro: true, text: text);
  }

  factory CampanelloPageData.campanello(CampanelloData campanello) {
    return CampanelloPageData._(
      isIntro: false,
      text: campanello.text,
      campanello: campanello,
    );
  }

  final bool isIntro;
  final String text;
  final CampanelloData? campanello;
}
