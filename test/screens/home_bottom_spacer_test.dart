import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/home_screen.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/main_dock_spacer.dart';

void main() {
  testWidgets(
    'HomeScreen includes bottom spacer to avoid floating dock overlap',
    (tester) async {
      const double bottomSafe = 24.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.only(bottom: bottomSafe)),
            child: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MainDockSpacerSliver), findsOneWidget);

      final spacerBoxFinder = find.descendant(
        of: find.byType(MainDockSpacerSliver),
        matching: find.byType(SizedBox),
      );

      expect(
        spacerBoxFinder,
        findsOneWidget,
        reason:
            'Expected a bottom SliverToBoxAdapter with enough height to clear the floating dock',
      );

      final spacerBox = tester.widget<SizedBox>(spacerBoxFinder);
      expect(
        spacerBox.height,
        greaterThanOrEqualTo(bottomSafe + AppTheme.mainDockClearance),
      );
    },
  );
}
