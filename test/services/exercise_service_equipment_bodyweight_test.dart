import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/dao/exercise_dao.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';
import 'package:zenith/services/exercise_service.dart';

// Reuse generated mocks from existing test
import 'exercise_service_test.mocks.dart';

void main() {
  group('ExerciseService Equipment & Bodyweight Extensions', () {
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
          instructions: ['Lie on bench', 'Press bar up'],
          equipment: 'Barbell',
          image: 'bench_press.jpg',
          animation: 'bench_press.gif',
          isBodyWeightExercise: false,
        ),
        Exercise(
          slug: 'push-up',
          name: 'Push Up',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [MuscleGroup.triceps, MuscleGroup.shoulders],
          instructions: ['Place hands on floor', 'Push body up'],
          equipment: 'None',
          image: 'pushup.jpg',
          animation: 'pushup.gif',
          isBodyWeightExercise: true,
        ),
        Exercise(
          slug: 'squat',
          name: 'Squat',
          primaryMuscleGroup: MuscleGroup.quads,
          secondaryMuscleGroups: [MuscleGroup.glutes, MuscleGroup.hamstrings],
          instructions: ['Stand with feet shoulder-width apart', 'Squat down'],
          equipment: 'None',
          image: 'squat.jpg',
          animation: 'squat.gif',
          isBodyWeightExercise: true,
        ),
        Exercise(
          slug: 'deadlift',
          name: 'Deadlift',
          primaryMuscleGroup: MuscleGroup.back,
          secondaryMuscleGroups: [MuscleGroup.hamstrings, MuscleGroup.glutes],
          instructions: ['Stand with feet hip-width apart', 'Lift bar from ground'],
          equipment: 'Barbell',
          image: 'deadlift.jpg',
          animation: 'deadlift.gif',
          isBodyWeightExercise: false,
        ),
      ];

      testMuscleGroups = [
        MuscleGroup.chest,
        MuscleGroup.triceps,
        MuscleGroup.quads,
        MuscleGroup.glutes,
        MuscleGroup.back,
        MuscleGroup.hamstrings,
        MuscleGroup.shoulders,
      ];

      exerciseService = ExerciseService.withDependencies(
        exerciseDao: mockExerciseDao,
        muscleGroupDao: mockMuscleGroupDao,
      );

      when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
      when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);

      await exerciseService.loadExercises();
    });

    group('searchExercises enhancements', () {
      test('should match equipment in search query (e.g., "barbell")', () {
        final resultLower = exerciseService.searchExercises('barbell');
        final resultUpper = exerciseService.searchExercises('BARBELL');
        expect(resultLower.map((e) => e.slug).toSet(), equals({'bench-press', 'deadlift'}));
        expect(resultUpper.map((e) => e.slug).toSet(), equals({'bench-press', 'deadlift'}));
      });

      test('should match "bodyweight" keyword in search query', () {
        final result = exerciseService.searchExercises('bodyweight');
        expect(result.map((e) => e.slug).toSet(), equals({'push-up', 'squat'}));
      });
    });

    group('filterByEquipment', () {
      test('should filter by equipment "Barbell" (case-insensitive)', () {
        final res1 = exerciseService.filterByEquipment('Barbell');
        final res2 = exerciseService.filterByEquipment('barbell');
        expect(res1.map((e) => e.slug).toSet(), equals({'bench-press', 'deadlift'}));
        expect(res2.map((e) => e.slug).toSet(), equals({'bench-press', 'deadlift'}));
      });

      test('should filter by equipment "None"', () {
        final res = exerciseService.filterByEquipment('None');
        expect(res.map((e) => e.slug).toSet(), equals({'push-up', 'squat'}));
      });

      test('should return all when equipment is empty or whitespace', () {
        expect(exerciseService.filterByEquipment(''), hasLength(4));
        expect(exerciseService.filterByEquipment('   '), hasLength(4));
      });
    });

    group('filterByBodyweight', () {
      test('should filter bodyweight == true', () {
        final res = exerciseService.filterByBodyweight(true);
        expect(res.map((e) => e.slug).toSet(), equals({'push-up', 'squat'}));
      });

      test('should filter bodyweight == false', () {
        final res = exerciseService.filterByBodyweight(false);
        expect(res.map((e) => e.slug).toSet(), equals({'bench-press', 'deadlift'}));
      });

      test('should return all when flag is null', () {
        final res = exerciseService.filterByBodyweight(null);
        expect(res, hasLength(4));
      });
    });
  });
}
