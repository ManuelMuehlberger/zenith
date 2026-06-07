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

    test('awards dynamic long session above recent average target', () async {
      const dynamicRulesJson = '''
{
  "rules": [
    {
      "id": "long_session",
      "type": "longSession",
      "title": "Long Session",
      "reasonTemplate": "Trained for {durationMinutes} minutes against {longSessionTargetMinutes}.",
      "conditions": [
        { "metric": "durationMinutes", "operator": "greaterThan", "value": 60 },
        { "metric": "durationMinutes", "operator": "greaterThan", "valueMetric": "longSessionTargetMinutes" }
      ]
    }
  ]
}
''';
      final service = WorkoutAchievementService(
        assetBundle: StringAssetBundle(dynamicRulesJson),
      );
      final now = DateTime(2026, 6, 1, 12);
      final workout = _workout(
        id: 'current',
        sets: 3,
        completedAt: now,
        duration: const Duration(minutes: 80),
      );
      final history = [
        _workout(
          id: 'old-1',
          sets: 3,
          completedAt: now.subtract(const Duration(days: 10)),
          duration: const Duration(minutes: 40),
        ),
        _workout(
          id: 'old-2',
          sets: 3,
          completedAt: now.subtract(const Duration(days: 20)),
          duration: const Duration(minutes: 50),
        ),
      ];

      final awards = await service.evaluateForWorkout(
        workout,
        history: history,
      );

      expect(awards.map((award) => award.type), [
        WorkoutAchievementType.longSession,
      ]);
      expect(awards.single.metrics['averageDurationMinutesLast90Days'], 45);
      expect(awards.single.metrics['longSessionTargetMinutes'], 78.75);
    });

    test('awards workout milestone by workout number', () async {
      const milestoneRulesJson = '''
{
  "rules": [
    {
      "id": "tenth_workout",
      "type": "workoutMilestone",
      "title": "10 Workouts",
      "reasonTemplate": "Completed workout #{workoutNumber}.",
      "conditions": [
        { "metric": "workoutNumber", "operator": "equals", "value": 10 }
      ]
    }
  ]
}
''';
      final service = WorkoutAchievementService(
        assetBundle: StringAssetBundle(milestoneRulesJson),
      );
      final now = DateTime(2026, 6, 1, 12);
      final history = List.generate(
        9,
        (index) => _workout(
          id: 'old-$index',
          sets: 3,
          completedAt: now.subtract(Duration(days: 10 - index)),
        ),
      );

      final awards = await service.evaluateForWorkout(
        _workout(id: 'current', sets: 3, completedAt: now),
        history: history,
      );

      expect(awards.single.type, WorkoutAchievementType.workoutMilestone);
      expect(awards.single.metrics['workoutNumber'], 10);
    });

    test('awards streak once cooldown has elapsed', () async {
      const streakRulesJson = '''
{
  "rules": [
    {
      "id": "three_day_streak",
      "type": "workoutStreak",
      "title": "3-Day Streak",
      "reasonTemplate": "{consecutiveWorkoutDays} days.",
      "conditions": [
        { "metric": "consecutiveWorkoutDays", "operator": "greaterThanOrEqual", "value": 3 },
        { "metric": "daysSince3DayStreakAward", "operator": "greaterThanOrEqual", "value": 3 }
      ]
    }
  ]
}
''';
      final service = WorkoutAchievementService(
        assetBundle: StringAssetBundle(streakRulesJson),
      );
      final now = DateTime(2026, 6, 7, 12);
      final priorAward = WorkoutAchievement(
        workoutId: 'old-award',
        ruleId: 'three_day_streak',
        type: WorkoutAchievementType.workoutStreak,
        title: '3-Day Streak',
        reason: '3 days.',
        earnedAt: DateTime(2026, 6, 4, 12),
      );
      final history = [
        _workout(
          id: 'old-award',
          sets: 3,
          completedAt: DateTime(2026, 6, 4, 12),
          achievements: [priorAward],
        ),
        _workout(id: 'old-1', sets: 3, completedAt: DateTime(2026, 6, 5, 12)),
        _workout(id: 'old-2', sets: 3, completedAt: DateTime(2026, 6, 6, 12)),
      ];

      final awards = await service.evaluateForWorkout(
        _workout(id: 'current', sets: 3, completedAt: now),
        history: history,
      );

      expect(awards.single.type, WorkoutAchievementType.workoutStreak);
      expect(awards.single.metrics['consecutiveWorkoutDays'], 4);
      expect(awards.single.metrics['daysSince3DayStreakAward'], 3);
    });
  });
}

Workout _workout({
  required String id,
  required int sets,
  DateTime? completedAt,
  Duration duration = const Duration(minutes: 45),
  List<WorkoutAchievement> achievements = const [],
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
    startedAt: end.subtract(duration),
    completedAt: end,
    exercises: [exercise],
    achievements: achievements,
  );
}
