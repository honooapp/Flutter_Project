import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:honoo/main.dart';
import 'package:honoo/Pages/home_page.dart';
import 'package:honoo/Pages/chest_page.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel pathChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathChannel, (methodCall) async {
    return '/tmp';
  });


  testWidgets('utente autenticato → home → scrigno con dati mock',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);

    final chestButton = find.byTooltip('Apri il tuo Cuore');
    expect(chestButton, findsOneWidget);
    await tester.tap(chestButton);
    await tester.pumpAndSettle();
    // Extra attesa per permettere a caroselli/transizioni di stabilizzarsi
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ChestPage), findsOneWidget);
    expect(find.textContaining('Test chest flow'), findsWidgets);
  });
}

