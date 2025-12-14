import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/screens/workout_completion_screen.dart';

void main() {
  group('WorkoutCompletionScreen', () {
    testWidgets('shows elapsed duration when completedAt is null', (WidgetTester tester) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 1, seconds: 10));
      final session = Workout(
        name: 'Test Workout',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutCompletionScreen(session: session),
        ),
      );

      // Expect the duration text to show minutes only (no seconds), e.g., '1m'
      expect(find.text('1m'), findsOneWidget);
    });

    testWidgets('uses completedAt when present to display duration', (WidgetTester tester) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 30));
      final duration = const Duration(minutes: 12, seconds: 34);
      final completedAt = startedAt.add(duration);

      final session = Workout(
        name: 'Completed Workout',
        status: WorkoutStatus.completed,
        startedAt: startedAt,
        completedAt: completedAt,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutCompletionScreen(session: session),
        ),
      );

      // Minutes only (no seconds) since we ignore seconds
      expect(find.text('12m'), findsOneWidget);
    });

    testWidgets('mood labels are not shown (only emojis)', (WidgetTester tester) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 1));
      final session = Workout(
        name: 'No Labels',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutCompletionScreen(session: session),
        ),
      );

      // Ensure old mood labels are not present
      const labels = ['Very Sad', 'Sad', 'Neutral', 'Happy', 'Very Happy'];
      for (final label in labels) {
        expect(find.text(label), findsNothing);
      }
    });
  });
}
