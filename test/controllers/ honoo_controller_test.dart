// test/controllers/honoo_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Controller/HonooController.dart';
import 'package:honoo/Entities/Honoo.dart';

void main() {
  group('HonooController (senza rete)', () {
    test('ValueNotifier di default', () {
      final c = HonooController();
      expect(c.isLoading.value, isFalse);
      expect(c.version.value, equals(0));
      expect(c.personal, isA<List<Honoo>>());
    });

    test('getHonooHistory: se dbId è null ritorna almeno l’honoo stesso', () async {
      // Costruttore POSIZIONALE di Honoo: (id, text, image, created_at, updated_at, user_id, type, [replyTo, recipientTag])
      final h = Honoo(
        1,
        '“Solo locale”',
        '',                         // image_url
        '2024-01-01T00:00:00Z',     // created_at
        '2024-01-01T00:00:00Z',     // updated_at
        'user_local',               // user_id
        HonooType.personal,
      );
      // dbId resta null => ramo "offline"
      final c = HonooController();
      final history = await c.getHonooHistory(h);
      expect(history, isNotEmpty);
      expect(history.first.text, '“Solo locale”');
    });
  });
}
