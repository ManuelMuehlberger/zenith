import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/models/workout_template.dart';
import 'package:zenith/services/dao/weight_entry_dao.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';
import 'package:zenith/services/dao/workout_template_dao.dart';
import 'package:zenith/services/debug_data_service.dart';

class FakeWorkoutDao extends WorkoutDao {
  final List<Workout> insertedWorkouts = [];

  @override
  Future<int> insert(Workout workout) async {
    insertedWorkouts.add(workout);
    return 1;
  }
}

class FakeWorkoutExerciseDao extends WorkoutExerciseDao {
  final List<WorkoutExercise> insertedExercises = [];

  @override
  Future<int> insert(WorkoutExercise model) async {
    insertedExercises.add(model);
    return 1;
  }

  @override
  Future<List<WorkoutExercise>> getWorkoutExercisesByWorkoutTemplateId(
    String workoutTemplateId,
  ) async {
    return insertedExercises
        .where((exercise) => exercise.workoutTemplateId == workoutTemplateId)
        .toList();
  }
}

class FakeWorkoutSetDao extends WorkoutSetDao {
  final List<WorkoutSet> insertedSets = [];

  @override
  Future<int> insert(WorkoutSet model) async {
    insertedSets.add(model);
    return 1;
  }
}

class FakeWorkoutTemplateDao extends WorkoutTemplateDao {
  final List<WorkoutTemplate> insertedTemplates = [];

  @override
  Future<int> insert(WorkoutTemplate model) async {
    insertedTemplates.add(model);
    return 1;
  }

  @override
  Future<List<WorkoutTemplate>> getAllWorkoutTemplatesOrdered() async {
    return List<WorkoutTemplate>.from(insertedTemplates);
  }
}

class FakeWeightEntryDao extends WeightEntryDao {
  final List<(String userId, WeightEntry entry)> insertedWeightEntries = [];

  @override
  Future<int> addWeightEntryForUser(
    String userDataId,
    WeightEntry weightEntry,
  ) async {
    insertedWeightEntries.add((userDataId, weightEntry));
    return 1;
  }
}

class SequenceRandom implements Random {
  SequenceRandom({
    List<int> nextInts = const [],
    List<double> nextDoubles = const [],
    this.fallbackInt = 0,
    this.fallbackDouble = 0.5,
  }) : _nextInts = List<int>.from(nextInts),
       _nextDoubles = List<double>.from(nextDoubles);

  final List<int> _nextInts;
  final List<double> _nextDoubles;
  final int fallbackInt;
  final double fallbackDouble;
  int _nextIntIndex = 0;
  int _nextDoubleIndex = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() {
    if (_nextDoubleIndex >= _nextDoubles.length) {
      return fallbackDouble;
    }

    final value = _nextDoubles[_nextDoubleIndex++];
    if (value < 0 || value >= 1) {
      throw StateError('Queued nextDouble value must be in [0, 1)');
    }
    return value;
  }

  @override
  int nextInt(int max) {
    if (_nextIntIndex >= _nextInts.length) {
      return fallbackInt % max;
    }

    final value = _nextInts[_nextIntIndex++];
    if (value < 0 || value >= max) {
      throw StateError('Queued nextInt value $value is invalid for max $max');
    }
    return value;
  }
}

