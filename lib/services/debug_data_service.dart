import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import 'dao/workout_dao.dart';
import 'dao/workout_exercise_dao.dart';
import 'dao/workout_set_dao.dart';
import 'exercise_service.dart';

enum _TrainingWeekType { normal, peak, deload, pause }

enum _TrainingDayType { baseline, volume, heavy, peak, bad, deload }

class DebugDataService {
  static final DebugDataService _instance = DebugDataService._internal();
  factory DebugDataService() => _instance;
  DebugDataService._internal();

  static DebugDataService get instance => _instance;

  final Logger _logger = Logger('DebugDataService');
  WorkoutDao _workoutDao = WorkoutDao();
  WorkoutExerciseDao _workoutExerciseDao = WorkoutExerciseDao();
  WorkoutSetDao _workoutSetDao = WorkoutSetDao();
  Random _random = Random();
  Future<void> Function() _loadExercises =
      ExerciseService.instance.loadExercises;
  DateTime Function() _nowProvider = DateTime.now;
  int _weeksToGenerate = 104;

  List<Map<String, dynamic>> _workoutTemplates = _defaultWorkoutTemplates();

  @visibleForTesting
  set workoutDao(WorkoutDao dao) => _workoutDao = dao;

  @visibleForTesting
  set workoutExerciseDao(WorkoutExerciseDao dao) => _workoutExerciseDao = dao;

  @visibleForTesting
  set workoutSetDao(WorkoutSetDao dao) => _workoutSetDao = dao;

  @visibleForTesting
  set random(Random random) => _random = random;

  @visibleForTesting
  set loadExercises(Future<void> Function() callback) =>
      _loadExercises = callback;

  @visibleForTesting
  set nowProvider(DateTime Function() callback) => _nowProvider = callback;

  @visibleForTesting
  set weeksToGenerate(int value) => _weeksToGenerate = value;

  @visibleForTesting
  set workoutTemplatesForTesting(List<Map<String, dynamic>> templates) {
    _workoutTemplates = _cloneTemplates(templates);
  }

  @visibleForTesting
  void resetForTesting() {
    _workoutDao = WorkoutDao();
    _workoutExerciseDao = WorkoutExerciseDao();
    _workoutSetDao = WorkoutSetDao();
    _random = Random();
    _loadExercises = ExerciseService.instance.loadExercises;
    _nowProvider = DateTime.now;
    _weeksToGenerate = 104;
    _workoutTemplates = _defaultWorkoutTemplates();
  }

  Future<void> generateDebugData() async {
    _logger.info('Starting debug data generation...');

    // Ensure exercises are loaded so we can link details if needed (though we mostly use slugs)
    await _loadExercises();

    final now = _startOfDay(_nowProvider());

    for (int weekIndex = 0; weekIndex < _weeksToGenerate; weekIndex++) {
      final progress = _weeksToGenerate <= 1
          ? 1.0
          : weekIndex / (_weeksToGenerate - 1);
      final weekStart = now.subtract(
        Duration(days: (_weeksToGenerate - weekIndex) * 7),
      );
      final weekType = _selectWeekType(progress);
      if (weekType == _TrainingWeekType.pause) {
        continue;
      }

      final workoutsCount = _workoutsForWeek(weekType);
      final dayOffsets = _pickWorkoutDayOffsets(workoutsCount);

      for (final dayOffset in dayOffsets) {
        final workoutDate = weekStart.add(Duration(days: dayOffset));
        final template =
            _workoutTemplates[_random.nextInt(_workoutTemplates.length)];
        final dayType = _selectDayType(weekType, progress);

        await _createWorkoutFromTemplate(
          template,
          workoutDate,
          progress: progress,
          dayType: dayType,
        );
      }
    }

    _logger.info('Debug data generation complete.');
  }

  @visibleForTesting
  Future<void> createWorkoutFromTemplateForTesting(
    Map<String, dynamic> template,
    DateTime date,
  ) => _createWorkoutFromTemplate(
    template,
    date,
    progress: 0.5,
    dayType: _TrainingDayType.baseline,
  );

