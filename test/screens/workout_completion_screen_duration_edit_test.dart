import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/screens/workout_completion_screen.dart';
import 'package:zenith/widgets/app_bottom_sheet.dart';
import 'package:zenith/widgets/weight_picker_wheel.dart';

void main() {
  group('WorkoutCompletionScreen duration editing', () {
    testWidgets('tapping duration shows shared duration wheel with done action', (
      WidgetTester tester,
    ) async {
      final start = DateTime(2025, 1, 1, 12, 0, 0);
      const duration = Duration(minutes: 12, seconds: 34);
      final session = Workout(
        name: 'Finishable',
        status: WorkoutStatus.inProgress,
        startedAt: start,
        completedAt: start.add(duration),
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutCompletionScreen(session: session)),
      );

      // Initial formatted duration is visible (minutes only)
      expect(find.text('12m'), findsOneWidget);

      // Tap on the summary tile to open the iOS-style picker
      await tester.tap(find.byKey(const Key('duration_summary')));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoTimerPicker), findsNothing);
      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(DurationPickerWheel), findsOneWidget);
      expect(find.byKey(const Key('workout_duration_picker')), findsOneWidget);
      expect(find.text('12 min'), findsNothing);
      expect(find.text('h'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBottomSheet),
          matching: find.byType(Divider),
        ),
        findsNothing,
      );

      // Done should close without changing anything if the wheel was not moved.
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(DurationPickerWheel), findsNothing);
      // Still the same duration
      expect(find.text('12m'), findsOneWidget);
    });

    testWidgets(
      'changing minutes in duration wheel updates the summary after Done',
      (WidgetTester tester) async {
        final start = DateTime(2025, 1, 1, 12, 0, 0);
        const duration = Duration(minutes: 12, seconds: 34);
        final session = Workout(
          name: 'Finishable',
          status: WorkoutStatus.inProgress,
          startedAt: start,
          completedAt: start.add(duration),
        );

        await tester.pumpWidget(
          MaterialApp(home: WorkoutCompletionScreen(session: session)),
        );

        // Open picker
        await tester.tap(find.byKey(const Key('duration_summary')));
        await tester.pumpAndSettle();

        expect(find.byType(CupertinoTimerPicker), findsNothing);
        expect(find.byType(DurationPickerWheel), findsOneWidget);

        // Drag the shared wheel's minutes column up by one item to increment minutes by 1.
        final minutesColumn = find
            .descendant(
              of: find.byType(DurationPickerWheel),
              matching: find.byType(CupertinoPicker),
            )
            .last;

        await tester.drag(minutesColumn, const Offset(0, -50));
        await tester.pumpAndSettle();

        // Confirm by tapping Done
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Summary should reflect updated duration (13m)
        expect(find.text('13m'), findsOneWidget);
      },
    );
  });
}
