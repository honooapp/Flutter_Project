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

  test('le descrizioni dell’Isola non mostrano punti a fine paragrafo', () {
    const source = 'Primo paragrafo.\n\n<b>Secondo paragrafo.<b>\n\nAttendi...';

    expect(
      IsolaDelleStoreContentManager.withoutParagraphTrailingPeriods(source),
      'Primo paragrafo\n\n<b>Secondo paragrafo<b>\n\nAttendi...',
    );
  });

  test('preserva i puntini di sospensione prima della chiusura di stile', () {
    expect(
      IsolaDelleStoreContentManager.withoutParagraphTrailingPeriods(
        '<b>Attendi...<b>\n\nPoi continua.',
      ),
      '<b>Attendi...<b>\n\nPoi continua',
    );
  });

  test('rimuove il punto dall’ultimo paragrafo prima della riga finale', () {
    expect(
      IsolaDelleStoreContentManager.withoutParagraphTrailingPeriods(
        'Ultimo paragrafo.\n',
      ),
      'Ultimo paragrafo\n',
    );
  });

  test('il testo di sostegno mantiene uno spazio finale', () {
    expect(Utility().sostieniText, endsWith('li consiglio bene\n\n'));
  });

  test('il secondo campanello mantiene la posizione manuale del testo', () {
    final text = Utility().campanelloExample2Text;

    expect(text, startsWith('Ti piace'));
    expect(text, contains('Questo è il campanello\ndi casa mia'));
    expect(text.split('\n'), hasLength(13));
  });
}
