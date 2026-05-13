import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/onboarding_screen.dart';
import 'package:zenith/theme/app_theme.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('shows the welcome entry point for new users', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to\nWorkout Logger'), findsOneWidget);
      expect(find.text("I'm New Here"), findsOneWidget);
    });
  });
}