  Future<void> _createWorkoutFromTemplate(
    Map<String, dynamic> template,
    DateTime date,
    {
      required double progress,
      required _TrainingDayType dayType,
    }
  ) async {
    final workoutId = const Uuid().v4();

    final hour = 6 + _random.nextInt(15);
    final minute = _random.nextInt(60);
    final completedAt = DateTime(date.year, date.month, date.day, hour, minute);
    final durationMinutes = _durationMinutesForDay(dayType);
    final startedAt = completedAt.subtract(Duration(minutes: durationMinutes));

    final workout = Workout(
      id: workoutId,
      name: template['name'] as String,
      status: WorkoutStatus.completed,
      startedAt: startedAt,
      completedAt: completedAt,
      mood: _moodForDay(dayType),
      exercises: [],
    );

    await _workoutDao.insert(workout);

    final templateExercises = _selectExercisesForWorkout(template, dayType);
    final requiredExerciseCount =
        (template['exercises'] as List<dynamic>).length;
    final prExerciseIndex = _prExerciseIndex(dayType, templateExercises.length);

    for (int i = 0; i < templateExercises.length; i++) {
      final exerciseData = templateExercises[i];
      final exerciseId = const Uuid().v4();
      final slug = exerciseData['slug'] as String;
      final baseWeight = exerciseData['baseWeight'] as double;
      final baseReps = exerciseData['baseReps'] as int;

      final workoutExercise = WorkoutExercise(
        id: exerciseId,
        workoutId: workoutId,
        exerciseSlug: slug,
        orderIndex: i,
        sets: [],
      );

      await _workoutExerciseDao.insert(workoutExercise);

      final isAccessory = i >= requiredExerciseCount;
      final plannedSetCount = _plannedSetCount(
        dayType,
        isAccessory: isAccessory,
      );
      final completedSetCount = _completedSetCount(
        dayType,
        plannedSetCount,
      );

      for (int j = 0; j < plannedSetCount; j++) {
        final targetWeight = _targetWeightForSet(
          baseWeight: baseWeight,
          progress: progress,
          dayType: dayType,
          setIndex: j,
          isAccessory: isAccessory,
        );
        final targetReps = _targetRepsForSet(
          baseReps: baseReps,
          progress: progress,
          dayType: dayType,
          setIndex: j,
          isAccessory: isAccessory,
        );
        final performance = _actualPerformanceForSet(
          targetWeight: targetWeight,
          targetReps: targetReps,
          isCompleted: j < completedSetCount,
          isBodyweightExercise: baseWeight <= 0,
          dayType: dayType,
          isPrSet: i == prExerciseIndex &&
              j == 0 &&
              (dayType == _TrainingDayType.peak ||
                  (dayType == _TrainingDayType.heavy && progress > 0.7)),
        );

        final set = WorkoutSet(
          workoutExerciseId: exerciseId,
          setIndex: j,
          targetReps: targetReps,
          targetWeight: targetWeight,
          targetRestSeconds: _targetRestSeconds(dayType),
          actualReps: performance.actualReps,
          actualWeight: performance.actualWeight,
          isCompleted: performance.isCompleted,
        );

        await _workoutSetDao.insert(set);
      }
    }
  }

  List<Map<String, dynamic>> _selectExercisesForWorkout(
    Map<String, dynamic> template,
    _TrainingDayType dayType,
  ) {
    final selected = (template['exercises'] as List<dynamic>)
        .map(
          (exercise) => Map<String, dynamic>.from(
            exercise as Map<dynamic, dynamic>,
          ),
        )
        .toList();
    final optionalExercises = (template['optionalExercises'] as List<dynamic>? ??
            const <dynamic>[])
        .map(
          (exercise) => Map<String, dynamic>.from(
            exercise as Map<dynamic, dynamic>,
          ),
        )
        .where(
          (exercise) => !selected.any(
            (existing) => existing['slug'] == exercise['slug'],
          ),
        )
        .toList();

    var extrasToAdd = 0;
    switch (dayType) {
      case _TrainingDayType.volume:
      case _TrainingDayType.peak:
        extrasToAdd = _chance(0.75) ? 1 : 0;
        if (extrasToAdd == 1 && _chance(0.2)) {
          extrasToAdd++;
        }
      case _TrainingDayType.baseline:
      case _TrainingDayType.heavy:
        extrasToAdd = _chance(0.25) ? 1 : 0;
      case _TrainingDayType.bad:
      case _TrainingDayType.deload:
        extrasToAdd = _chance(0.1) ? 1 : 0;
    }

    for (int i = 0; i < extrasToAdd && optionalExercises.isNotEmpty; i++) {
      final nextIndex = _random.nextInt(optionalExercises.length);
      selected.add(optionalExercises.removeAt(nextIndex));
    }

    return selected;
  }

  _TrainingWeekType _selectWeekType(double progress) {
    if (_chance(0.08)) {
      return _TrainingWeekType.pause;
    }
    if (progress > 0.65 && _chance(0.14)) {
      return _TrainingWeekType.peak;
    }
    if (_chance(progress > 0.4 ? 0.1 : 0.06)) {
      return _TrainingWeekType.deload;
    }
    return _TrainingWeekType.normal;
  }

