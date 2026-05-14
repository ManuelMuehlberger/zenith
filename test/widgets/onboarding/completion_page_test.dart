import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/onboarding/completion_page.dart';

void main() {
  group('CompletionPage', () {
    testWidgets('renders completion copy and privacy card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CompletionPage(
              name: 'Manu',
              isLoading: false,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You\'re ready, Manu!'), findsOneWidget);
      expect(
        find.text(
          'Your profile is ready. You can adjust these details anytime from settings.',
        ),
        findsOneWidget,
      );
      expect(find.text('Privacy First'), findsOneWidget);
      expect(find.text('Start Logging Workouts'), findsOneWidget);
    });

    testWidgets('invokes completion callback and shows loading state', (
      tester,
    ) async {
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CompletionPage(
              name: '',
              isLoading: false,
              onComplete: () {
                completed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Start Logging Workouts'),
      );
      await tester.pump();
      expect(completed, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CompletionPage(name: '', isLoading: true, onComplete: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      final FilledButton button = tester.widget(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
