import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/screens/exercise_info_screen.dart';
import 'package:zenith/services/insights_service.dart';

Future<void> pumpUntilVisible(WidgetTester tester, Finder finder, {Duration step = const Duration(milliseconds: 50), int maxTicks = 200}) async {
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  await tester.pump();
}

void main() {
  group('ExerciseInfoScreen - Stats Tab', () {
    setUp(() {
      // Reset preferences and insights service state before each test
      SharedPreferences.setMockInitialValues({});
      InsightsService.instance.reset();
    });

    testWidgets('shows stats when insights data is available for exercise slug',
        (tester) async {
      // Arrange: create an exercise and workouts that include this exercise slug
      final exercise = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: const [],
        instructions: const [],
        image: '',
        animation: '',
      );

      final workout = Workout(
        id: 'w1',
        name: 'Chest Day',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2025, 1, 10),
        completedAt: DateTime(2025, 1, 10, 1),
        exercises: [
          WorkoutExercise(
            id: 'e1',
            workoutId: 'w1',
            exerciseSlug: 'bench-press',
            sets: [
              WorkoutSet(
                id: 's1',
                workoutExerciseId: 'e1',
                setIndex: 0,
                actualReps: 10,
                actualWeight: 100.0,
                isCompleted: true,
              ),
              WorkoutSet(
                id: 's2',
                workoutExerciseId: 'e1',
                setIndex: 1,
                actualReps: 8,
                actualWeight: 110.0,
                isCompleted: true,
              ),
            ],
          ),
        ],
      );

      // Provide workouts directly to insights service
      InsightsService.instance.setWorkoutsProvider(() async => [workout]);

      // Act: pump the screen with initial tab index = 1 (Stats tab)
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseInfoScreen(
            exercise: exercise,
            initialTabIndex: 1,
          ),
        ),
      );

      // Let async insights load finish (avoid pumpAndSettle to prevent spinner animation timeout)
      await pumpUntilVisible(tester, find.text('Total Sessions'));

      // Assert: Stat cards are visible with correct headers and some values
      expect(find.text('Total Sessions'), findsOneWidget);
      expect(find.text('Total Sets'), findsOneWidget);
      expect(find.text('Total Reps'), findsOneWidget);
      expect(find.text('Max Weight'), findsOneWidget);

      // Charts are present
      expect(find.text('Progress Charts'), findsOneWidget);
      expect(find.text('Monthly Volume'), findsOneWidget);
      expect(find.text('Max Weight Progress'), findsOneWidget);
      expect(find.text('Monthly Frequency'), findsOneWidget);

      // Averages section shown
      expect(find.text('Averages'), findsOneWidget);
      expect(find.text('Average Weight per Set:'), findsOneWidget);
      expect(find.text('Average Reps per Set:'), findsOneWidget);
      expect(find.text('Average Sets per Session:'), findsOneWidget);
    });

    testWidgets('shows empty-state message when no insights data',
        (tester) async {
      // Arrange: exercise with no workout usage
      final exercise = Exercise(
        slug: 'non-existent-exercise',
        name: 'Non Existent',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: const [],
        instructions: const [],
        image: '',
        animation: '',
      );

      InsightsService.instance.setWorkoutsProvider(() async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseInfoScreen(
            exercise: exercise,
            initialTabIndex: 1,
          ),
        ),
      );

      await pumpUntilVisible(
        tester,
        find.text('No workout data found for this exercise in the selected time period'),
      );

      // Assert: Empty-state for stats
      expect(
        find.text(
          'No workout data found for this exercise in the selected time period',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows Cupertino action sheet for time period and updates selection', (tester) async {
      // Arrange
      final exercise = Exercise(
        slug: 'squat',
        name: 'Squat',
        primaryMuscleGroup: MuscleGroup.legs,
        secondaryMuscleGroups: const [],
        instructions: const [],
        image: '',
        animation: '',
      );

      // No workouts necessary to test the sheet behavior
      InsightsService.instance.setWorkoutsProvider(() async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseInfoScreen(
            exercise: exercise,
            initialTabIndex: 1, // Stats tab
          ),
        ),
      );

      // Initial shows "6 months" button
      await pumpUntilVisible(tester, find.text('6 months'));
      expect(find.text('6 months'), findsOneWidget);

      // Open action sheet
      await tester.tap(find.text('6 months'));
      await tester.pump(); // start animation
      await pumpUntilVisible(tester, find.text('Select Time Period'));

      // Select 3 months
      await tester.tap(find.text('3 months'));
      await tester.pump(); // dismiss animation start
      // Allow state update and possible re-fetch
      await tester.pump(const Duration(milliseconds: 200));

      // Button label updated
      expect(find.text('3 months'), findsWidgets);
    });

    testWidgets('segmented control switches between Info and Stats', (tester) async {
      // Arrange with a workout so stats can render when switched
      final exercise = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: const [],
        instructions: const [],
        image: '',
        animation: '',
      );

      final workout = Workout(
        id: 'w1',
        name: 'Chest Day',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2025, 1, 10),
        completedAt: DateTime(2025, 1, 10, 1),
        exercises: [
          WorkoutExercise(
            id: 'e1',
            workoutId: 'w1',
            exerciseSlug: 'bench-press',
            sets: [
              WorkoutSet(
                id: 's1',
                workoutExerciseId: 'e1',
                setIndex: 0,
                actualReps: 10,
                actualWeight: 100.0,
                isCompleted: true,
              ),
            ],
          ),
        ],
      );

      InsightsService.instance.setWorkoutsProvider(() async => [workout]);

      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseInfoScreen(
            exercise: exercise,
            initialTabIndex: 0, // Info tab
          ),
        ),
      );

      // Info tab content visible (look for "Primary" label from muscle groups section)
      await pumpUntilVisible(tester, find.text('Primary'));
      expect(find.text('Primary'), findsOneWidget);

      // Switch to Stats via segmented control
      await tester.tap(find.text('Stats'));
      await tester.pump(const Duration(milliseconds: 100));
      await pumpUntilVisible(tester, find.text('Total Sessions'));

      // Stats visible
      expect(find.text('Total Sessions'), findsOneWidget);
    });
  });
}
