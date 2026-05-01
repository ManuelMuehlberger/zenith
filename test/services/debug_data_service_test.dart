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
  }) : _nextInts = List<int>.from(nextInts),
       _nextDoubles = List<double>.from(nextDoubles);

  final List<int> _nextInts;
  final List<double> _nextDoubles;
  int _nextIntIndex = 0;
  int _nextDoubleIndex = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() {
    if (_nextDoubleIndex >= _nextDoubles.length) {
      throw StateError('No queued nextDouble value available');
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
      throw StateError('No queued nextInt value available for max $max');
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

    setUp(() {
      service = DebugDataService.instance;
      service.resetForTesting();

      workoutDao = FakeWorkoutDao();
      workoutExerciseDao = FakeWorkoutExerciseDao();
      workoutSetDao = FakeWorkoutSetDao();
      loadExercisesCallCount = 0;

      service.workoutDao = workoutDao;
      service.workoutExerciseDao = workoutExerciseDao;
      service.workoutSetDao = workoutSetDao;
      service.loadExercises = () async {
        loadExercisesCallCount++;
      };
    });

    tearDown(() {
      service.resetForTesting();
    });

    test(
      'generateDebugData loads exercises and creates predictable workout data',
      () async {
        service.weeksToGenerate = 1;
        service.nowProvider = () => DateTime(2025, 1, 15, 12);
        service.workoutTemplatesForTesting = [
          {
            'name': 'Custom Day',
            'exercises': [
              {'slug': 'bench-press', 'baseWeight': 60.0, 'baseReps': 8},
              {'slug': 'pull-up', 'baseWeight': 0.0, 'baseReps': 5},
            ],
          },
        ];
        service.random = SequenceRandom(
          nextInts: [
            0,
            1,
            1,
            3,
            5,
            0,
            0,
            30,
            10,
            1,
            1,
            1,
            1,
            1,
            1,
            0,
            0,
            30,
            10,
            1,
            1,
            1,
            1,
            1,
            1,
            0,
            0,
            30,
            10,
            1,
            1,
            1,
            1,
            1,
            1,
          ],
          nextDoubles: List<double>.filled(18, 0.5),
        );

        await service.generateDebugData();

        expect(loadExercisesCallCount, 1);
        expect(workoutDao.insertedWorkouts, hasLength(3));
        expect(workoutExerciseDao.insertedExercises, hasLength(6));
        expect(workoutSetDao.insertedSets, hasLength(18));

        expect(
          workoutDao.insertedWorkouts.map((workout) => workout.name),
          everyElement('Custom Day'),
        );
        expect(
          workoutDao.insertedWorkouts.map((workout) => workout.status),
          everyElement(WorkoutStatus.completed),
        );
        expect(
          workoutDao.insertedWorkouts.map((workout) => workout.completedAt),
          [
            DateTime(2025, 1, 9, 6, 30),
            DateTime(2025, 1, 11, 6, 30),
            DateTime(2025, 1, 13, 6, 30),
          ],
        );
        expect(
          workoutDao.insertedWorkouts.map((workout) => workout.startedAt),
          [
            DateTime(2025, 1, 9, 5, 35),
            DateTime(2025, 1, 11, 5, 35),
            DateTime(2025, 1, 13, 5, 35),
          ],
        );

        final exercisesByWorkoutId = <String, List<WorkoutExercise>>{};
        for (final exercise in workoutExerciseDao.insertedExercises) {
          exercisesByWorkoutId
              .putIfAbsent(exercise.workoutId!, () => [])
              .add(exercise);
        }

        for (final workout in workoutDao.insertedWorkouts) {
          final exercises = exercisesByWorkoutId[workout.id];
          expect(exercises, isNotNull);
          expect(exercises, hasLength(2));
          expect(exercises!.map((exercise) => exercise.orderIndex), [0, 1]);
          expect(exercises.map((exercise) => exercise.exerciseSlug), [
            'bench-press',
            'pull-up',
          ]);
        }

        final setsByExerciseId = <String, List<WorkoutSet>>{};
        for (final set in workoutSetDao.insertedSets) {
          setsByExerciseId
              .putIfAbsent(set.workoutExerciseId, () => [])
              .add(set);
        }

        for (final exercise in workoutExerciseDao.insertedExercises) {
          final sets = setsByExerciseId[exercise.id];
          expect(sets, isNotNull);
          expect(sets, hasLength(3));
          expect(sets!.map((set) => set.setIndex), [0, 1, 2]);
          expect(sets.map((set) => set.isCompleted), everyElement(isTrue));

          if (exercise.exerciseSlug == 'bench-press') {
            expect(sets.map((set) => set.targetWeight), everyElement(60.0));
            expect(sets.map((set) => set.actualWeight), everyElement(60.0));
            expect(sets.map((set) => set.targetReps), everyElement(8));
            expect(sets.map((set) => set.actualReps), everyElement(8));
          } else {
            expect(sets.map((set) => set.targetWeight), everyElement(0.0));
            expect(sets.map((set) => set.actualWeight), everyElement(0.0));
            expect(sets.map((set) => set.targetReps), everyElement(5));
            expect(sets.map((set) => set.actualReps), everyElement(5));
          }
        }
      },
    );

    test(
      'createWorkoutFromTemplateForTesting clamps invalid reps and weight',
      () async {
        service.random = SequenceRandom(
          nextInts: [4, 15, 0, 0, 0, 0],
          nextDoubles: [0.0, 0.0, 0.0],
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
          expect(set.targetReps, 1);
          expect(set.actualReps, 1);
          expect(set.isCompleted, isTrue);
        }
      },
    );
  });
}
