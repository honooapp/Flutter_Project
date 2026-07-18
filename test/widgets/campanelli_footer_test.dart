import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Widgets/campanelli_footer.dart';

void main() {
  Future<void> pumpFooter(
    WidgetTester tester, {
    required bool showCampanello,
    bool isOwnCampanello = false,
    bool isKnocking = false,
    bool hasPendingKnock = false,
    bool hasAnyPendingKnock = false,
    int pendingKnockCount = 0,
    VoidCallback? onHome,
    VoidCallback? onKnock,
    VoidCallback? onOpenPendingKnocks,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampanelliFooter(
            iconSize: 40,
            bottomPadding: 10,
            desiredGap: 24,
            showCampanello: showCampanello,
            isOwnCampanello: isOwnCampanello,
            isKnocking: isKnocking,
            hasPendingKnock: hasPendingKnock,
            hasAnyPendingKnock: hasAnyPendingKnock,
            pendingKnockCount: pendingKnockCount,
            onHome: onHome ?? () {},
            onKnock: onKnock ?? () {},
            onOpenPendingKnocks: onOpenPendingKnocks ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('campanello visitatore mostra badge e inoltra le azioni',
      (tester) async {
    var home = false;
    var knocked = false;
    await pumpFooter(
      tester,
      showCampanello: true,
      hasPendingKnock: true,
      pendingKnockCount: 7,
      onHome: () => home = true,
      onKnock: () => knocked = true,
    );

    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byTooltip('Campanello'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.byType(IconButton), findsNWidgets(2));

    await tester.tap(find.byTooltip('Home'));
    await tester.tap(find.byTooltip('Campanello'));
    expect(home, isTrue);
    expect(knocked, isTrue);
  });

  testWidgets('intro con bussate mostra lista e limita il badge a 99+',
      (tester) async {
    var opened = false;
    await pumpFooter(
      tester,
      showCampanello: false,
      hasAnyPendingKnock: true,
      pendingKnockCount: 120,
      onOpenPendingKnocks: () => opened = true,
    );

    expect(find.byTooltip('Bussate in attesa'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
    await tester.tap(find.byTooltip('Bussate in attesa'));
    expect(opened, isTrue);
  });

  testWidgets('campanello proprio non mostra azioni di bussata',
      (tester) async {
    await pumpFooter(
      tester,
      showCampanello: true,
      isOwnCampanello: true,
    );

    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byTooltip('Campanello'), findsNothing);
    expect(find.byType(IconButton), findsOneWidget);
  });
}
