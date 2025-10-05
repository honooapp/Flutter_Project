class Honoo {
  // ID locale (int) che usavi finora — opzionale
  int _id;

  // UUID reale della riga su DB (stringa)
  String? _dbId;

  String _text;
  String _image;
  String _created_at;
  String _updated_at;
  String _user_id;
  HonooType _type;
  String? _replyTo;
  String? _recipientTag;

  // Nuovi flag lato app
  bool _isFromMoonSaved;
  bool _hasReplies;

  Honoo(
    this._id,
    this._text,
    this._image,
    this._created_at,
    this._updated_at,
    this._user_id,
    this._type, [
    this._replyTo,
    this._recipientTag,
  ])  : _dbId = null,
        _isFromMoonSaved = false,
        _hasReplies = false;

  // ===== Getter/Setter esistenti =====
  String get updated_at => _updated_at;
  set updated_at(String value) => _updated_at = value;

  String get created_at => _created_at;
  set created_at(String value) => _created_at = value;

  String get image => _image;
  set image(String value) => _image = value;

  String get text => _text;
  set text(String value) => _text = value;

  int get id => _id;
  set id(int value) => _id = value;

  String get user_id => _user_id;
  set user_id(String value) => _user_id = value;

  HonooType get type => _type;
  set type(HonooType value) => _type = value;

  String? get replyTo => _replyTo;
  set replyTo(String? value) => _replyTo = value;

  String? get recipientTag => _recipientTag;
  set recipientTag(String? value) => _recipientTag = value;

  // ===== Nuovi getter/setter =====
  String? get dbId => _dbId; // uuid del DB
  set dbId(String? v) => _dbId = v;

  bool get isFromMoonSaved => _isFromMoonSaved;
  set isFromMoonSaved(bool v) => _isFromMoonSaved = v;

  bool get hasReplies => _hasReplies;
  set hasReplies(bool v) => _hasReplies = v;

  // Comodità
  String? get idAsString => _dbId;

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
    h._dbId = map['id']?.toString();

    // Flag opzionali se esistono a DB, altrimenti false
    h._isFromMoonSaved = (map['is_from_moon_saved'] as bool?) ?? false;
    h._hasReplies = (map['has_replies'] as bool?) ?? false;

    return h;
  }

  // ===== Map per update/insert =====
  Map<String, dynamic> toMap() {
    return {
      'text': _text,
      'image_url': _image,
      'created_at': _created_at,
      'user_id': _user_id,
      'destination': _mapHonooTypeToDestination(_type),
      'reply_to': _replyTo,
      'recipient_tag': _recipientTag,
      // opzionali: salva solo se hai colonne a DB
      'is_from_moon_saved': _isFromMoonSaved,
      'has_replies': _hasReplies,
    };
  }

  /// Solo per INSERT: niente id/created_at/updated_at/user_id
  Map<String, dynamic> toInsertMap() {
    final dest = _mapHonooTypeToDestination(_type);
    return {
      'text': _text,
      'image_url': _image.isEmpty ? null : _image,
      'destination': dest, // 'chest' | 'moon' | 'reply'
      'reply_to': dest == 'reply' ? _replyTo : null,
      'recipient_tag': dest == 'reply' ? _recipientTag : null,
    };
  }

  /// Solo per UPDATE: campi editabili
  Map<String, dynamic> toUpdateMap() {
    return {
      'text': _text,
      'image_url': _image.isEmpty ? null : _image,
      'destination': _mapHonooTypeToDestination(_type),
      'reply_to': _replyTo,
      'recipient_tag': _recipientTag,
    };
  }

  // ===== copyWith per modifiche immutabili =====
  Honoo copyWith({
    int? id,
    String? dbId,
    String? text,
    String? image,
    String? created_at,
    String? updated_at,
    String? user_id,
    HonooType? type,
    String? replyTo,
    String? recipientTag,
    bool? isFromMoonSaved,
    bool? hasReplies,
  }) {
    final h = Honoo(
      id ?? _id,
      text ?? _text,
      image ?? _image,
      created_at ?? _created_at,
      updated_at ?? _updated_at,
      user_id ?? _user_id,
      type ?? _type,
      replyTo ?? _replyTo,
      recipientTag ?? _recipientTag,
    );
    h._dbId = dbId ?? _dbId;
    h._isFromMoonSaved = isFromMoonSaved ?? _isFromMoonSaved;
    h._hasReplies = hasReplies ?? _hasReplies;
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
