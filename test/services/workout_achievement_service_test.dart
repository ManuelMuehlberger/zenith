import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_achievement.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/workout_achievement_service.dart';

class StringAssetBundle extends CachingAssetBundle {
  StringAssetBundle(this.rulesJson);

  final String rulesJson;

  @override
  Future<ByteData> load(String key) async {
    return ByteData(0);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return rulesJson;
  }
}

void main() {
  group('WorkoutAchievementService', () {
    const rulesJson = '''
{
  "rules": [
    {
      "id": "first_workout",
      "type": "firstWorkout",
      "title": "First Workout",
      "reasonTemplate": "Completed your first workout ever: {workoutName}.",
      "conditions": [
        { "metric": "workoutCountBefore", "operator": "equals", "value": 0 }
      ]
    },
    {
      "id": "high_volume",
      "type": "highVolume",
      "title": "High Volume",
      "reasonTemplate": "Completed {totalSets} sets, beating {totalSetsPercentileLast90Days}% of workouts from the last 3 months.",
      "conditions": [
        { "metric": "totalSets", "operator": "greaterThan", "value": 20 },
        { "metric": "totalSetsPercentileLast90Days", "operator": "greaterThan", "value": 75 }
      ]
    }
  ]
}
''';

    late WorkoutAchievementService service;

    setUp(() {
      service = WorkoutAchievementService(
        assetBundle: StringAssetBundle(rulesJson),
      );
    });

    test(
      'awards first workout when no prior completed workouts exist',
      () async {
        final workout = _workout(id: 'current', sets: 3);

        final awards = await service.evaluateForWorkout(workout, history: []);

        expect(awards, hasLength(1));
        expect(awards.single.type, WorkoutAchievementType.firstWorkout);
        expect(awards.single.reason, contains('Push Day'));
        expect(awards.single.metrics['workoutCountBefore'], 0);
      },
    );

    test('awards high volume above threshold and percentile window', () async {
      final now = DateTime(2026, 6, 1, 12);
      final workout = _workout(id: 'current', sets: 24, completedAt: now);
      final history = [
        _workout(
          id: 'old-1',
          sets: 10,
          completedAt: now.subtract(const Duration(days: 10)),
        ),
        _workout(
          id: 'old-2',
          sets: 12,
          completedAt: now.subtract(const Duration(days: 20)),
        ),
        _workout(
          id: 'old-3',
          sets: 18,
          completedAt: now.subtract(const Duration(days: 30)),
        ),
        _workout(
          id: 'old-4',
          sets: 20,
          completedAt: now.subtract(const Duration(days: 40)),
        ),
      ];

      final awards = await service.evaluateForWorkout(
        workout,
        history: history,
      );

      expect(
        awards.map((award) => award.type),
        contains(WorkoutAchievementType.highVolume),
      );
      final highVolume = awards.firstWhere(
        (award) => award.type == WorkoutAchievementType.highVolume,
      );
      expect(highVolume.metrics['comparisonWorkoutCount'], 4);
      expect(highVolume.metrics['totalSetsPercentileLast90Days'], 100);
    });

    test('does not award high volume below static threshold', () async {
      final now = DateTime(2026, 6, 1, 12);
      final workout = _workout(id: 'current', sets: 20, completedAt: now);
      final history = [
        _workout(
          id: 'old-1',
          sets: 10,
          completedAt: now.subtract(const Duration(days: 10)),
        ),
      ];

      final awards = await service.evaluateForWorkout(
        workout,
        history: history,
      );

      expect(
        awards.map((award) => award.type),
        isNot(contains(WorkoutAchievementType.highVolume)),
      );
    });

    test(
      'does not award percentile rule when history window is empty',
      () async {
        final now = DateTime(2026, 6, 1, 12);
        final workout = _workout(id: 'current', sets: 24, completedAt: now);
        final history = [
          _workout(
            id: 'old-1',
            sets: 10,
            completedAt: now.subtract(const Duration(days: 120)),
          ),
        ];

        final awards = await service.evaluateForWorkout(
          workout,
          history: history,
        );

        expect(
          awards.map((award) => award.type),
          isNot(contains(WorkoutAchievementType.highVolume)),
        );
      },
    );
  });
}

Workout _workout({
  required String id,
  required int sets,
  DateTime? completedAt,
}) {
  final end = completedAt ?? DateTime(2026, 1, 1, 12);
  final exercise = WorkoutExercise(
    id: 'exercise-$id',
    workoutId: id,
    exerciseSlug: 'bench-press',
    sets: List.generate(
      sets,
      (index) => WorkoutSet(
        id: 'set-$id-$index',
        workoutExerciseId: 'exercise-$id',
        setIndex: index,
        actualReps: 10,
        actualWeight: 50,
        isCompleted: true,
      ),
    ),
  );
  return Workout(
    id: id,
    name: 'Push Day',
    status: WorkoutStatus.completed,
    startedAt: end.subtract(const Duration(minutes: 45)),
    completedAt: end,
    exercises: [exercise],
  );
}
