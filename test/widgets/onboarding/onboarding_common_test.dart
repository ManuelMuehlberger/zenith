import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/onboarding/onboarding_common.dart';

void main() {
  group('OnboardingStepLayout', () {
    testWidgets('renders shared title, subtitle, content, and footer', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: OnboardingStepLayout(
              current: 2,
              total: 5,
              onBack: () {},
              title: 'Step title',
              subtitle: 'Step subtitle',
              footer: const Text('Footer action'),
              child: const Text('Step body'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step title'), findsOneWidget);
      expect(find.text('Step subtitle'), findsOneWidget);
      expect(find.text('Step body'), findsOneWidget);
      expect(find.text('Footer action'), findsOneWidget);
    });
  });

  group('OnboardingNavigationButtons', () {
    testWidgets('disables and enables continue based on canContinue', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: OnboardingNavigationButtons(
              canContinue: false,
              onNext: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      FilledButton button = tester.widget(
        find.widgetWithText(FilledButton, 'Continue'),
      );
      expect(button.onPressed, isNull);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: OnboardingNavigationButtons(
              canContinue: true,
              onNext: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      button = tester.widget(find.widgetWithText(FilledButton, 'Continue'));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
