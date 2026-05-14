import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/onboarding/welcome_page.dart';

void main() {
  group('WelcomePage', () {
    testWidgets('renders welcome copy and both entry options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: WelcomePage(onRestoreBackup: () {}, onNewUser: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to\nWorkout Logger'), findsOneWidget);
      expect(
        find.text(
          'Private workout tracking that stays on this device from day one.',
        ),
        findsOneWidget,
      );
      expect(find.text('Restore a backup'), findsOneWidget);
      expect(find.text('Set up this device'), findsOneWidget);
    });

    testWidgets('invokes callbacks when entry options are tapped', (
      tester,
    ) async {
      var restoreTapped = false;
      var newUserTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: WelcomePage(
              onRestoreBackup: () {
                restoreTapped = true;
              },
              onNewUser: () {
                newUserTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore a backup'));
      await tester.pumpAndSettle();
      expect(restoreTapped, isTrue);

      await tester.tap(find.text('Set up this device'));
      await tester.pumpAndSettle();
      expect(newUserTapped, isTrue);
    });
  });
}
