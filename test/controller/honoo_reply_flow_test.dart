import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:honoo/Controller/honoo_controller.dart';
import 'package:honoo/Entities/honoo.dart';

import '../test_supabase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseTestHarness harness;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true);
    harness.enableOverrides();
  });

  tearDown(() {
    harness.disableOverrides();
  });

  test('HonooController.getHonooHistory recupera root e reply', () async {
    final chain = harness.stubTable('honoo');
    chain.queueResponse([
      {
        'id': 'root-1',
        'text': 'Root',
        'image_url': '',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'user_id': 'user-1',
        'destination': 'chest',
        'reply_to': null,
        'recipient_tag': null,
      },
      {
        'id': 'reply-1',
        'text': 'Reply',
        'image_url': '',
        'created_at': '2024-01-02T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
        'user_id': 'user-2',
        'destination': 'reply',
        'reply_to': 'root-1',
        'recipient_tag': 'user-1',
      },
    ]);

    final root = Honoo(
      1,
      'Root',
      '',
      '2024-01-01T00:00:00Z',
      '2024-01-01T00:00:00Z',
      'user-1',
      HonooType.personal,
    );
    root.dbId = 'root-1';

    final list = await HonooController().getHonooHistory(root);

    expect(list.length, 2);
    expect(list.first.dbId, 'root-1');
    expect(list.last.replyTo, 'root-1');
    verify(() => chain.select(
            'id,text,image_url,destination,reply_to,recipient_tag,created_at,updated_at,user_id'))
        .called(1);
    verify(() => chain.or('id.eq.root-1,reply_to.eq.root-1')).called(1);
    verify(() => chain.order('created_at', ascending: true)).called(1);
  });
}
