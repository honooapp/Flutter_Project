import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Controller/honoo_controller.dart';

import '../test_supabase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true);
    harness.enableOverrides();
  });

  tearDown(() => harness.disableOverrides());

  test('loadChest marca un honoo con la stessa copia già sulla Luna',
      () async {
    final hiddenConversations = harness.stubTable(
      'chest_hidden_conversations',
    );
    hiddenConversations.queueResponse(const []);
    final honoo = harness.stubTable('honoo');
    honoo.queueResponse([
      {
        'id': 'chest-1',
        'text': 'Testo',
        'image_url': 'image.png',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'user_id': 'test_user',
        'destination': 'chest',
      }
    ]);
    honoo.queueResponse([
      {
        'id': 'moon-1',
        'text': 'Testo',
        'image_url': 'image.png',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'user_id': 'test_user',
        'destination': 'moon',
      }
    ]);
    honoo.queueResponse(const []);

    final controller = HonooController();
    await controller.loadChest();

    expect(controller.personal.single.isOnMoon, isTrue);
  });
}
