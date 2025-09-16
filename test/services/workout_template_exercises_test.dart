import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/workout_template_service.dart';

// Reuse existing generated mocks from other test suites to avoid regenerating
import 'export_import_service_test.mocks.dart' as m1; // Provides MockWorkoutExerciseDao, MockWorkoutSetDao
import 'workout_template_service_test.mocks.dart' as m2; // Provides MockWorkoutTemplateDao, MockWorkoutFolderDao

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutTemplateService - Template Exercises', () {
    late WorkoutTemplateService service;
    late m2.MockWorkoutTemplateDao mockTemplateDao;
    late m2.MockWorkoutFolderDao mockFolderDao;
    late m1.MockWorkoutExerciseDao mockWorkoutExerciseDao;
    late m1.MockWorkoutSetDao mockWorkoutSetDao;

    setUp(() {
      mockTemplateDao = m2.MockWorkoutTemplateDao();
      mockFolderDao = m2.MockWorkoutFolderDao();
      mockWorkoutExerciseDao = m1.MockWorkoutExerciseDao();
      mockWorkoutSetDao = m1.MockWorkoutSetDao();

      // Inject all DAOs including exercise/set DAOs
      service = WorkoutTemplateService(
        workoutTemplateDao: mockTemplateDao,
        workoutFolderDao: mockFolderDao,
        workoutExerciseDao: mockWorkoutExerciseDao,
        workoutSetDao: mockWorkoutSetDao,
      );
    });

    test('getTemplateExercises returns exercises with their sets loaded', () async {
      const templateId = 'tpl_1';

      final ex1 = WorkoutExercise(
        id: 'ex_1',
        workoutTemplateId: templateId,
        exerciseSlug: 'bench-press',
        sets: const [],
      );
      final ex2 = WorkoutExercise(
        id: 'ex_2',
        workoutTemplateId: templateId,
        exerciseSlug: 'squat',
        sets: const [],
      );

      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutTemplateId(templateId))
          .thenAnswer((_) async => [ex1, ex2]);

      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId('ex_1'))
          .thenAnswer((_) async => [
                WorkoutSet(
                  id: 's_1',
                  workoutExerciseId: 'ex_1',
                  setIndex: 0,
                  targetReps: 10,
                  targetWeight: 50.0,
                ),
                WorkoutSet(
                  id: 's_2',
                  workoutExerciseId: 'ex_1',
                  setIndex: 1,
                  targetReps: 8,
                  targetWeight: 55.0,
                ),
              ]);

      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId('ex_2'))
          .thenAnswer((_) async => [
                WorkoutSet(
                  id: 's_3',
                  workoutExerciseId: 'ex_2',
                  setIndex: 0,
                  targetReps: 5,
                  targetWeight: 80.0,
                ),
              ]);

      final result = await service.getTemplateExercises(templateId);

      expect(result.length, 2);
      final loadedEx1 = result.firstWhere((e) => e.id == 'ex_1');
      final loadedEx2 = result.firstWhere((e) => e.id == 'ex_2');
      expect(loadedEx1.sets.length, 2);
      expect(loadedEx2.sets.length, 1);

      verify(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutTemplateId(templateId)).called(1);
      verify(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId('ex_1')).called(1);
      verify(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId('ex_2')).called(1);
      verifyZeroInteractions(mockTemplateDao);
    });

    test('saveTemplateExercises replaces existing and inserts provided exercises and sets in order', () async {
      const templateId = 'tpl_2';

      // Two exercises each with sets
      final newEx1 = WorkoutExercise(
        id: 'new_ex_1',
        workoutTemplateId: 'PENDING', // will be overridden inside service
        exerciseSlug: 'overhead-press',
        sets: [
          WorkoutSet(
            id: 'new_s_1',
            workoutExerciseId: 'new_ex_1',
            setIndex: 0,
            targetReps: 8,
            targetWeight: 40.0,
          ),
          WorkoutSet(
            id: 'new_s_2',
            workoutExerciseId: 'new_ex_1',
            setIndex: 1,
            targetReps: 8,
            targetWeight: 40.0,
          ),
        ],
      );

      final newEx2 = WorkoutExercise(
        id: 'new_ex_2',
        workoutTemplateId: 'PENDING',
        exerciseSlug: 'pull-up',
        sets: [
          WorkoutSet(
            id: 'new_s_3',
            workoutExerciseId: 'new_ex_2',
            setIndex: 0,
            targetReps: 10,
            targetWeight: 0.0,
          ),
        ],
      );

      when(mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutTemplateId(templateId))
          .thenAnswer((_) async => 1);

      when(mockWorkoutExerciseDao.insert(any)).thenAnswer((_) async => 1);
      when(mockWorkoutSetDao.insert(any)).thenAnswer((_) async => 1);

      await service.saveTemplateExercises(templateId, [newEx1, newEx2]);

      // Deleted old template exercises
      verify(mockWorkoutExerciseDao.deleteWorkoutExercisesByWorkoutTemplateId(templateId)).called(1);

      // Capture inserted exercises
      final insertedExVerification = verify(mockWorkoutExerciseDao.insert(captureAny));
      insertedExVerification.called(2);
      final insertedExercises = insertedExVerification.captured.cast<WorkoutExercise>();

      expect(insertedExercises.length, 2);
      // orderIndex should be assigned 0..n and templateId set, workoutId cleared
      expect(insertedExercises[0].orderIndex, 0);
      expect(insertedExercises[0].workoutTemplateId, templateId);
      expect(insertedExercises[0].workoutId, isNull);
      expect(insertedExercises[1].orderIndex, 1);
      expect(insertedExercises[1].workoutTemplateId, templateId);
      expect(insertedExercises[1].workoutId, isNull);

      // Capture inserted sets (3 total)
      final insertedSetVerification = verify(mockWorkoutSetDao.insert(captureAny));
      insertedSetVerification.called(3);
      final insertedSets = insertedSetVerification.captured.cast<WorkoutSet>();

      expect(insertedSets.length, 3);

      // Sets are reindexed by service: 0..n for each exercise and linked via workoutExerciseId.
      // IDs are regenerated server-side, so link sets to the inserted exercises by slug.
      final idsBySlug = {for (final e in insertedExercises) e.exerciseSlug: e.id};
      final ex1Id = idsBySlug['overhead-press'];
      final ex2Id = idsBySlug['pull-up'];
      expect(ex1Id, isNotNull);
      expect(ex2Id, isNotNull);

      final ex1Sets = insertedSets.where((s) => s.workoutExerciseId == ex1Id).toList();
      final ex2Sets = insertedSets.where((s) => s.workoutExerciseId == ex2Id).toList();

      expect(ex1Sets.map((s) => s.setIndex).toList(), [0, 1]);
      expect(ex2Sets.map((s) => s.setIndex).toList(), [0]);

      // Ensure no unexpected interactions with template/folder DAOs in this path
      verifyZeroInteractions(mockTemplateDao);
      verifyZeroInteractions(mockFolderDao);
    });
  });
}
