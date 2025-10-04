// test/entities/honoo_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/Honoo.dart';

void main() {
  test('Honoo costruttore posizionale base', () {
    final h = Honoo(
      1,
      '“ciao”',
      '',
      '2024-01-01T00:00:00Z',
      '2024-01-01T00:00:00Z',
      'user_1',
      HonooType.personal,
    );
    expect(h.id, 1);
    expect(h.text, '“ciao”');
    expect(h.type, HonooType.personal);
    expect(h.replyTo, isNull);
    expect(h.recipientTag, isNull);
  });

  test('Honoo con replyTo e recipientTag', () {
    final h = Honoo(
      2,
      '“risposta”',
      '',
      '2024-01-02T00:00:00Z',
      '2024-01-02T00:00:00Z',
      'user_2',
      HonooType.answer,
      'root_uuid',
      'ventoBlu',
    );
    expect(h.id, 2);
    expect(h.type, HonooType.answer);
    expect(h.replyTo, 'root_uuid');
    expect(h.recipientTag, 'ventoBlu');
  });
}
