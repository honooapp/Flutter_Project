import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Utility/interface_text.dart';

void main() {
  test('rimuove il punto finale dai testi di interfaccia', () {
    expect(
      withoutInterfaceTrailingPeriod('Operazione completata.'),
      'Operazione completata',
    );
    expect(
      withoutInterfaceTrailingPeriod('Operazione completata.\n'),
      'Operazione completata\n',
    );
  });

  test('mantiene i puntini di sospensione e il testo senza punto', () {
    expect(withoutInterfaceTrailingPeriod('Attendi...'), 'Attendi...');
    expect(withoutInterfaceTrailingPeriod('Salva honoo'), 'Salva honoo');
  });
}
