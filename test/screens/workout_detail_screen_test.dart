import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/screens/workout_detail_screen.dart';
import 'package:zenith/services/workout_service.dart';

// Reuse generated mocks from existing tests
import '../services/workout_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutDetailScreen - Mood', () {
    testWidgets('renders persisted mood instead of neutral fallback', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final workout = Workout(
        id: 'mood-workout',
        name: 'Mood Session',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(const Duration(hours: 1)),
        completedAt: now,
        mood: 5,
        exercises: const [],
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutDetailScreen(workout: workout)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mood: Excellent'), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_very_satisfied), findsOneWidget);
      expect(find.text('Mood: Neutral'), findsNothing);
    });
  });

  group('WorkoutDetailScreen - Delete Workout', () {
    late WorkoutService workoutService;
    late MockWorkoutDao mockWorkoutDao;
    late MockWorkoutExerciseDao mockWorkoutExerciseDao;
    late MockWorkoutSetDao mockWorkoutSetDao;

    setUp(() async {
      // Set up WorkoutService with mocks
      workoutService = WorkoutService.instance;
      mockWorkoutDao = MockWorkoutDao();
      mockWorkoutExerciseDao = MockWorkoutExerciseDao();
      mockWorkoutSetDao = MockWorkoutSetDao();

      // Inject mock DAOs
      workoutService.workoutDao = mockWorkoutDao;
      workoutService.workoutExerciseDao = mockWorkoutExerciseDao;
      workoutService.workoutSetDao = mockWorkoutSetDao;

      // Clear any previous state
      workoutService.workouts.clear();
    });

    testWidgets(
      'pressing Delete deletes workout and cascades sets/exercises via DAOs and pops with result',
      (WidgetTester tester) async {
        // Arrange: completed workout with minimal data
        final now = DateTime.now();
        final workout = Workout(
          id: 'w1',
          name: 'Completed Session',
          status: WorkoutStatus.completed,
          startedAt: now.subtract(const Duration(hours: 2)),
          completedAt: now.subtract(const Duration(hours: 1)),
          exercises: const [],
        );

        // DAO expectations: delete sets by exercise, then exercises by workout, then workout
        final exercise = WorkoutExercise(
          id: 'e1',
          workoutId: 'w1',
          exerciseSlug: 'bench-press',
          sets: const [],
        );

        when(
          mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('w1'),
        ).thenAnswer((_) async => [exercise]);

        when(
          mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('e1'),
        ).thenAnswer((_) async => 1);

        when(
          mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId('w1'),
        ).thenAnswer((_) async => 1);

        when(mockWorkoutDao.deleteWorkout('w1')).thenAnswer((_) async => 1);

        // Act: pump screen and tap Delete then confirm
        await tester.pumpWidget(
          MaterialApp(home: WorkoutDetailScreen(workout: workout)),
        );
        await tester.pumpAndSettle();

        // Tap the "Delete Workout" button
        expect(find.text('Delete Workout'), findsOneWidget);
        await tester.ensureVisible(find.text('Delete Workout'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete Workout'));
        await tester.pumpAndSettle();

        // Dialog appears, confirm deletion
        expect(find.text('Delete Workout?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Assert: DAO deletions executed in cascade
        verify(
          mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('w1'),
        ).called(1);
        verify(
          mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('e1'),
        ).called(1);
        verify(
          mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId('w1'),
        ).called(1);
        verify(mockWorkoutDao.deleteWorkout('w1')).called(1);
      },
    );
  });

  group('WorkoutDetailScreen - Set Details', () {
    testWidgets('renders goal and actual values for completed sets', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final workout = Workout(
        id: 'w-detail',
        name: 'Detailed Session',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(const Duration(hours: 2)),
        completedAt: now,
        exercises: [
          WorkoutExercise(
            id: 'exercise-1',
            workoutId: 'w-detail',
            exerciseSlug: 'bench-press',
            sets: [
              WorkoutSet(
                workoutExerciseId: 'exercise-1',
                setIndex: 0,
                targetReps: 8,
                targetWeight: 80.0,
                actualReps: 6,
                actualWeight: 82.5,
                isCompleted: true,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutDetailScreen(workout: workout)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText() == 'Goal: 8 reps @ 80.0 kg',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText() == 'Actual: 6 reps @ 82.5 kg',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders workout notes when present', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final workout = Workout(
        id: 'notes-workout',
        name: 'Notes Session',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(const Duration(hours: 2)),
        completedAt: now,
        notes: 'Focus on controlled tempo',
        exercises: const [],
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutDetailScreen(workout: workout)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Focus on controlled tempo'), findsOneWidget);
    });
  });
}
