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

  Future<void> pumpDialog(WidgetTester tester, _FakeDownloadSaver saver) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDownloadSaveResult(
                context: context,
                contentName: 'honoo',
                openSavedImage: saver.openSavedImage,
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

  testWidgets('Ignora chiude il dialogo senza aprire la galleria', (
    tester,
  ) async {
    final saver = _FakeDownloadSaver();
    await pumpDialog(tester, saver);

    expect(
      find.text("L'honoo è stato salvato nella tua galleria delle foto"),
      findsOneWidget,
    );

    await tester.tap(find.text('Ignora'));
    await tester.pumpAndSettle();

    expect(saver.openCalled, isFalse);
    expect(find.text('Salva'), findsOneWidget);
  });

  testWidgets('Apri galleria apre esattamente il file salvato', (tester) async {
    final saver = _FakeDownloadSaver();
    await pumpDialog(tester, saver);

    await tester.tap(find.text('Apri galleria'));
    await tester.pumpAndSettle();

    expect(saver.openCalled, isTrue);
    expect(find.text('Salva'), findsOneWidget);
  });
}
