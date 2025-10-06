// lib/Entities/Hinoo.dart
import 'package:flutter/foundation.dart';

enum HinooType { personal, moon, answer }

@immutable
class HinooSlide {
  final String? backgroundImage; // URL pubblico (dopo upload)
  final String text; // testo centrato
  final bool isTextWhite; // true=bianco, false=nero
  final double bgScale; // default 1.0
  final double bgOffsetX; // default 0.0
  final double bgOffsetY; // default 0.0
  final List<double>?
      bgTransform; // matrice completa 4x4 normalizzata (opzionale)

  const HinooSlide({
    required this.backgroundImage,
    required this.text,
    required this.isTextWhite,
    this.bgScale = 1.0,
    this.bgOffsetX = 0.0,
    this.bgOffsetY = 0.0,
    this.bgTransform,
  });

  HinooSlide copyWith({
    String? backgroundImage,
    String? text,
    bool? isTextWhite,
    double? bgScale,
    double? bgOffsetX,
    double? bgOffsetY,
    List<double>? bgTransform,
  }) {
    return HinooSlide(
      backgroundImage: backgroundImage ?? this.backgroundImage,
      text: text ?? this.text,
      isTextWhite: isTextWhite ?? this.isTextWhite,
      bgScale: bgScale ?? this.bgScale,
      bgOffsetX: bgOffsetX ?? this.bgOffsetX,
      bgOffsetY: bgOffsetY ?? this.bgOffsetY,
      bgTransform: bgTransform ?? this.bgTransform,
    );
  }

  Map<String, dynamic> toJson() => {
        'backgroundImage': backgroundImage,
        'text': text,
        'isTextWhite': isTextWhite,
        'bgScale': bgScale,
        'bgOffsetX': bgOffsetX,
        'bgOffsetY': bgOffsetY,
        if (bgTransform != null) 'bgTransform': bgTransform,
      };

  factory HinooSlide.fromJson(Map<String, dynamic> json) => HinooSlide(
        backgroundImage: json['backgroundImage'] as String?,
        text: (json['text'] as String?) ?? '',
        isTextWhite: (json['isTextWhite'] as bool?) ?? true,
        bgScale: (json['bgScale'] as num?)?.toDouble() ?? 1.0,
        bgOffsetX: (json['bgOffsetX'] as num?)?.toDouble() ?? 0.0,
        bgOffsetY: (json['bgOffsetY'] as num?)?.toDouble() ?? 0.0,
        bgTransform: (json['bgTransform'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
      );
}

@immutable
class HinooDraft {
  final List<HinooSlide> pages;
  final HinooType type; // personal | moon | answer
  final String? recipientTag; // opzionale
  final double?
      baseCanvasHeight; // altezza canvas al momento della creazione (per proporzioni testo)

  const HinooDraft({
    required this.pages,
    this.type = HinooType.personal,
    this.recipientTag,
    this.baseCanvasHeight,
  });

  HinooDraft copyWith({
    List<HinooSlide>? pages,
    HinooType? type,
    String? replyTo,
    String? recipientTag,
    double? baseCanvasHeight,
  }) {
    return HinooDraft(
      pages: pages ?? this.pages,
      type: type ?? this.type,
      recipientTag: recipientTag ?? this.recipientTag,
      baseCanvasHeight: baseCanvasHeight ?? this.baseCanvasHeight,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'recipientTag': recipientTag,
        'pages': pages.map((p) => p.toJson()).toList(),
        if (baseCanvasHeight != null) 'baseCanvasHeight': baseCanvasHeight,
      };

  factory HinooDraft.fromJson(Map<String, dynamic> json) => HinooDraft(
        type: _typeFrom(json['type'] as String?),
        recipientTag: json['recipientTag'] as String?,
        pages: (json['pages'] as List<dynamic>? ?? [])
            .map((e) => HinooSlide.fromJson(e as Map<String, dynamic>))
            .toList(),
        baseCanvasHeight: (json['baseCanvasHeight'] as num?)?.toDouble(),
      );

  static HinooType _typeFrom(String? s) {
    switch (s) {
      case 'moon':
      case 'public':
        return HinooType.moon;
      case 'answer':
        return HinooType.answer;
      default:
        return HinooType.personal;
    }
  }
}
