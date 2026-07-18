enum CasaShareMode {
  honoo,
  hinoo,
  conversations;

  String get label {
    switch (this) {
      case CasaShareMode.honoo:
        return 'I miei honoo';
      case CasaShareMode.hinoo:
        return 'I miei hinoo';
      case CasaShareMode.conversations:
        return 'Le mie conversazioni';
    }
  }

  String get dbValue {
    switch (this) {
      case CasaShareMode.honoo:
        return 'honoo';
      case CasaShareMode.hinoo:
        return 'hinoo';
      case CasaShareMode.conversations:
        return 'conversations';
    }
  }

  static CasaShareMode? fromDb(String? value) {
    switch (value) {
      case 'honoo':
        return CasaShareMode.honoo;
      case 'hinoo':
        return CasaShareMode.hinoo;
      case 'conversations':
        return CasaShareMode.conversations;
      default:
        return null;
    }
  }
}
