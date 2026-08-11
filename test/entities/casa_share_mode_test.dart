import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/casa_share_mode.dart';

void main() {
  test('mantiene etichette e valori database', () {
    expect(CasaShareMode.home.label, 'honoo e hinoo di casa');
    expect(CasaShareMode.home.dbValue, 'home');
    expect(CasaShareMode.moon.label, 'honoo e hinoo dalla luna');
    expect(CasaShareMode.moon.dbValue, 'moon');
    expect(CasaShareMode.all.label, 'tutto');
    expect(CasaShareMode.all.dbValue, 'all');
  });

  test('converte i valori database e rifiuta quelli sconosciuti', () {
    expect(CasaShareMode.fromDb('home'), CasaShareMode.home);
    expect(CasaShareMode.fromDb('moon'), CasaShareMode.moon);
    expect(CasaShareMode.fromDb('all'), CasaShareMode.all);
    expect(CasaShareMode.fromDb('unknown'), isNull);
    expect(CasaShareMode.fromDb(null), isNull);
  });
}
