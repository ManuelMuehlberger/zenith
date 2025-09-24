import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/dao/exercise_dao.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';
import 'package:zenith/services/exercise_service.dart';

// Reuse mocks generated in exercise_service_test.dart
import 'exercise_service_test.mocks.dart';

void main() {
  group('ExerciseService Fuzzy Search', () {
    late ExerciseService exerciseService;
    late MockExerciseDao mockExerciseDao;
    late MockMuscleGroupDao mockMuscleGroupDao;

    late List<Exercise> testExercises;
    late List<MuscleGroup> testMuscleGroups;

    setUp(() async {
      mockExerciseDao = MockExerciseDao();
      mockMuscleGroupDao = MockMuscleGroupDao();

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
        Exercise(
          slug: 'plank',
          name: 'Plank',
          primaryMuscleGroup: MuscleGroup.abs,
          secondaryMuscleGroups: const [],
          instructions: const ['Hold'],
          image: '',
          animation: '',
          isBodyWeightExercise: true,
          equipment: 'None',
        ),
        Exercise(
          slug: 'deadlift',
          name: 'Deadlift',
          primaryMuscleGroup: MuscleGroup.back,
          secondaryMuscleGroups: [MuscleGroup.hamstrings, MuscleGroup.glutes],
          instructions: const ['Lift'],
          image: '',
          animation: '',
          isBodyWeightExercise: false,
          equipment: 'Barbell',
        ),
        // Intentional data typo in equipment spelling to test normalization
        Exercise(
          slug: 'biceps-curl',
          name: 'Biceps Curl',
          primaryMuscleGroup: MuscleGroup.biceps,
          secondaryMuscleGroups: const [],
          instructions: const ['Curl'],
          image: '',
          animation: '',
          isBodyWeightExercise: false,
          equipment: 'Dumbell', // note: single 'b'
        ),
      ];

      testMuscleGroups = [
        MuscleGroup.chest,
        MuscleGroup.triceps,
        MuscleGroup.abs,
        MuscleGroup.back,
        MuscleGroup.hamstrings,
        MuscleGroup.glutes,
        MuscleGroup.biceps,
      ];

      when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
      when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);

      exerciseService = ExerciseService.withDependencies(
        exerciseDao: mockExerciseDao,
        muscleGroupDao: mockMuscleGroupDao,
      );

      await exerciseService.loadExercises();
    });

    test('typo tolerance: "puhs up" matches "Push Up"', () {
      final result = exerciseService.searchExercises('puhs up');
      expect(result, isNotEmpty);
      expect(result.first.name, equals('Push Up'));
    });

    test('partial/typo: "bnch prs" ranks "Bench Press" at top', () {
      final result = exerciseService.searchExercises('bnch prs');
      expect(result, isNotEmpty);
      expect(result.first.name, equals('Bench Press'));
    });

    test('equipment normalization: "dumbbell" finds exercise with equipment "Dumbell"', () {
      final result = exerciseService.searchExercises('dumbbell');
      expect(result.map((e) => e.slug), contains('biceps-curl'));
    });

    test('bodyweight keyword (with typo) still surfaces bodyweight exercises', () {
      final result = exerciseService.searchExercises('bodywight');
      // Should include bodyweight exercises like Plank / Push Up
      expect(result.any((e) => e.slug == 'plank' || e.slug == 'push-up'), isTrue);
    });

    test('avoid false positives: "weightlifter" should not match via bodyweight token', () {
      final result = exerciseService.searchExercises('weightlifter');
      // With cutoff 70, this should be empty for our dataset
      expect(result, isEmpty);
    });

    test('contains matches keep priority over fuzzy (query "press")', () {
      // "press" is a strict substring; it should rank Bench Press at the top
      final result = exerciseService.searchExercises('press');
      expect(result, isNotEmpty);
      expect(result.first.name, equals('Bench Press'));
    });

    test('case insensitivity preserved with fuzzy logic', () {
      final r1 = exerciseService.searchExercises('PUSH');
      final r2 = exerciseService.searchExercises('push');
      final r3 = exerciseService.searchExercises('PuSh');
      for (final r in [r1, r2, r3]) {
        expect(r.any((e) => e.name == 'Push Up'), isTrue);
      }
    });
  });
}
