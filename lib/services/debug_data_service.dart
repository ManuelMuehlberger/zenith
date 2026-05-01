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

  // Define the 4 workout templates
  List<Map<String, dynamic>> _workoutTemplates = [
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
    },
    {
      'name': 'Pull Day',
      'exercises': [
        {'slug': 'deadlift', 'baseWeight': 100.0, 'baseReps': 5},
        {'slug': 'pull-up', 'baseWeight': 0.0, 'baseReps': 8}, // Bodyweight
        {'slug': 'barbell-row', 'baseWeight': 50.0, 'baseReps': 10},
        {'slug': 'dumbbell-curl', 'baseWeight': 12.0, 'baseReps': 12},
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
    },
    {
      'name': 'Full Body',
      'exercises': [
        {'slug': 'kettlebell-swing', 'baseWeight': 16.0, 'baseReps': 20},
        {'slug': 'push-up', 'baseWeight': 0.0, 'baseReps': 15},
        {'slug': 'plank', 'baseWeight': 0.0, 'baseReps': 60}, // Seconds
        {'slug': 'dumbbell-lunge', 'baseWeight': 14.0, 'baseReps': 12},
      ],
    },
  ];

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
    _workoutTemplates = templates
        .map(
          (template) => {
            ...template,
            'exercises': (template['exercises'] as List<dynamic>)
                .map(
                  (exercise) => Map<String, dynamic>.from(
                    exercise as Map<dynamic, dynamic>,
                  ),
                )
                .toList(),
          },
        )
        .toList();
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
    _workoutTemplates = [
      {
        'name': 'Push Day',
        'exercises': [
          {'slug': 'bench-press', 'baseWeight': 60.0, 'baseReps': 8},
          {'slug': 'overhead-press', 'baseWeight': 40.0, 'baseReps': 10},
          {
            'slug': 'incline-dumbbell-press',
            'baseWeight': 20.0,
            'baseReps': 12,
          },
          {
            'slug': 'tricep-pushdown-with-rope',
            'baseWeight': 15.0,
            'baseReps': 15,
          },
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
      },
      {
        'name': 'Leg Day',
        'exercises': [
          {'slug': 'squat', 'baseWeight': 80.0, 'baseReps': 6},
          {'slug': 'leg-press', 'baseWeight': 120.0, 'baseReps': 10},
          {'slug': 'romanian-deadlift', 'baseWeight': 70.0, 'baseReps': 10},
          {'slug': 'standing-calf-raise', 'baseWeight': 40.0, 'baseReps': 15},
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
      },
    ];
  }

  Future<void> generateDebugData() async {
    _logger.info('Starting debug data generation...');

    // Ensure exercises are loaded so we can link details if needed (though we mostly use slugs)
    await _loadExercises();

    final now = _nowProvider();

    for (int week = 0; week < _weeksToGenerate; week++) {
      // Calculate the start of this week (going backwards from now)
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));

      // Decide how many workouts this week (3 or 4)
      final workoutsCount = 3 + _random.nextInt(2); // 3 or 4

      // Pick random days in this week
      final List<int> daysOffsets = [];
      while (daysOffsets.length < workoutsCount) {
        final offset = _random.nextInt(7);
        if (!daysOffsets.contains(offset)) {
          daysOffsets.add(offset);
        }
      }
      daysOffsets.sort();

      for (final dayOffset in daysOffsets) {
        final workoutDate = weekStart.add(Duration(days: dayOffset));

        // Pick a random workout template
        final template =
            _workoutTemplates[_random.nextInt(_workoutTemplates.length)];

        await _createWorkoutFromTemplate(template, workoutDate);
      }
    }

    _logger.info('Debug data generation complete.');
  }

  @visibleForTesting
  Future<void> createWorkoutFromTemplateForTesting(
    Map<String, dynamic> template,
    DateTime date,
  ) => _createWorkoutFromTemplate(template, date);

  Future<void> _createWorkoutFromTemplate(
    Map<String, dynamic> template,
    DateTime date,
  ) async {
    final workoutId = const Uuid().v4();

    // Randomize time of day (e.g., between 6 AM and 8 PM)
    final hour = 6 + _random.nextInt(15);
    final minute = _random.nextInt(60);
    final completedAt = DateTime(date.year, date.month, date.day, hour, minute);
    final durationMinutes = 45 + _random.nextInt(30); // 45-75 mins
    final startedAt = completedAt.subtract(Duration(minutes: durationMinutes));

    final workout = Workout(
      id: workoutId,
      name: template['name'] as String,
      status: WorkoutStatus.completed,
      startedAt: startedAt,
      completedAt: completedAt,
      exercises: [], // Will be populated
    );

    await _workoutDao.insert(workout);

    final templateExercises = template['exercises'] as List<dynamic>;

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

      // Create 3 sets
      for (int j = 0; j < 3; j++) {
        // Add some variation
        final weightVariation =
            (baseWeight * 0.1) * (_random.nextDouble() - 0.5); // +/- 5%
        final repsVariation = _random.nextInt(3) - 1; // -1, 0, +1

        double weight = baseWeight + weightVariation;
        // Round to nearest 0.5
        weight = (weight * 2).round() / 2;
        if (weight < 0) weight = 0;

        int reps = baseReps + repsVariation;
        if (reps < 1) reps = 1;

        final set = WorkoutSet(
          workoutExerciseId: exerciseId,
          setIndex: j,
          targetReps: reps,
          targetWeight: weight,
          actualReps: reps,
          actualWeight: weight,
          isCompleted: true,
        );

        await _workoutSetDao.insert(set);
      }
    }
  }
}
