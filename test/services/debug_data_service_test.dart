import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';
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
}

class FakeWorkoutSetDao extends WorkoutSetDao {
  final List<WorkoutSet> insertedSets = [];

  @override
  Future<int> insert(WorkoutSet model) async {
    insertedSets.add(model);
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
    late int loadExercisesCallCount;
    late int refreshWorkoutDataCallCount;

    setUp(() {
      service = DebugDataService.instance;
      service.resetForTesting();

      workoutDao = FakeWorkoutDao();
      workoutExerciseDao = FakeWorkoutExerciseDao();
      workoutSetDao = FakeWorkoutSetDao();
      loadExercisesCallCount = 0;
      refreshWorkoutDataCallCount = 0;

      service.workoutDao = workoutDao;
      service.workoutExerciseDao = workoutExerciseDao;
      service.workoutSetDao = workoutSetDao;
      service.loadExercises = () async {
        loadExercisesCallCount++;
      };
      service.refreshWorkoutData = () async {
        refreshWorkoutDataCallCount++;
      };
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
        expect(workoutDao.insertedWorkouts, isNotEmpty);
        expect(
          workoutDao.insertedWorkouts.map((workout) => workout.name),
          everyElement('Custom Day'),
        );
        expect(
          workoutDao.insertedWorkouts.map((workout) => workout.status),
          everyElement(WorkoutStatus.completed),
        );

        final exercisesByWorkoutId = <String, List<WorkoutExercise>>{};
        for (final exercise in workoutExerciseDao.insertedExercises) {
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
        expect(workoutSetDao.insertedSets.any((set) => !set.isCompleted), isTrue);
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

        final benchExerciseIds = workoutExerciseDao.insertedExercises
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

        final earlyAverageWeight = benchSets
                .take(10)
                .fold<double>(0, (sum, set) => sum + set.actualWeight!) /
            10;
        final lateAverageWeight = benchSets
                .skip(benchSets.length - 10)
                .fold<double>(0, (sum, set) => sum + set.actualWeight!) /
            10;
        expect(lateAverageWeight, greaterThan(earlyAverageWeight));
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
  });
}
