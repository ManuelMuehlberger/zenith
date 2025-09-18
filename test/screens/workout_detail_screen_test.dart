import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/services/workout_service.dart';
import 'package:zenith/screens/workout_detail_screen.dart';

// Reuse generated mocks from existing tests
import '../services/workout_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    testWidgets('pressing Delete deletes workout and cascades sets/exercises via DAOs and pops with result', (WidgetTester tester) async {
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

      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('w1'))
          .thenAnswer((_) async => [exercise]);

      when(mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('e1'))
          .thenAnswer((_) async => 1);

      when(mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId('w1'))
          .thenAnswer((_) async => 1);

      when(mockWorkoutDao.deleteWorkout('w1'))
          .thenAnswer((_) async => 1);

      // Act: pump screen and tap Delete then confirm
      await tester.pumpWidget(MaterialApp(home: WorkoutDetailScreen(workout: workout)));
      await tester.pumpAndSettle();

      // Tap the "Delete Workout" button
      expect(find.text('Delete Workout'), findsOneWidget);
      await tester.tap(find.text('Delete Workout'));
      await tester.pumpAndSettle();

      // Dialog appears, confirm deletion
      expect(find.text('Delete Workout?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Assert: DAO deletions executed in cascade
      verify(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId('w1')).called(1);
      verify(mockWorkoutSetDao.deleteWorkoutSetsByWorkoutExerciseId('e1')).called(1);
      verify(mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutId('w1')).called(1);
      verify(mockWorkoutDao.deleteWorkout('w1')).called(1);
    });
  });
}
