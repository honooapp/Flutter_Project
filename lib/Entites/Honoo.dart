class Honoo {
  int _id;
  String _text;
  String _image;
  String _created_at;
  String _updated_at;
  String _author;
  HonooType _type;


  Honoo(this._id, this._text, this._image, this._created_at, this._updated_at, this._author, this._type);

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

  String get author => _author;

  set author(String value) {
    _author = value;
  }

  HonooType get type => _type;

  set type(HonooType value) {
    _type = value;
  }
}

enum HonooType { personal, moon, answer }