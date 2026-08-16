import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver.dart';
import 'package:honoo/Widgets/gallery_save_dialog.dart';

class _FakeDownloadSaver implements DownloadSaver {
  bool openCalled = false;

  @override
  Future<bool> openSavedImage(DownloadSaveResult result) async {
    openCalled = true;
    return true;
  }

  @override
  Future<DownloadSaveResult> save(
    List<DownloadImage> images, {
    String? message,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  const result = DownloadSaveResult(
    message: 'Immagine salvata nella galleria.',
    savedToGallery: true,
    savedItemUri: 'content://gallery/honoo.png',
  );

  Future<void> pumpDialog(
    WidgetTester tester,
    _FakeDownloadSaver saver, {
    String contentName = 'honoo',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDownloadSaveResult(
                context: context,
                contentName: contentName,
                result: result,
              ),
              child: const Text('Salva'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra il popup honoo e torna alla schermata con OK', (
    tester,
  ) async {
    final saver = _FakeDownloadSaver();
    await pumpDialog(tester, saver);

    expect(
      find.text('L’honoo è nella tua Galleria delle foto'),
      findsOneWidget,
    );
    expect(find.text('Ignora'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(saver.openCalled, isFalse);
    expect(find.text('Salva'), findsOneWidget);
  });

  testWidgets('non apre la galleria dopo la conferma', (tester) async {
    final saver = _FakeDownloadSaver();
    await pumpDialog(tester, saver);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(saver.openCalled, isFalse);
    expect(find.text('Salva'), findsOneWidget);
  });

  testWidgets('il messaggio usa correttamente il nome hinoo', (tester) async {
    final saver = _FakeDownloadSaver();
    await pumpDialog(tester, saver, contentName: 'hinoo');

    expect(
      find.text('L’hinoo è nella tua Galleria delle foto'),
      findsOneWidget,
    );
  });

  testWidgets('il messaggio usa correttamente il nome campanello', (
    tester,
  ) async {
    final saver = _FakeDownloadSaver();
    await pumpDialog(tester, saver, contentName: 'campanello');

    expect(
      find.text('Il campanello è nella tua Galleria delle foto'),
      findsOneWidget,
    );
  });
}
