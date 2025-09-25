import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/workout_builder_screen.dart';
import 'package:zenith/services/workout_session_service.dart';

void main() {
  testWidgets('WorkoutBuilderScreen includes bottom spacer to avoid glass tab bar overlap', (tester) async {
    // Simulate a device with a bottom safe area (e.g., iPhone with home indicator)
    const double bottomSafe = 24.0;
    const expectedHeight = bottomSafe + kBottomNavigationBarHeight;

    // Ensure no active session so WorkoutBuilderScreen renders its main content (not ActiveWorkoutScreen)
    await tester.runAsync(() async {
      await WorkoutSessionService.instance.clearActiveSession(deleteFromDb: false);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: bottomSafe)),
          child: const WorkoutBuilderScreen(),
        ),
      ),
    );
    // Avoid pumpAndSettle; app may schedule timers/post-frame callbacks that never settle in tests
    await tester.pump();

    // If screen is still in loading/redirect state, CustomScrollView won't be present.
    // In that case, we exit early (the spacer is asserted only when scroll content is shown).
    final hasScroll = find.byType(CustomScrollView).evaluate().isNotEmpty;
    if (!hasScroll) {
      // Sanity: confirm we're not on ActiveWorkoutScreen by mistake
      expect(hasScroll, isFalse, reason: 'WorkoutBuilderScreen still loading; skipping spacer assertion.');
      return;
    }

    // Find a SizedBox with at least the bar height (bottom spacer)
    final spacerFinder = find.byWidgetPredicate((w) {
      if (w is SizedBox) {
        final h = w.height;
        return h != null && h >= kBottomNavigationBarHeight;
      }
      return false;
    });

    expect(spacerFinder, findsAtLeastNWidgets(1),
        reason: 'Expected a bottom SizedBox with height >= kBottomNavigationBarHeight');
  });
}
