class Honoo {
  int _id;
  String _text;
  String _image;
  String _created_at;
  String _updated_at;
  String _user_id;
  HonooType _type;
  String? _replyTo;
  String? _recipientTag;



  Honoo(this._id, this._text, this._image, this._created_at, this._updated_at, this._user_id, this._type,
      [this._replyTo, this._recipientTag]);

  String get updated_at => _updated_at;

  set updated_at(String value) {
    _updated_at = value;
  }

  String get created_at => _created_at;

  set created_at(String value) {
    _created_at = value;
  }

  String get image => _image;

  set image(String value) {
    _image = value;
  }

  String get text => _text;

  set text(String value) {
    _text = value;
  }

  int get id => _id;

  set id(int value) {
    _id = value;
  }

  String get user_id => _user_id;
  set user_id(String value) => _user_id = value;


  HonooType get type => _type;

  set type(HonooType value) {
    _type = value;
  }

  String? get replyTo => _replyTo;
  set replyTo(String? value) => _replyTo = value;

  String? get recipientTag => _recipientTag;
  set recipientTag(String? value) => _recipientTag = value;


  factory Honoo.fromMap(Map<String, dynamic> map) {
    return Honoo(
      0, // ID locale, opzionale se gestito da Supabase
      map['text'],
      map['image_url'],
      map['created_at'],
      map['updated_at'] ?? '',
      map['user_id'] ?? '',
      _mapDestinationToHonooType(map['destination']),
      map['reply_to'],
      map['recipient_tag'],

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': _text,
      'image_url': _image,
      'created_at': _created_at,
      'updated_at': _updated_at,
      'user_id': _user_id,
      'destination': _mapHonooTypeToDestination(_type),
      'reply_to': _replyTo,
      'recipient_tag': _recipientTag,

    };
  }

  static HonooType _mapDestinationToHonooType(String destination) {
    switch (destination) {
      case 'moon':
        return HonooType.moon;
      case 'chest':
        return HonooType.personal;
      case 'reply':
        return HonooType.answer;
      default:
        return HonooType.personal;
    }
  }

  static String _mapHonooTypeToDestination(HonooType type) {
    switch (type) {
      case HonooType.moon:
        return 'moon';
      case HonooType.personal:
        return 'chest';
      case HonooType.answer:
        return 'reply';
    }
  }

}

enum HonooType { personal, moon, answer }
