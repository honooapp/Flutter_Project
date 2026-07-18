import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/casa_share_mode.dart';

void main() {
  test('mantiene etichette e valori database', () {
    expect(CasaShareMode.honoo.label, 'I miei honoo');
    expect(CasaShareMode.honoo.dbValue, 'honoo');
    expect(CasaShareMode.hinoo.label, 'I miei hinoo');
    expect(CasaShareMode.hinoo.dbValue, 'hinoo');
    expect(CasaShareMode.conversations.label, 'Le mie conversazioni');
    expect(CasaShareMode.conversations.dbValue, 'conversations');
  });

  test('converte i valori database e rifiuta quelli sconosciuti', () {
    expect(CasaShareMode.fromDb('honoo'), CasaShareMode.honoo);
    expect(CasaShareMode.fromDb('hinoo'), CasaShareMode.hinoo);
    expect(
      CasaShareMode.fromDb('conversations'),
      CasaShareMode.conversations,
    );
    expect(CasaShareMode.fromDb('unknown'), isNull);
    expect(CasaShareMode.fromDb(null), isNull);
  });
}
