class Honoo {
  // ID locale (int) che usavi finora — opzionale
  int id;

  // UUID reale della riga su DB (stringa)
  String? dbId;

  String text;
  String image;
  String createdAt;
  String updatedAt;
  String userId;
  HonooType type;
  String? replyTo;
  String? recipientTag;

  // Nuovi flag lato app
  bool isFromMoonSaved;
  bool hasReplies;

  Honoo(
    this.id,
    this.text,
    this.image,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.type, [
    this.replyTo,
    this.recipientTag,
  ])  : dbId = null,
        isFromMoonSaved = false,
        hasReplies = false;

  // Comodità
  String? get idAsString => dbId;

  // ===== Factory da DB =====
  factory Honoo.fromMap(Map<String, dynamic> map) {
    final h = Honoo(
      0, // ID locale (inutile per il DB)
      (map['text'] ?? '') as String,
      (map['image_url'] ?? '') as String,
      (map['created_at'] ?? '') as String,
      (map['updated_at'] ?? '') as String,
      (map['user_id'] ?? '') as String,
      _mapDestinationToHonooType((map['destination'] ?? 'chest') as String),
      map['reply_to']?.toString(),
      map['recipient_tag']?.toString(),
    );

    // uuid vero della riga
    h.dbId = map['id']?.toString();

    // Flag opzionali se esistono a DB, altrimenti false
    h.isFromMoonSaved = (map['is_from_moon_saved'] as bool?) ?? false;
    h.hasReplies = (map['has_replies'] as bool?) ?? false;

    return h;
  }

  // ===== Map per update/insert =====
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'image_url': image,
      'created_at': createdAt,
      'user_id': userId,
      'destination': _mapHonooTypeToDestination(type),
      'reply_to': replyTo,
      'recipient_tag': recipientTag,
      // opzionali: salva solo se hai colonne a DB
      'is_from_moon_saved': isFromMoonSaved,
      'has_replies': hasReplies,
    };
  }

  /// Solo per INSERT: niente id/created_at/updated_at/user_id
  Map<String, dynamic> toInsertMap() {
    final dest = _mapHonooTypeToDestination(type);
    return {
      'text': text,
      'image_url': image.isEmpty ? null : image,
      'destination': dest, // 'chest' | 'moon' | 'reply'
      'reply_to': dest == 'reply' ? replyTo : null,
      'recipient_tag': dest == 'reply' ? recipientTag : null,
    };
  }

  /// Solo per UPDATE: campi editabili
  Map<String, dynamic> toUpdateMap() {
    return {
      'text': text,
      'image_url': image.isEmpty ? null : image,
      'destination': _mapHonooTypeToDestination(type),
      'reply_to': replyTo,
      'recipient_tag': recipientTag,
    };
  }

  // ===== copyWith per modifiche immutabili =====
  Honoo copyWith({
    int? id,
    String? dbId,
    String? text,
    String? image,
    String? createdAt,
    String? updatedAt,
    String? userId,
    HonooType? type,
    String? replyTo,
    String? recipientTag,
    bool? isFromMoonSaved,
    bool? hasReplies,
  }) {
    final h = Honoo(
      id ?? this.id,
      text ?? this.text,
      image ?? this.image,
      createdAt ?? this.createdAt,
      updatedAt ?? this.updatedAt,
      userId ?? this.userId,
      type ?? this.type,
      replyTo ?? this.replyTo,
      recipientTag ?? this.recipientTag,
    );
    h.dbId = dbId ?? this.dbId;
    h.isFromMoonSaved = isFromMoonSaved ?? this.isFromMoonSaved;
    h.hasReplies = hasReplies ?? this.hasReplies;
    return h;
  }

  // ===== mapper tipo <-> destination =====
  static HonooType _mapDestinationToHonooType(String destination) {
    switch (destination) {
      case 'moon':
        return HonooType.moon;
      case 'reply':
        return HonooType.answer;
      case 'chest':
      default:
        return HonooType.personal;
    }
  }

  static String _mapHonooTypeToDestination(HonooType type) {
    switch (type) {
      case HonooType.moon:
        return 'moon';
      case HonooType.answer:
        return 'reply';
      case HonooType.personal:
      default:
        return 'chest';
    }
  }
}

enum HonooType { personal, moon, answer }
