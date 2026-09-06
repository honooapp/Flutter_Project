import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Services/hinoo_service.dart';
import 'package:honoo/Services/honoo_service.dart';
import 'package:mocktail/mocktail.dart';
import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);
  late SupabaseTestHarness harness;
  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true)
      ..enableOverrides();
  });
  tearDown(() => harness.disableOverrides());

  for (final table in ['honoo', 'hinoo']) {
    test(
      '$table updates the original only, preserving ownership and links',
      () async {
        final chain = harness.stubTable(table);
        when(() => chain.single()).thenAnswer((_) => chain);
        chain.queueResponse({'id': 'original'});
        if (table == 'honoo') {
          await HonooService.updateContent(
            id: 'original',
            text: 'edited',
            imageUrl: 'image',
          );
        } else {
          await HinooService.updateContent(
            id: 'original',
            draft: const HinooDraft(
              pages: [
                HinooSlide(
                  backgroundImage: 'image',
                  text: 'edited',
                  isTextWhite: true,
                ),
              ],
            ),
          );
        }
        verify(() => chain.eq('id', 'original')).called(1);
        verify(() => chain.eq('user_id', 'test_user')).called(1);
        final payload =
            verify(() => chain.update(captureAny())).captured.single as Map;
        expect(
          payload.keys,
          unorderedEquals(
            table == 'honoo'
                ? ['text', 'image_url', 'fingerprint']
                : ['pages', 'fingerprint'],
          ),
        );
        verifyNever(() => chain.insert(any()));
      },
    );
  }

  test('content updates require authentication', () async {
    when(() => harness.auth.currentUser).thenReturn(null);
    await expectLater(
      HonooService.updateContent(
        id: 'original',
        text: 'text',
        imageUrl: 'image',
      ),
      throwsStateError,
    );
    await expectLater(
      HinooService.updateContent(
        id: 'original',
        draft: const HinooDraft(pages: []),
      ),
      throwsStateError,
    );
    verifyNever(() => harness.client.from(any()));
  });
}
