import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/screens/workout_completion_screen.dart';

void main() {
  group('WorkoutCompletionScreen duration editing (iOS style)', () {
    testWidgets('tapping duration shows CupertinoTimerPicker and cancel/done actions', (WidgetTester tester) async {
      final start = DateTime(2025, 1, 1, 12, 0, 0);
      final duration = const Duration(minutes: 12, seconds: 34);
      final session = Workout(
        name: 'Finishable',
        status: WorkoutStatus.inProgress,
        startedAt: start,
        completedAt: start.add(duration),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutCompletionScreen(session: session),
        ),
      );

      // Initial formatted duration is visible (minutes only)
      expect(find.text('12m'), findsOneWidget);

      // Tap on the summary tile to open the iOS-style picker
      await tester.tap(find.byKey(const Key('duration_summary')));
      await tester.pumpAndSettle();

      // CupertinoTimerPicker should appear
      expect(find.byType(CupertinoTimerPicker), findsOneWidget);

      // Cancel should close without changes
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoTimerPicker), findsNothing);
      // Still the same duration
      expect(find.text('12m'), findsOneWidget);
    });

    testWidgets('changing seconds in CupertinoTimerPicker updates the summary after Done', (WidgetTester tester) async {
      final start = DateTime(2025, 1, 1, 12, 0, 0);
      final duration = const Duration(minutes: 12, seconds: 34);
      final session = Workout(
        name: 'Finishable',
        status: WorkoutStatus.inProgress,
        startedAt: start,
        completedAt: start.add(duration),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutCompletionScreen(session: session),
        ),
      );

      // Open picker
      await tester.tap(find.byKey(const Key('duration_summary')));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoTimerPicker), findsOneWidget);

      // The CupertinoTimerPicker composes multiple CupertinoPicker columns (h, m).
      // Drag the minutes column (usually the last CupertinoPicker) up by ~one item height to increment minutes by 1.
      final minutesColumn = find.descendant(
        of: find.byType(CupertinoTimerPicker),
        matching: find.byType(CupertinoPicker),
      ).last;

      // Drag by approximately one item (default itemExtent is ~32.0)
      await tester.drag(minutesColumn, const Offset(0, -32));
      await tester.pumpAndSettle();

      // Confirm by tapping Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Summary should reflect updated duration (13m)
      expect(find.text('13m'), findsOneWidget);
    });
  });
}
