import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/screens/workout_completion_screen.dart';

void main() {
  group('WorkoutCompletionScreen', () {
    testWidgets('shows elapsed duration when completedAt is null', (
      WidgetTester tester,
    ) async {
      final startedAt = DateTime.now().subtract(
        const Duration(minutes: 1, seconds: 10),
      );
      final session = Workout(
        name: 'Test Workout',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutCompletionScreen(session: session)),
      );
      await tester.pump();

      final durationFinder = find.descendant(
        of: find.byKey(const Key('duration_summary')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              RegExp(r'^\d+h \d+m$|^\d+m$').hasMatch(widget.data!),
        ),
      );

      expect(durationFinder, findsOneWidget);
    });

    testWidgets('uses completedAt when present to display duration', (
      WidgetTester tester,
    ) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 30));
      const duration = Duration(minutes: 12, seconds: 34);
      final completedAt = startedAt.add(duration);

      final session = Workout(
        name: 'Completed Workout',
        status: WorkoutStatus.completed,
        startedAt: startedAt,
        completedAt: completedAt,
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutCompletionScreen(session: session)),
      );
      await tester.pump();

      final durationFinder = find.descendant(
        of: find.byKey(const Key('duration_summary')),
        matching: find.text('12m'),
      );

      expect(durationFinder, findsOneWidget);
    });

    testWidgets('mood labels are not shown (only emojis)', (
      WidgetTester tester,
    ) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 1));
      final session = Workout(
        name: 'No Labels',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutCompletionScreen(session: session)),
      );

      // Ensure old mood labels are not present
      const labels = ['Very Sad', 'Sad', 'Neutral', 'Happy', 'Very Happy'];
      for (final label in labels) {
        expect(find.text(label), findsNothing);
      }
    });
  });
}
