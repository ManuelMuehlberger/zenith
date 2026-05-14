import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/onboarding_screen.dart';
import 'package:zenith/theme/app_theme.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('shows the local-first welcome entry point', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to\nWorkout Logger'), findsOneWidget);
      expect(
        find.text(
          'Private workout tracking that stays on this device from day one.',
        ),
        findsOneWidget,
      );
      expect(find.text('Set up this device'), findsOneWidget);
    });

    testWidgets('supports edge-swipe back to the previous step', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set up this device'));
      await tester.pumpAndSettle();

      expect(find.text('What should we call you?'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('onboardingBackSwipeRegion')),
        const Offset(120, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to\nWorkout Logger'), findsOneWidget);
    });
  });
}
