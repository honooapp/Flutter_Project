import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/IsolaDelleStorie/Utility/isola_delle_storie_content_manager.dart';
import 'package:honoo/Utility/utility.dart';
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

  test(
    'le sezioni raggiunte da clicca qui non chiudono i paragrafi col punto',
    () {
      final utility = Utility();
      for (final text in <String>[
        IsolaDelleStoreContentManager.fullIslandDescription,
        utility.campanelliText,
        utility.campanelloExample1Text,
        utility.campanelloExample2Text,
      ]) {
        expect(text, isNot(contains('.')));
      }
    },
  );

  test('il testo di sostegno mantiene uno spazio finale', () {
    expect(Utility().sostieniText, endsWith('li consiglio bene\n\n'));
  });
}
