// lib/Entities/Hinoo.dart
import 'package:flutter/foundation.dart';

enum HinooType { personal, moon, answer }

@immutable
class HinooSlide {
  final String? backgroundImage; // URL pubblico (dopo upload)
  final String text;             // testo centrato
  final bool isTextWhite;        // true=bianco, false=nero
  final double bgScale;   // default 1.0
  final double bgOffsetX; // default 0.0
  final double bgOffsetY; // default 0.0

  const HinooSlide({
    required this.backgroundImage,
    required this.text,
    required this.isTextWhite,
    this.bgScale = 1.0,
    this.bgOffsetX = 0.0,
    this.bgOffsetY = 0.0,
  });

  HinooSlide copyWith({
    String? backgroundImage,
    String? text,
    bool? isTextWhite,
    double? bgScale,
    double? bgOffsetX,
    double? bgOffsetY,
  }) {
    return HinooSlide(
      backgroundImage: backgroundImage ?? this.backgroundImage,
      text: text ?? this.text,
      isTextWhite: isTextWhite ?? this.isTextWhite,
      bgScale: bgScale ?? this.bgScale,
      bgOffsetX: bgOffsetX ?? this.bgOffsetX,
      bgOffsetY: bgOffsetY ?? this.bgOffsetY,
    );
  }

  Map<String, dynamic> toJson() => {
    'backgroundImage': backgroundImage,
    'text': text,
    'isTextWhite': isTextWhite,
    'bgScale': bgScale,
    'bgOffsetX': bgOffsetX,
    'bgOffsetY': bgOffsetY,
  };


  factory HinooSlide.fromJson(Map<String, dynamic> json) => HinooSlide(
    backgroundImage: json['backgroundImage'] as String?,
    text: (json['text'] as String?) ?? '',
    isTextWhite: (json['isTextWhite'] as bool?) ?? true,
    bgScale: (json['bgScale'] as num?)?.toDouble() ?? 1.0,
    bgOffsetX: (json['bgOffsetX'] as num?)?.toDouble() ?? 0.0,
    bgOffsetY: (json['bgOffsetY'] as num?)?.toDouble() ?? 0.0,
  );
}

@immutable
class HinooDraft {
  final List<HinooSlide> pages;
  final HinooType type;       // personal | moon | answer
  final String? replyTo;      // opzionale → id hinoo a cui rispondi
  final String? recipientTag; // opzionale

  const HinooDraft({
    required this.pages,
    this.type = HinooType.personal,
    this.replyTo,
    this.recipientTag,
  });

  HinooDraft copyWith({
    List<HinooSlide>? pages,
    HinooType? type,
    String? replyTo,
    String? recipientTag,
  }) {
    return HinooDraft(
      pages: pages ?? this.pages,
      type: type ?? this.type,
      replyTo: replyTo ?? this.replyTo,
      recipientTag: recipientTag ?? this.recipientTag,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'replyTo': replyTo,
    'recipientTag': recipientTag,
    'pages': pages.map((p) => p.toJson()).toList(),
  };

  factory HinooDraft.fromJson(Map<String, dynamic> json) => HinooDraft(
    type: _typeFrom(json['type'] as String?),
    replyTo: json['replyTo'] as String?,
    recipientTag: json['recipientTag'] as String?,
    pages: (json['pages'] as List<dynamic>? ?? [])
        .map((e) => HinooSlide.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static HinooType _typeFrom(String? s) {
    switch (s) {
      case 'moon': return HinooType.moon;
      case 'answer': return HinooType.answer;
      default: return HinooType.personal;
    }
  }
}