  _TrainingDayType _selectDayType(
    _TrainingWeekType weekType,
    double progress,
  ) {
    if (weekType == _TrainingWeekType.deload) {
      return _TrainingDayType.deload;
    }
    if (weekType == _TrainingWeekType.peak && _chance(0.35)) {
      return _TrainingDayType.peak;
    }

    final roll = _random.nextDouble();
    if (roll < 0.14) {
      return _TrainingDayType.bad;
    }
    if (roll < 0.34) {
      return _TrainingDayType.heavy;
    }
    if (roll < 0.54) {
      return _TrainingDayType.volume;
    }
    if (progress > 0.55 && roll < 0.64) {
      return _TrainingDayType.peak;
    }
    return _TrainingDayType.baseline;
  }

  int _workoutsForWeek(_TrainingWeekType weekType) {
    switch (weekType) {
      case _TrainingWeekType.pause:
        return 0;
      case _TrainingWeekType.peak:
        return 4 + _random.nextInt(2);
      case _TrainingWeekType.deload:
        return 2 + _random.nextInt(2);
      case _TrainingWeekType.normal:
        return 3 + _random.nextInt(3);
    }
  }

  List<int> _pickWorkoutDayOffsets(int workoutsCount) {
    final dayOffsets = <int>[];
    final usedOffsets = <int>{};

    while (dayOffsets.length < workoutsCount) {
      var offset = _random.nextInt(7);
      if (!usedOffsets.add(offset)) {
        offset = _firstAvailableDayOffset(usedOffsets);
        usedOffsets.add(offset);
      }
      dayOffsets.add(offset);
    }

    dayOffsets.sort();
    return dayOffsets;
  }

  int _firstAvailableDayOffset(Set<int> usedOffsets) {
    for (int offset = 0; offset < 7; offset++) {
      if (!usedOffsets.contains(offset)) {
        return offset;
      }
    }
    return 0;
  }

  int _durationMinutesForDay(_TrainingDayType dayType) {
    switch (dayType) {
      case _TrainingDayType.peak:
        return 65 + _random.nextInt(26);
      case _TrainingDayType.volume:
        return 60 + _random.nextInt(21);
      case _TrainingDayType.heavy:
        return 50 + _random.nextInt(21);
      case _TrainingDayType.bad:
        return 35 + _random.nextInt(21);
      case _TrainingDayType.deload:
        return 40 + _random.nextInt(16);
      case _TrainingDayType.baseline:
        return 45 + _random.nextInt(21);
    }
  }

  int _moodForDay(_TrainingDayType dayType) {
    switch (dayType) {
      case _TrainingDayType.peak:
        return 4 + _random.nextInt(2);
      case _TrainingDayType.volume:
      case _TrainingDayType.baseline:
        return 3 + _random.nextInt(2);
      case _TrainingDayType.heavy:
        return 3 + _random.nextInt(3);
      case _TrainingDayType.bad:
        return 1 + _random.nextInt(2);
      case _TrainingDayType.deload:
        return 2 + _random.nextInt(2);
    }
  }

  int _plannedSetCount(
    _TrainingDayType dayType, {
    required bool isAccessory,
  }) {
    switch (dayType) {
      case _TrainingDayType.peak:
        return isAccessory ? 3 : 4;
      case _TrainingDayType.volume:
        return isAccessory ? 3 : 4 + _random.nextInt(2);
      case _TrainingDayType.heavy:
        return isAccessory ? 2 : 3;
      case _TrainingDayType.bad:
        return isAccessory ? 2 : 3;
      case _TrainingDayType.deload:
        return 2;
      case _TrainingDayType.baseline:
        return 3;
    }
  }

  int _completedSetCount(_TrainingDayType dayType, int plannedSetCount) {
    if (plannedSetCount <= 1) {
      return plannedSetCount;
    }

    switch (dayType) {
      case _TrainingDayType.bad:
        return max(1, plannedSetCount - 1 - (_chance(0.4) ? 1 : 0));
      case _TrainingDayType.volume:
        return _chance(0.12) ? plannedSetCount - 1 : plannedSetCount;
      case _TrainingDayType.heavy:
        return _chance(0.08) ? plannedSetCount - 1 : plannedSetCount;
      case _TrainingDayType.peak:
        return _chance(0.05) ? plannedSetCount - 1 : plannedSetCount;
      case _TrainingDayType.deload:
        return _chance(0.1) ? plannedSetCount - 1 : plannedSetCount;
      case _TrainingDayType.baseline:
        return _chance(0.07) ? plannedSetCount - 1 : plannedSetCount;
    }
  }

