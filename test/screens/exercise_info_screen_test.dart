import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/screens/exercise_image_gallery_screen.dart';
import 'package:zenith/screens/exercise_info_screen.dart';
import 'package:zenith/services/dao/exercise_dao.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';
import 'package:zenith/services/exercise_service.dart';
import 'package:zenith/services/insights_service.dart';
import 'package:zenith/widgets/exercise_info/exercise_image_section.dart';

class _FakeExerciseDao extends ExerciseDao {
  _FakeExerciseDao(this.seed);

  final List<Exercise> seed;

  @override
  Future<List<Exercise>> getAllExercises() async => seed;

  @override
  Future<int> deleteExerciseBySlug(String slug) async {
    seed.removeWhere((exercise) => exercise.slug == slug);
    return 1;
  }
}

class _FakeMuscleGroupDao extends MuscleGroupDao {
  _FakeMuscleGroupDao(this.seed);

  final List<MuscleGroup> seed;

  @override
  Future<List<MuscleGroup>> getAllMuscleGroups() async => seed;
}

Future<void> pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 50),
  int maxTicks = 200,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  await tester.pump();
}

void main() {
  group('ExerciseInfoScreen', () {
    setUp(() {
      // Reset preferences and insights service state before each test
      SharedPreferences.setMockInitialValues({});
      InsightsService.instance.reset();
      ExerciseService.instance.resetForTesting();
    });

    testWidgets('shows info and stats when insights data is available', (
      tester,
    ) async {
      // Arrange: create an exercise and workouts that include this exercise slug
      final exercise = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: const [],
        instructions: const ['Push bar up'],
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

      // Act: pump the screen
      await tester.pumpWidget(
        MaterialApp(home: ExerciseInfoScreen(exercise: exercise)),
      );

      // Check for Info section elements
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget); // Muscle group chip
      // Instructions might be pre-rendered but hidden by SizeTransition
      // expect(find.text('Push bar up'), findsNothing);

      // Expand instructions
      await tester.tap(find.text('Instructions'));
      await tester.pumpAndSettle();
      expect(find.text('Push bar up'), findsOneWidget);

      // Let async insights load finish
      await pumpUntilVisible(tester, find.text('Statistics'));

      // Assert: Stats section is visible
      expect(find.text('Statistics'), findsOneWidget);

      // Check for stat cards (Summary Card)
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Sets'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget); // In summary card

      // Charts are present
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('Max Weight'), findsOneWidget); // Chart title

      // Averages section shown
      expect(find.text('Averages'), findsOneWidget);
      expect(find.text('Weight per Set'), findsOneWidget);
      expect(find.text('Reps per Set'), findsOneWidget);
      expect(find.text('Sets per Session'), findsOneWidget);
    });

    testWidgets('shows empty-state message when no insights data', (
      tester,
    ) async {
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
        MaterialApp(home: ExerciseInfoScreen(exercise: exercise)),
      );

      await pumpUntilVisible(tester, find.text('No data available'));

      // Assert: Empty-state for stats
      expect(find.text('No data available'), findsOneWidget);
      expect(
        find.text('Complete workouts with this exercise to see stats.'),
        findsOneWidget,
      );
    });

    testWidgets('opens fullscreen gallery from the image section', (
      tester,
    ) async {
      final exercise = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: const [],
        instructions: const ['Push bar up'],
        image: 'assets/images/bench_press.png',
        animation: '',
      );

      InsightsService.instance.setWorkoutsProvider(() async => []);

      await tester.pumpWidget(
        MaterialApp(home: ExerciseInfoScreen(exercise: exercise)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseImageSection));
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseImageGalleryScreen), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('shows timeframe selector', (tester) async {
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

      // No workouts necessary to test the selector presence
      InsightsService.instance.setWorkoutsProvider(() async => []);

      await tester.pumpWidget(
        MaterialApp(home: ExerciseInfoScreen(exercise: exercise)),
      );

      // Initial shows "6M" button (default)
      await pumpUntilVisible(tester, find.text('6M'));
      expect(find.text('6M'), findsOneWidget);

      // Note: Testing PullDownButton interaction in widget tests can be complex due to overlays
      // We verify the button exists and has the correct initial label
    });

    testWidgets('custom exercise can be deleted from the info screen', (
      tester,
    ) async {
      final customExercise = Exercise(
        slug: 'custom-tempo-run',
        name: 'Tempo Run',
        primaryMuscleGroup: MuscleGroup.legs,
        secondaryMuscleGroups: const [MuscleGroup.glutes],
        instructions: const ['Run steadily'],
        image: '',
        animation: '',
        isCustom: true,
        type: ExerciseType.cardio,
        isBodyWeightExercise: true,
      );
      final exercises = [customExercise];
      ExerciseService.instance.setDependenciesForTesting(
        exerciseDao: _FakeExerciseDao(exercises),
        muscleGroupDao: _FakeMuscleGroupDao(MuscleGroup.values.toList()),
        seedExercises: exercises,
        seedMuscleGroups: MuscleGroup.values
            .map((group) => group.name)
            .toList(),
      );
      InsightsService.instance.setWorkoutsProvider(() async => []);

      await tester.pumpWidget(
        MaterialApp(home: ExerciseInfoScreen(exercise: customExercise)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Exercise actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
        ExerciseService.instance.exercises.any(
          (exercise) => exercise.slug == customExercise.slug,
        ),
        isFalse,
      );
    });
  });
}
