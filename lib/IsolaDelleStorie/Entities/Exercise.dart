class Exercise {
  String _id;
  String _exerciseTitle;
  String _exerciseDescription;
  String _exerciseImage;
  int _parentId;
  String? _exerciseDescriptionMore;
  String? _exerciseIcon;
  String? _exerciseIconName;

  Exercise(this._id, this._parentId, this._exerciseTitle,
      this._exerciseDescription, this._exerciseImage,
      {String? exerciseDescriptionMore,
      String? exerciseIcon,
      String? exerciseIconName})
      : _exerciseDescriptionMore = exerciseDescriptionMore,
        _exerciseIcon = exerciseIcon,
        _exerciseIconName = exerciseIconName;

  String get id => _id;
  set id(String value) => _id = value;

  String get exerciseDescription => _exerciseDescription;
  set exerciseDescription(String value) => _exerciseDescription = value;

  String get exerciseTitle => _exerciseTitle;
  set exerciseTitle(String value) => _exerciseTitle = value;

  String get exerciseImage => _exerciseImage;
  set exerciseImage(String value) => _exerciseImage = value;

  int get parentId => _parentId;
  set parentId(int value) => _parentId = value;

  String? get exerciseDescriptionMore => _exerciseDescriptionMore;
  set exerciseDescriptionMore(String? value) =>
      _exerciseDescriptionMore = value;

  String? get exerciseIcon => _exerciseIcon;
  set exerciseIcon(String? value) => _exerciseIcon = value;

  String? get exerciseIconName => _exerciseIconName;
  set exerciseIconName(String? value) => _exerciseIconName = value;
}