  int _targetRepsForSet({
    required int baseReps,
    required double progress,
    required _TrainingDayType dayType,
    required int setIndex,
    required bool isAccessory,
  }) {
    final progressionBonus = progress > 0.7 && isAccessory ? 1 : 0;
    final dayAdjustment = switch (dayType) {
      _TrainingDayType.volume => 2,
      _TrainingDayType.heavy => -2,
      _TrainingDayType.peak => -1,
      _TrainingDayType.bad => -1,
      _TrainingDayType.deload => -2,
      _TrainingDayType.baseline => 0,
    };
    final setAdjustment = setIndex > 1 ? 1 : 0;
    return max(1, baseReps + progressionBonus + dayAdjustment - setAdjustment);
  }

  double _targetWeightForSet({
    required double baseWeight,
    required double progress,
    required _TrainingDayType dayType,
    required int setIndex,
    required bool isAccessory,
  }) {
    if (baseWeight <= 0) {
      return 0;
    }

    final progressionMultiplier = 0.88 +
        (progress * (isAccessory ? 0.12 : 0.22));
    final dayMultiplier = switch (dayType) {
      _TrainingDayType.volume => 0.95,
      _TrainingDayType.heavy => 1.05,
      _TrainingDayType.peak => 1.1,
      _TrainingDayType.bad => 0.9,
      _TrainingDayType.deload => 0.85,
      _TrainingDayType.baseline => 1.0,
    };
    final setMultiplier = switch (setIndex) {
      0 => 1.0,
      1 => 0.98,
      2 => 0.96,
      3 => 0.94,
      _ => 0.92,
    };
    final weight = baseWeight *
        progressionMultiplier *
        dayMultiplier *
        setMultiplier *
        (0.96 + (_random.nextDouble() * 0.08));
    return _roundToNearestHalf(weight);
  }

  ({double? actualWeight, int? actualReps, bool isCompleted})
      _actualPerformanceForSet({
    required double targetWeight,
    required int targetReps,
    required bool isCompleted,
    required bool isBodyweightExercise,
    required _TrainingDayType dayType,
    required bool isPrSet,
  }) {
    if (!isCompleted) {
      return (actualWeight: null, actualReps: null, isCompleted: false);
    }

    double actualWeight = targetWeight;
    int actualReps = targetReps;

    switch (dayType) {
      case _TrainingDayType.bad:
        actualWeight = isBodyweightExercise
            ? 0
            : _roundToNearestHalf(targetWeight * (0.9 + _random.nextDouble() * 0.05));
        actualReps = max(1, targetReps - 1 - _random.nextInt(2));
      case _TrainingDayType.heavy:
        actualWeight = isBodyweightExercise
            ? 0
            : _roundToNearestHalf(targetWeight * (1.01 + _random.nextDouble() * 0.04));
        actualReps = max(1, targetReps - _random.nextInt(2));
      case _TrainingDayType.volume:
        actualWeight = isBodyweightExercise
            ? 0
            : _roundToNearestHalf(targetWeight * (0.97 + _random.nextDouble() * 0.03));
        actualReps = targetReps + _random.nextInt(3);
      case _TrainingDayType.peak:
        actualWeight = isBodyweightExercise
            ? 0
            : _roundToNearestHalf(targetWeight * (1.03 + _random.nextDouble() * 0.05));
        actualReps = targetReps + (_chance(0.4) ? 1 : 0);
      case _TrainingDayType.deload:
        actualWeight = isBodyweightExercise
            ? 0
            : _roundToNearestHalf(targetWeight * (0.95 + _random.nextDouble() * 0.02));
        actualReps = max(1, targetReps - _random.nextInt(2));
      case _TrainingDayType.baseline:
        actualWeight = isBodyweightExercise
            ? 0
            : _roundToNearestHalf(targetWeight * (0.99 + _random.nextDouble() * 0.03));
        actualReps = max(1, targetReps + (_chance(0.15) ? 1 : 0) - (_chance(0.1) ? 1 : 0));
    }

    if (isPrSet) {
      if (isBodyweightExercise) {
        actualReps += 1 + _random.nextInt(3);
      } else {
        actualWeight = _roundToNearestHalf(
          actualWeight + 2.5 + (2.5 * _random.nextInt(2)),
        );
      }
    }

    return (
      actualWeight: isBodyweightExercise ? 0 : max(0, actualWeight),
      actualReps: max(1, actualReps),
      isCompleted: true,
    );
  }

