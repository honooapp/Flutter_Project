class Exercise {
  String _exerciseTitle;
  String _exerciseDescription;
  String _exerciseImage;
  bool _hasSubMenu;

  Exercise(this._exerciseTitle, this._exerciseDescription, this._exerciseImage, this._hasSubMenu);

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


  bool get hasSubMenu => _hasSubMenu;

  set hasSubMenu(bool value) {
    _hasSubMenu = value;
  }

}

