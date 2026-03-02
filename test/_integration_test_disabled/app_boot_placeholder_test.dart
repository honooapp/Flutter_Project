import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:honoo/main.dart';
import 'package:honoo/Pages/placeholder_page.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();


  testWidgets('boot senza sessione mostra PlaceholderPage', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderPage), findsOneWidget);
  });
}

