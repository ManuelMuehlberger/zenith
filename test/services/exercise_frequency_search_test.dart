import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/exercise_service.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';

// Reuse mocks generated in exercise_service_test.dart
import 'exercise_service_test.mocks.dart';

class MockWorkoutExerciseDao extends Mock implements WorkoutExerciseDao {
  @override
  Future<Map<String, int>> getExerciseFrequency() =>
      super.noSuchMethod(
        Invocation.method(#getExerciseFrequency, []),
        returnValue: Future.value(<String, int>{}),
      ) as Future<Map<String, int>>;
}

void main() {
  group('ExerciseService Frequency Search', () {
    late ExerciseService exerciseService;
    late MockExerciseDao mockExerciseDao;
    late MockMuscleGroupDao mockMuscleGroupDao;
    late MockWorkoutExerciseDao mockWorkoutExerciseDao;

    late List<Exercise> testExercises;
    late List<MuscleGroup> testMuscleGroups;

    setUp(() async {
      mockExerciseDao = MockExerciseDao();
      mockMuscleGroupDao = MockMuscleGroupDao();
      mockWorkoutExerciseDao = MockWorkoutExerciseDao();

      testExercises = [
        Exercise(
          slug: 'bench-press',
          name: 'Bench Press',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [MuscleGroup.triceps],
          instructions: const ['Press'],
          image: '',
          animation: '',
          isBodyWeightExercise: false,
          equipment: 'Barbell',
        ),
        Exercise(
          slug: 'dumbbell-bench-press',
          name: 'Dumbbell Bench Press',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [MuscleGroup.triceps],
          instructions: const ['Press'],
          image: '',
          animation: '',
          isBodyWeightExercise: false,
          equipment: 'Dumbbell',
        ),
        Exercise(
          slug: 'push-up',
          name: 'Push Up',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: const [],
          instructions: const ['Push'],
          image: '',
          animation: '',
          isBodyWeightExercise: true,
          equipment: 'None',
        ),
      ];

      testMuscleGroups = [
        MuscleGroup.chest,
        MuscleGroup.triceps,
      ];

      when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
      when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);
    });

    test('prioritizes frequently used exercises when scores are equal', () async {
      // Setup frequency: Dumbbell Bench Press used more than Bench Press
      when(mockWorkoutExerciseDao.getExerciseFrequency()).thenAnswer((_) async => {
        'dumbbell-bench-press': 10,
        'bench-press': 5,
      });

      exerciseService = ExerciseService.withDependencies(
        exerciseDao: mockExerciseDao,
        muscleGroupDao: mockMuscleGroupDao,
        workoutExerciseDao: mockWorkoutExerciseDao,
      );

      await exerciseService.loadExercises();

      // Search for "bench press" - both should match well
      // "Bench Press" is a substring of "Dumbbell Bench Press"
      // But "Bench Press" is an exact match for "Bench Press"
      // Wait, "Bench Press" contains "Bench Press", so score is 100.
      // "Dumbbell Bench Press" contains "Bench Press", so score is 100.
      // So they are tied on score. Frequency should break the tie.
      
      final result = exerciseService.searchExercises('bench press');
      
      expect(result.length, greaterThanOrEqualTo(2));
      expect(result[0].name, equals('Dumbbell Bench Press'));
      expect(result[1].name, equals('Bench Press'));
    });

    test('prioritizes frequently used exercises in fuzzy search', () async {
      // Setup frequency: Push Up used more than Bench Press
      when(mockWorkoutExerciseDao.getExerciseFrequency()).thenAnswer((_) async => {
        'push-up': 20,
        'bench-press': 5,
      });

      exerciseService = ExerciseService.withDependencies(
        exerciseDao: mockExerciseDao,
        muscleGroupDao: mockMuscleGroupDao,
        workoutExerciseDao: mockWorkoutExerciseDao,
      );

      await exerciseService.loadExercises();

      // Search for "press"
      // "Bench Press" contains "press" -> score 100
      // "Push Up" does not contain "press" -> score < 100
      // So Bench Press should still win because score takes precedence
      
      final result1 = exerciseService.searchExercises('press');
      expect(result1.first.name, equals('Bench Press')); // Score wins

      // Now let's try a search where scores are likely equal or close
      // "chest" matches both (primary muscle group)
      
      final result2 = exerciseService.searchExercises('chest');
      // Both have "chest" in primary muscle group, so both match via contains -> score 100
      // Push Up has higher frequency (20 vs 5)
      
      expect(result2.first.name, equals('Push Up'));
      // Bench Press frequency is 5, Dumbbell Bench Press is 0.
      // So order: Push Up (20), Bench Press (5), Dumbbell Bench Press (0)
      
      expect(result2[1].name, equals('Bench Press'));
      expect(result2[2].name, equals('Dumbbell Bench Press'));
    });
    
    test('handles empty frequency map gracefully', () async {
      when(mockWorkoutExerciseDao.getExerciseFrequency()).thenAnswer((_) async => {});

      exerciseService = ExerciseService.withDependencies(
        exerciseDao: mockExerciseDao,
        muscleGroupDao: mockMuscleGroupDao,
        workoutExerciseDao: mockWorkoutExerciseDao,
      );

      await exerciseService.loadExercises();

      final result = exerciseService.searchExercises('chest');
      // Default sort order (alphabetical by name)
      // Bench Press, Dumbbell Bench Press, Push Up
      
      expect(result[0].name, equals('Bench Press'));
      expect(result[1].name, equals('Dumbbell Bench Press'));
      expect(result[2].name, equals('Push Up'));
    });
  });
}