void main() {
  group('DebugDataService', () {
    late DebugDataService service;
    late FakeWorkoutDao workoutDao;
    late FakeWorkoutExerciseDao workoutExerciseDao;
    late FakeWorkoutSetDao workoutSetDao;
    late FakeWorkoutTemplateDao workoutTemplateDao;
    late FakeWeightEntryDao weightEntryDao;
    late int loadExercisesCallCount;
    late int refreshWorkoutDataCallCount;
    late int refreshUserProfileCallCount;

    setUp(() {
      service = DebugDataService.instance;
      service.resetForTesting();

      workoutDao = FakeWorkoutDao();
      workoutExerciseDao = FakeWorkoutExerciseDao();
      workoutSetDao = FakeWorkoutSetDao();
      workoutTemplateDao = FakeWorkoutTemplateDao();
      weightEntryDao = FakeWeightEntryDao();
      loadExercisesCallCount = 0;
      refreshWorkoutDataCallCount = 0;
      refreshUserProfileCallCount = 0;

      service.workoutDao = workoutDao;
      service.workoutExerciseDao = workoutExerciseDao;
      service.workoutSetDao = workoutSetDao;
      service.workoutTemplateDao = workoutTemplateDao;
      service.weightEntryDao = weightEntryDao;
      service.loadExercises = () async {
        loadExercisesCallCount++;
      };
      service.refreshWorkoutData = () async {
        refreshWorkoutDataCallCount++;
      };
      service.refreshUserProfile = () async {
        refreshUserProfileCallCount++;
      };
      service.currentProfileProvider = () => null;
    });

    tearDown(() {
      service.resetForTesting();
    });

    test(
      'generateDebugData creates varied two-year-style history with progression',
      () async {
        service.weeksToGenerate = 24;
        service.nowProvider = () => DateTime(2025, 1, 15, 12);
        service.workoutTemplatesForTesting = [
          {
            'name': 'Custom Day',
            'exercises': [
              {'slug': 'bench-press', 'baseWeight': 60.0, 'baseReps': 8},
              {'slug': 'pull-up', 'baseWeight': 0.0, 'baseReps': 5},
            ],
            'optionalExercises': [
              {'slug': 'push-up', 'baseWeight': 0.0, 'baseReps': 12},
            ],
          },
        ];
        service.random = Random(42);

        await service.generateDebugData();

        expect(loadExercisesCallCount, 1);
        expect(refreshWorkoutDataCallCount, 1);
        expect(refreshUserProfileCallCount, 0);
        expect(workoutTemplateDao.insertedTemplates, hasLength(1));
        expect(workoutDao.insertedWorkouts, isNotEmpty);
        expect(weightEntryDao.insertedWeightEntries, isEmpty);
        expect(
          workoutDao.insertedWorkouts.map((workout) => workout.name),
          everyElement('Custom Day'),
        );
        expect(
          workoutDao.insertedWorkouts.map((workout) => workout.status),
          everyElement(WorkoutStatus.completed),
        );

        final historyExercises = workoutExerciseDao.insertedExercises
            .where((exercise) => exercise.workoutId != null)
            .toList();
        final exercisesByWorkoutId = <String, List<WorkoutExercise>>{};
        for (final exercise in historyExercises) {
          exercisesByWorkoutId
              .putIfAbsent(exercise.workoutId!, () => [])
              .add(exercise);
        }

        final setsByExerciseId = <String, List<WorkoutSet>>{};
        for (final set in workoutSetDao.insertedSets) {
          setsByExerciseId
              .putIfAbsent(set.workoutExerciseId, () => [])
              .add(set);
        }

        final exerciseCounts = workoutDao.insertedWorkouts
            .map((workout) => exercisesByWorkoutId[workout.id]?.length ?? 0)
            .toList();
        expect(exerciseCounts.any((count) => count > 2), isTrue);

        final completedSets = workoutSetDao.insertedSets
            .where((set) => set.isCompleted)
            .toList();
        expect(completedSets, isNotEmpty);
        expect(
          workoutSetDao.insertedSets.any((set) => !set.isCompleted),
          isTrue,
        );
        expect(
          completedSets.any(
            (set) =>
                (set.actualWeight ?? 0) > (set.targetWeight ?? 0) ||
                (set.actualReps ?? 0) > (set.targetReps ?? 0),
          ),
          isTrue,
        );
        expect(
          completedSets.any(
            (set) =>
                (set.actualWeight ?? 0) < (set.targetWeight ?? 0) ||
                (set.actualReps ?? 0) < (set.targetReps ?? 0),
          ),
          isTrue,
        );

        final benchExerciseIds = historyExercises
            .where((exercise) => exercise.exerciseSlug == 'bench-press')
            .map((exercise) => exercise.id)
            .toSet();
        final benchSets = workoutSetDao.insertedSets
            .where(
              (set) =>
                  benchExerciseIds.contains(set.workoutExerciseId) &&
                  set.isCompleted &&
                  set.actualWeight != null,
            )
            .toList();
        expect(benchSets.length, greaterThan(10));

        final earlyAverageWeight =
            benchSets
                .take(10)
                .fold<double>(0, (sum, set) => sum + set.actualWeight!) /
            10;
        final lateAverageWeight =
            benchSets
                .skip(benchSets.length - 10)
                .fold<double>(0, (sum, set) => sum + set.actualWeight!) /
            10;
        expect(lateAverageWeight, greaterThan(earlyAverageWeight));

        final seededTemplate = workoutTemplateDao.insertedTemplates.single;
        final templateExercises = workoutExerciseDao.insertedExercises
            .where(
              (exercise) => exercise.workoutTemplateId == seededTemplate.id,
            )
            .toList();
        expect(templateExercises, hasLength(3));
        expect(templateExercises.map((exercise) => exercise.exerciseSlug), [
          'bench-press',
          'pull-up',
          'push-up',
        ]);

        final templateSets = workoutSetDao.insertedSets.where(
          (set) => templateExercises.any(
            (exercise) => exercise.id == set.workoutExerciseId,
          ),
        );
        expect(templateSets.where((set) => set.isCompleted), isEmpty);
      },
    );

    test(
      'generateDebugData can pause for a full week before resuming training',
      () async {
        service.weeksToGenerate = 2;
        service.nowProvider = () => DateTime(2025, 1, 15, 12);
        service.workoutTemplatesForTesting = [
          {
            'name': 'Custom Day',
            'exercises': [
              {'slug': 'bench-press', 'baseWeight': 60.0, 'baseReps': 8},
            ],
            'optionalExercises': [
              {'slug': 'push-up', 'baseWeight': 0.0, 'baseReps': 15},
            ],
          },
        ];
        service.random = SequenceRandom(
          nextInts: [0, 0, 2, 4],
          nextDoubles: [0.01, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9],
        );

        await service.generateDebugData();

        expect(loadExercisesCallCount, 1);
        expect(refreshWorkoutDataCallCount, 1);
        expect(workoutDao.insertedWorkouts, hasLength(3));
        expect(weightEntryDao.insertedWeightEntries, isEmpty);
        expect(
          workoutDao.insertedWorkouts.map((workout) => workout.startedAt!.day),
          [8, 10, 12],
        );
        expect(
          workoutDao.insertedWorkouts.every(
            (workout) => workout.startedAt!.isAfter(DateTime(2025, 1, 1)),
          ),
          isTrue,
        );
      },
    );

    test('generateDebugData does not duplicate persisted templates', () async {
      service.weeksToGenerate = 1;
      service.nowProvider = () => DateTime(2025, 1, 15, 12);
      service.workoutTemplatesForTesting = [
        {
          'name': 'Push Day',
          'exercises': [
            {'slug': 'bench-press', 'baseWeight': 60.0, 'baseReps': 8},
          ],
          'optionalExercises': [
            {'slug': 'push-up', 'baseWeight': 0.0, 'baseReps': 15},
          ],
        },
      ];
      service.random = Random(7);

      await service.generateDebugData();
      await service.generateDebugData();

      expect(workoutTemplateDao.insertedTemplates, hasLength(1));

      final template = workoutTemplateDao.insertedTemplates.single;
      final templateExercises = workoutExerciseDao.insertedExercises
          .where((exercise) => exercise.workoutTemplateId == template.id)
          .toList();
      expect(templateExercises, hasLength(2));
      expect(weightEntryDao.insertedWeightEntries, isEmpty);
    });

    test(
      'createWorkoutFromTemplateForTesting clamps invalid reps and weight',
      () async {
        service.random = SequenceRandom(
          nextInts: [4, 15, 0],
          nextDoubles: List<double>.filled(12, 0.9),
        );

        await service.createWorkoutFromTemplateForTesting({
          'name': 'Guard Day',
          'exercises': [
            {'slug': 'edge-case-exercise', 'baseWeight': -10.0, 'baseReps': 1},
          ],
        }, DateTime(2025, 2, 20));

        expect(workoutDao.insertedWorkouts, hasLength(1));
        expect(workoutExerciseDao.insertedExercises, hasLength(1));
        expect(workoutSetDao.insertedSets, hasLength(3));

        final workout = workoutDao.insertedWorkouts.single;
        expect(workout.name, 'Guard Day');
        expect(workout.completedAt, DateTime(2025, 2, 20, 10, 15));
        expect(workout.startedAt, DateTime(2025, 2, 20, 9, 30));

        for (final set in workoutSetDao.insertedSets) {
          expect(set.targetWeight, 0.0);
          expect(set.actualWeight, 0.0);
          expect(set.targetReps, greaterThanOrEqualTo(1));
          expect(set.actualReps, greaterThanOrEqualTo(1));
          expect(set.isCompleted, isTrue);
        }
      },
    );

    test(
      'generateDebugData adds weight entries for the active profile',
      () async {
        service.weeksToGenerate = 4;
        service.nowProvider = () => DateTime(2025, 1, 15, 12);
        service.currentProfileProvider = () => UserData(
          id: 'user-1',
          name: 'Tester',
          birthdate: DateTime(1990, 1, 1),
          units: Units.metric,
          weightHistory: [
            WeightEntry(timestamp: DateTime(2024, 12, 31), value: 74.0),
          ],
          createdAt: DateTime(2024, 1, 1),
          theme: 'system',
        );
        service.workoutTemplatesForTesting = [
          {
            'name': 'Custom Day',
            'exercises': [
              {'slug': 'bench-press', 'baseWeight': 60.0, 'baseReps': 8},
            ],
          },
        ];
        service.random = Random(10);

        await service.generateDebugData();

        expect(refreshWorkoutDataCallCount, 1);
        expect(refreshUserProfileCallCount, 1);
        expect(
          weightEntryDao.insertedWeightEntries,
          hasLength(workoutDao.insertedWorkouts.length),
        );

        for (int i = 0; i < weightEntryDao.insertedWeightEntries.length; i++) {
          final seededWeight = weightEntryDao.insertedWeightEntries[i];
          final workout = workoutDao.insertedWorkouts[i];

          expect(seededWeight.$1, 'user-1');
          expect(seededWeight.$2.timestamp, workout.completedAt);
          expect(seededWeight.$2.value, greaterThan(0));
        }
      },
    );
  });
}