  int _targetRestSeconds(_TrainingDayType dayType) {
    return switch (dayType) {
      _TrainingDayType.peak => 180,
      _TrainingDayType.heavy => 150,
      _TrainingDayType.volume => 90,
      _TrainingDayType.bad => 75,
      _TrainingDayType.deload => 60,
      _TrainingDayType.baseline => 90,
    };
  }

  int _prExerciseIndex(_TrainingDayType dayType, int exerciseCount) {
    if (exerciseCount == 0 || dayType == _TrainingDayType.bad) {
      return -1;
    }
    return 0;
  }

  bool _chance(double probability) {
    return _random.nextDouble() < probability;
  }

  double _roundToNearestHalf(double value) {
    if (value <= 0) {
      return 0;
    }
    return (value * 2).round() / 2;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static List<Map<String, dynamic>> _defaultWorkoutTemplates() {
    return _cloneTemplates([
      {
        'name': 'Push Day',
        'exercises': [
          {'slug': 'bench-press', 'baseWeight': 60.0, 'baseReps': 8},
          {'slug': 'overhead-press', 'baseWeight': 40.0, 'baseReps': 10},
          {'slug': 'incline-dumbbell-press', 'baseWeight': 20.0, 'baseReps': 12},
          {
            'slug': 'tricep-pushdown-with-rope',
            'baseWeight': 15.0,
            'baseReps': 15,
          },
        ],
        'optionalExercises': [
          {'slug': 'push-up', 'baseWeight': 0.0, 'baseReps': 18},
          {'slug': 'plank', 'baseWeight': 0.0, 'baseReps': 75},
        ],
      },
      {
        'name': 'Pull Day',
        'exercises': [
          {'slug': 'deadlift', 'baseWeight': 100.0, 'baseReps': 5},
          {'slug': 'pull-up', 'baseWeight': 0.0, 'baseReps': 8},
          {'slug': 'barbell-row', 'baseWeight': 50.0, 'baseReps': 10},
          {'slug': 'dumbbell-curl', 'baseWeight': 12.0, 'baseReps': 12},
        ],
        'optionalExercises': [
          {'slug': 'kettlebell-swing', 'baseWeight': 16.0, 'baseReps': 18},
          {'slug': 'push-up', 'baseWeight': 0.0, 'baseReps': 15},
        ],
      },
      {
        'name': 'Leg Day',
        'exercises': [
          {'slug': 'squat', 'baseWeight': 80.0, 'baseReps': 6},
          {'slug': 'leg-press', 'baseWeight': 120.0, 'baseReps': 10},
          {'slug': 'romanian-deadlift', 'baseWeight': 70.0, 'baseReps': 10},
          {'slug': 'standing-calf-raise', 'baseWeight': 40.0, 'baseReps': 15},
        ],
        'optionalExercises': [
          {'slug': 'dumbbell-lunge', 'baseWeight': 14.0, 'baseReps': 12},
          {'slug': 'kettlebell-swing', 'baseWeight': 16.0, 'baseReps': 20},
        ],
      },
      {
        'name': 'Full Body',
        'exercises': [
          {'slug': 'kettlebell-swing', 'baseWeight': 16.0, 'baseReps': 20},
          {'slug': 'push-up', 'baseWeight': 0.0, 'baseReps': 15},
          {'slug': 'plank', 'baseWeight': 0.0, 'baseReps': 60},
          {'slug': 'dumbbell-lunge', 'baseWeight': 14.0, 'baseReps': 12},
        ],
        'optionalExercises': [
          {'slug': 'bench-press', 'baseWeight': 52.5, 'baseReps': 6},
          {'slug': 'pull-up', 'baseWeight': 0.0, 'baseReps': 8},
        ],
      },
    ]);
  }

  static List<Map<String, dynamic>> _cloneTemplates(
    List<Map<String, dynamic>> templates,
  ) {
    return templates
        .map(
          (template) => {
            ...template,
            'exercises': _cloneExerciseList(template['exercises'] as List<dynamic>),
            'optionalExercises': _cloneExerciseList(
              template['optionalExercises'] as List<dynamic>? ??
                  const <dynamic>[],
            ),
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _cloneExerciseList(List<dynamic> source) {
    return source
        .map(
          (exercise) => Map<String, dynamic>.from(
            exercise as Map<dynamic, dynamic>,
          ),
        )
        .toList();
  }
}
