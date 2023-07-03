class Exercise {
  String _exerciseTitle;
  String _exerciseDescription;
  String _exerciseImage;
  int _parentId;

  Exercise(this._parentId, this._exerciseTitle, this._exerciseDescription, this._exerciseImage);

  String get exerciseDescription => _exerciseDescription;

  set exerciseDescription(String value) {
    _exerciseDescription = value;
  }

  String get exerciseTitle => _exerciseTitle;

  set exerciseTitle(String value) {
    _exerciseTitle = value;
  }

  String get exerciseImage => _exerciseImage;

  set exerciseImage(String value) {
    _exerciseImage = value;
  }

  int get parentId => _parentId;

  set parentId (int value) {
    _parentId = value;
  }

}

