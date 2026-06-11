import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/insight_feed.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_achievement.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/insights/cache/insights_cache_store.dart';
import 'package:zenith/services/insights/insight_feed_service.dart';

class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = assets[key];
    if (value == null) {
      throw FlutterError('Missing test asset: $key');
    }
    return value;
  }

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError();
  }
}

void main() {
  const rulesAsset = InsightFeedService.defaultRulesAsset;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'generates achievement and consistency cards from workout history',
    () async {
      final now = DateTime(2026, 6, 11, 12);
      final service = InsightFeedService(
        assetBundle: _StringAssetBundle({
          rulesAsset: '''
{
  "rules": [
    {"id": "achievement", "type": "recentAchievementShoutout", "enabled": true, "priority": 100, "params": {"maxAgeDays": 14}},
    {"id": "consistency", "type": "consistencyPulse", "enabled": true, "priority": 50, "params": {"recentDays": 7, "minimumWorkouts": 2}}
  ]
}
''',
        }),
        workoutsProvider: () async => [
          _workout(
            id: 'w1',
            completedAt: now.subtract(const Duration(days: 2)),
          ),
          _workout(
            id: 'w2',
            completedAt: now.subtract(const Duration(days: 1)),
            achievements: [
              WorkoutAchievement(
                workoutId: 'w2',
                ruleId: 'high_volume',
                type: WorkoutAchievementType.highVolume,
                title: 'High Volume',
                reason: 'Completed a rare high-volume workout.',
                earnedAt: now.subtract(const Duration(days: 1)),
              ),
            ],
          ),
        ],
        nowProvider: () => now,
        cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-1'),
      );

      final cards = await service.getCards();

      expect(cards.map((card) => card.type), [
        InsightFeedCardType.recentAchievementShoutout,
        InsightFeedCardType.consistencyPulse,
      ]);
      expect(cards.first.title, 'High Volume');
    },
  );

  test('reuses the daily cache until the local date changes', () async {
    var now = DateTime(2026, 6, 11, 12);
    var loadCount = 0;
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "rules": [
    {"id": "consistency", "type": "consistencyPulse", "enabled": true, "priority": 50, "params": {"recentDays": 7, "minimumWorkouts": 1}}
  ]
}
''',
      }),
      workoutsProvider: () async {
        loadCount++;
        return [_workout(id: 'w$loadCount', completedAt: now)];
      },
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-2'),
    );

    final first = await service.getCards();
    final second = await service.getCards();
    now = DateTime(2026, 6, 12, 9);
    final third = await service.getCards();

    expect(first.single.sourceWorkoutId, isNull);
    expect(second.single.generatedAt, first.single.generatedAt);
    expect(third.single.generatedAt, DateTime(2026, 6, 12, 9));
    expect(loadCount, 2);
  });

  test('returns no cards when configured thresholds are unmet', () async {
    final now = DateTime(2026, 6, 11, 12);
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "rules": [
    {"id": "consistency", "type": "consistencyPulse", "enabled": true, "priority": 50, "params": {"recentDays": 7, "minimumWorkouts": 3}}
  ]
}
''',
      }),
      workoutsProvider: () async => [
        _workout(id: 'w1', completedAt: now.subtract(const Duration(days: 1))),
      ],
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-3'),
    );

    expect(await service.getCards(), isEmpty);
  });

  test('generates momentum, intensity, and velocity cards', () async {
    final now = DateTime(2026, 6, 20, 12);
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "rules": [
    {"id": "velocity", "type": "trainingVelocity", "enabled": true, "priority": 90, "params": {"recentDays": 7, "baselineDays": 90, "minimumDeltaPercent": 10}},
    {"id": "intensity", "type": "highIntensityShoutout", "enabled": true, "priority": 80, "params": {"lookbackDays": 90, "minimumPercentile": 80}},
    {"id": "comeback", "type": "comebackCard", "enabled": true, "priority": 70, "params": {"minGapDays": 7}},
    {"id": "momentum", "type": "personalBestMomentum", "enabled": true, "priority": 60, "params": {}}
  ]
}
''',
      }),
      workoutsProvider: () async => [
        for (var day = 90; day >= 20; day -= 10)
          _workout(
            id: 'baseline-$day',
            completedAt: now.subtract(Duration(days: day)),
            setCount: 2,
            reps: 8,
            weight: 20,
          ),
        _workout(
          id: 'gap-return',
          completedAt: now.subtract(const Duration(days: 9)),
          setCount: 3,
          reps: 8,
          weight: 40,
        ),
        _workout(
          id: 'recent-1',
          completedAt: now.subtract(const Duration(days: 5)),
          setCount: 3,
          reps: 10,
          weight: 50,
        ),
        _workout(
          id: 'recent-2',
          completedAt: now.subtract(const Duration(days: 3)),
          setCount: 4,
          reps: 10,
          weight: 55,
        ),
        _workout(
          id: 'latest',
          completedAt: now.subtract(const Duration(days: 1)),
          setCount: 9,
          reps: 12,
          weight: 80,
        ),
      ],
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-4'),
    );

    final cards = await service.getCards(maxCards: 10);
    final types = cards.map((card) => card.type).toSet();

    expect(types, contains(InsightFeedCardType.trainingVelocity));
    expect(types, contains(InsightFeedCardType.highIntensityShoutout));
    expect(types, contains(InsightFeedCardType.personalBestMomentum));
  });

  test('generates a comeback card after a long gap', () async {
    final now = DateTime(2026, 6, 20, 12);
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "rules": [
    {"id": "comeback", "type": "comebackCard", "enabled": true, "priority": 70, "params": {"minGapDays": 7}}
  ]
}
''',
      }),
      workoutsProvider: () async => [
        _workout(
          id: 'older',
          completedAt: now.subtract(const Duration(days: 12)),
        ),
        _workout(
          id: 'latest',
          completedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-6'),
    );

    final cards = await service.getCards();

    expect(cards.single.type, InsightFeedCardType.comebackCard);
    expect(cards.single.metric, '11d');
  });

  test('invalidateCache forces regeneration on the same day', () async {
    final now = DateTime(2026, 6, 11, 12);
    var callCount = 0;
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "rules": [
    {"id": "consistency", "type": "consistencyPulse", "enabled": true, "priority": 50, "params": {"recentDays": 7, "minimumWorkouts": 1}}
  ]
}
''',
      }),
      workoutsProvider: () async {
        callCount++;
        return [_workout(id: 'w$callCount', completedAt: now)];
      },
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-5'),
    );

    await service.getCards();
    await service.invalidateCache();
    await service.getCards();

    expect(callCount, 2);
  });
}

Workout _workout({
  required String id,
  required DateTime completedAt,
  List<WorkoutAchievement> achievements = const [],
  int setCount = 3,
  int reps = 10,
  double weight = 50,
}) {
  final exercise = WorkoutExercise(
    id: '$id-exercise',
    workoutId: id,
    exerciseSlug: 'bench_press',
    sets: List.generate(
      setCount,
      (index) => WorkoutSet(
        workoutExerciseId: '$id-exercise',
        setIndex: index,
        actualReps: reps,
        actualWeight: weight,
        isCompleted: true,
      ),
    ),
  );

  return Workout(
    id: id,
    name: 'Workout $id',
    status: WorkoutStatus.completed,
    startedAt: completedAt.subtract(const Duration(minutes: 45)),
    completedAt: completedAt,
    exercises: [exercise],
    achievements: achievements,
  );
}
