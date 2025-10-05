class APIExercise {
  String _id;
  String _exerciseTitle;
  String _exerciseDescription;

  APIExercise(this._id, this._exerciseTitle, this._exerciseDescription);

  String get exerciseDescription => _exerciseDescription;

  set exerciseDescription(String value) {
    _exerciseDescription = value;
  }

  String get exerciseTitle => _exerciseTitle;

  set exerciseTitle(String value) {
    _exerciseTitle = value;
  }

  String get parentId => _id;

  set id(String value) {
    _id = value;
  }
}
