import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:honoo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boot → mostra login o home senza crash', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // accetta entrambe: se non loggato vedrai la login, se loggato la home
    expect(find.textContaining('Login', findRichText: true).evaluate().isNotEmpty ||
        find.textContaining('Home', findRichText: true).evaluate().isNotEmpty, isTrue);
  },
tags: ['integration']
  );
}
