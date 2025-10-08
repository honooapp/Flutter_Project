import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:honoo/main.dart';
import 'package:honoo/Pages/home_page.dart';
import 'package:honoo/Pages/chest_page.dart';

import '../test_supabase_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel pathChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathChannel, (methodCall) async {
    return '/tmp';
  });

  late SupabaseTestHarness harness;
  late MockQueryChain honooChain;
  late MockQueryChain hinooChain;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true);
    honooChain = harness.stubTable('honoo');
    honooChain.queueResponse([
      {
        'id': 'uuid-chest-1',
        'text': 'Test chest flow',
        'image_url': '',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'user_id': 'test_user',
        'type': 'personal',
        'destination': 'chest',
      }
    ]);
    honooChain.queueResponse(<Map<String, dynamic>>[]); // reply_to lookup
    honooChain.queueResponse([
      {
        'id': 'uuid-chest-1',
        'text': 'Test chest flow',
        'image_url': '',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'user_id': 'test_user',
        'type': 'personal',
        'destination': 'chest',
      }
    ]); // history load
    honooChain.queueResponse(<String, dynamic>{});

    hinooChain = harness.stubTable('hinoo');
    hinooChain.queueResponse(<Map<String, dynamic>>[]); // no hinoo draft

    harness.enableOverrides();
  });

  tearDown(() {
    harness.disableOverrides();
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

    expect(find.byType(ChestPage), findsOneWidget);
    expect(find.textContaining('Test chest flow'), findsWidgets);
  });
}
