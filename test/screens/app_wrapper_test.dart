import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/main.dart';
import 'package:zenith/screens/app_wrapper.dart';
import 'package:zenith/screens/onboarding_screen.dart';
import 'package:zenith/services/app_navigation_service.dart';

void main() {
  setUp(() {
    AppNavigationService.instance.resetForTesting();
  });

  testWidgets(
    'shows onboarding without bootstrapping when onboarding is incomplete',
    (tester) async {
      var bootstrapCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AppWrapper(
            onboardingStatusLoader: () async => false,
            bootstrapApp: () async {
              bootstrapCalls += 1;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(MainScreen), findsNothing);
      expect(bootstrapCalls, 0);
    },
  );

  testWidgets(
    'shows loading state until bootstrapping completes, then renders main screen',
    (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          home: AppWrapper(
            onboardingStatusLoader: () async => true,
            bootstrapApp: () => completer.future,
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Preparing your workout data...'), findsOneWidget);
      expect(find.byType(MainScreen), findsNothing);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );

  testWidgets(
    'shows retry UI when bootstrapping fails and retries successfully',
    (tester) async {
      var attempts = 0;

      Future<void> bootstrap() async {
        attempts += 1;
        if (attempts == 1) {
          throw StateError('boom');
        }
      }

      await tester.pumpWidget(
        MaterialApp(
          home: AppWrapper(
            onboardingStatusLoader: () async => true,
            bootstrapApp: bootstrap,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('The app could not finish starting up.'),
        findsOneWidget,
      );
      expect(find.textContaining('boom'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(attempts, 2);
      expect(find.byType(MainScreen), findsOneWidget);
    },
  );
}
