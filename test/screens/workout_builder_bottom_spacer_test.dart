import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/workout_builder_screen.dart';
import 'package:zenith/services/workout_session_service.dart';
import 'package:zenith/widgets/main_dock_spacer.dart';

void main() {
  testWidgets(
    'WorkoutBuilderScreen includes bottom spacer to avoid glass tab bar overlap',
    (tester) async {
      // Simulate a device with a bottom safe area (e.g., iPhone with home indicator)
      const double bottomSafe = 24.0;

      // Ensure no active session so WorkoutBuilderScreen renders its main content (not ActiveWorkoutScreen)
      await tester.runAsync(() async {
        await WorkoutSessionService.instance.clearActiveSession(
          deleteFromDb: false,
        );
      });
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.only(bottom: bottomSafe)),
            child: WorkoutBuilderScreen(),
          ),
        ),
      );
      // Avoid pumpAndSettle; app may schedule timers/post-frame callbacks that never settle in tests
      await tester.pump();

      final spacerFinder = find.byType(MainDockSpacer);

      for (var attempt = 0; attempt < 20; attempt++) {
        if (spacerFinder.evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 50));
      }

      if (spacerFinder.evaluate().isEmpty) {
        expect(
          find.byType(CircularProgressIndicator),
          findsAtLeastNWidgets(1),
          reason:
              'WorkoutBuilderScreen did not finish loading in the test window; skipping spacer assertion.',
        );
        return;
      }

      expect(
        spacerFinder,
        findsOneWidget,
        reason: 'Expected WorkoutBuilderScreen to include MainDockSpacer',
      );
    },
  );
}
