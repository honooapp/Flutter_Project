import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Pages/new_honoo_page.dart';
import 'package:honoo/UI/honoo_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sizer/sizer.dart';
import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);
  for (final sendToMoon in [false, true]) {
    testWidgets(
      'save keeps editor open, moon=$sendToMoon, and updates original again',
      (tester) async {
        final harness = SupabaseTestHarness(withAuthenticatedUser: true)
          ..enableOverrides();
        addTearDown(harness.disableOverrides);
        final chain = harness.stubTable('honoo');
        when(() => chain.single()).thenAnswer((_) => chain);
        final original = Honoo(
          0,
          'Testo originale',
          '',
          '',
          '',
          'test_user',
          HonooType.personal,
        )..dbId = 'original';
        await tester.pumpWidget(
          Sizer(
            builder: (_, _, _) =>
                MaterialApp(home: NewHonooPage(editingHonoo: original)),
          ),
        );
        await tester.pumpAndSettle();
        for (var save = 0; save < 2; save++) {
          await tester.enterText(find.byType(TextField).first, 'Testo $save');
          await tester.pump();
          final builder = tester.widget<HonooBuilder>(
            find.byType(HonooBuilder),
          );
          builder.onHonooChanged!(
            'Testo $save',
            'https://example.com/image.png',
          );
          await tester.pump();
          chain.queueResponse({'id': 'original'});
          final pending = builder.onImageConfirmed!();
          await tester.pumpAndSettle();
          expect(
            find.text("L'honoo è stato salvato nel tuo Scrigno"),
            findsOneWidget,
          );
          if (sendToMoon) chain.queueResponse(null);
          await tester.tap(find.text(sendToMoon ? 'Sì' : 'No'));
          await tester.pumpAndSettle();
          expect(await pending, isTrue);
          expect(find.byType(NewHonooPage), findsOneWidget);
          expect(
            tester
                .widget<TextField>(find.byType(TextField).first)
                .controller!
                .text,
            'Testo $save',
          );
          expect(find.byKey(const Key('content-edit-text')), findsOneWidget);
          expect(find.byKey(const Key('content-edit-image')), findsOneWidget);
        }
        verify(() => chain.eq('id', 'original')).called(2);
        verify(() => chain.update(any())).called(2);
      },
    );
  }
}
