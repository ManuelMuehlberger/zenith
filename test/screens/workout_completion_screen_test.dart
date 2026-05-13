import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/screens/workout_completion_screen.dart';
import 'package:zenith/services/user_service.dart';

void main() {
  group('WorkoutCompletionScreen', () {
    setUp(() {
      UserService.instance.currentProfileForTesting = UserData(
        id: 'user-1',
        name: 'Tester',
        birthdate: DateTime(1990, 1, 1),
        units: Units.metric,
        weightHistory: [
          WeightEntry(timestamp: DateTime(2026, 5, 1), value: 74.2),
        ],
        createdAt: DateTime(2026, 1, 1),
        theme: 'system',
      );
    });

    tearDown(() {
      UserService.instance.resetForTesting();
    });

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

    testWidgets('shows latest weight and opens weight tumbler', (
      WidgetTester tester,
    ) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 1));
      final session = Workout(
        name: 'Weight Log',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutCompletionScreen(session: session)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Latest: 74.2 kg'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('weight_summary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('weight_summary')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('post_workout_weight_picker')),
        findsOneWidget,
      );
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('shows both completion actions', (WidgetTester tester) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 1));
      final session = Workout(
        name: 'Action Check',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutCompletionScreen(session: session)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('back_to_workout_btn')), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });
  });
}
