import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/insight_feed.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_achievement.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/insights/cache/insights_cache_store.dart';
import 'package:zenith/services/insights/insight_feed_service.dart';
import 'package:zenith/services/workout_muscle_activation_service.dart';

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
    {"id": "achievement", "type": "recentAchievementShoutout", "enabled": true, "priority": 100, "params": {"maxAgeDays": 14}, "visual": {"enabled": true, "type": "awardPreview", "size": "wide", "params": {}}},
    {"id": "consistency", "type": "consistencyPulse", "enabled": true, "priority": 50, "params": {"recentDays": 7, "minimumWorkouts": 2}}
  ]
}
''',
        }),
        workoutsProvider: () async => [
          _workout(
            id: 'w1',
            completedAt: now.subtract(const Duration(days: 2)),
            achievements: [
              WorkoutAchievement(
                workoutId: 'w1',
                ruleId: 'first_workout',
                type: WorkoutAchievementType.firstWorkout,
                title: 'First Workout',
                reason: 'Completed your first workout.',
                earnedAt: now.subtract(const Duration(days: 2)),
              ),
            ],
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
      expect(cards.first.metric, isEmpty);
      expect(cards.first.visualData['achievements'], hasLength(1));
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

  test('generates configured card stacks in priority order', () async {
    final now = DateTime(2026, 6, 20, 12);
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "stacks": [
    {"id": "last_workout", "title": "Last Workout", "enabled": true, "priority": 100, "minCompletedWorkouts": 1, "maxCards": 2},
    {"id": "recent_trends", "title": "Recent Trends", "enabled": true, "priority": 80, "minCompletedWorkouts": 3, "maxCards": 2},
    {"id": "long_term_trends", "title": "Long-Term Trends", "enabled": true, "priority": 60, "minCompletedWorkouts": 8, "maxCards": 2}
  ],
  "rules": [
    {"id": "latest", "stackId": "last_workout", "type": "latestWorkoutComparison", "enabled": true, "priority": 90, "params": {"baselineWorkouts": 4, "minBaselineWorkouts": 2}, "visual": {"enabled": true, "type": "baselineBars", "size": "wide", "params": {}}},
    {"id": "consistency", "stackId": "recent_trends", "type": "consistencyPulse", "enabled": true, "priority": 80, "params": {"recentDays": 14, "minimumWorkouts": 2}},
    {"id": "weight", "stackId": "long_term_trends", "type": "bodyWeightTrend", "enabled": true, "priority": 70, "params": {"lookbackDays": 90, "minSamples": 2}, "visual": {"enabled": true, "type": "bodyWeightLine", "size": "wide", "params": {}}}
  ]
}
''',
      }),
      workoutsProvider: () async => [
        for (var day = 8; day >= 1; day--)
          _workout(
            id: 'w$day',
            completedAt: now.subtract(Duration(days: day)),
          ),
      ],
      weightHistoryProvider: () => [
        WeightEntry(
          timestamp: now.subtract(const Duration(days: 30)),
          value: 80,
        ),
        WeightEntry(
          timestamp: now.subtract(const Duration(days: 1)),
          value: 79,
        ),
      ],
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-stacks'),
    );

    final stacks = await service.getCardStacks();

    expect(stacks.map((stack) => stack.title), [
      'Last Workout',
      'Recent Trends',
      'Long-Term Trends',
    ]);
    expect(
      stacks[0].cards.single.type,
      InsightFeedCardType.latestWorkoutComparison,
    );
    expect(stacks[1].cards.single.type, InsightFeedCardType.consistencyPulse);
    expect(stacks[2].cards.single.type, InsightFeedCardType.bodyWeightTrend);
  });

  test('hides stacks below completed workout thresholds', () async {
    final now = DateTime(2026, 6, 20, 12);
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "stacks": [
    {"id": "last_workout", "title": "Last Workout", "enabled": true, "priority": 100, "minCompletedWorkouts": 1, "maxCards": 2},
    {"id": "recent_trends", "title": "Recent Trends", "enabled": true, "priority": 80, "minCompletedWorkouts": 3, "maxCards": 2},
    {"id": "long_term_trends", "title": "Long-Term Trends", "enabled": true, "priority": 60, "minCompletedWorkouts": 8, "maxCards": 2}
  ],
  "rules": [
    {"id": "latest", "stackId": "last_workout", "type": "latestWorkoutComparison", "enabled": true, "priority": 90, "params": {"baselineWorkouts": 2, "minBaselineWorkouts": 1}, "visual": {"enabled": true, "type": "baselineBars", "size": "wide", "params": {}}},
    {"id": "consistency", "stackId": "recent_trends", "type": "consistencyPulse", "enabled": true, "priority": 80, "params": {"recentDays": 14, "minimumWorkouts": 1}},
    {"id": "weight", "stackId": "long_term_trends", "type": "bodyWeightTrend", "enabled": true, "priority": 70, "params": {"lookbackDays": 90, "minSamples": 2}, "visual": {"enabled": true, "type": "bodyWeightLine", "size": "wide", "params": {}}}
  ]
}
''',
      }),
      workoutsProvider: () async => [
        _workout(
          id: 'older',
          completedAt: now.subtract(const Duration(days: 8)),
        ),
        _workout(
          id: 'latest',
          completedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      weightHistoryProvider: () => [
        WeightEntry(
          timestamp: now.subtract(const Duration(days: 30)),
          value: 80,
        ),
        WeightEntry(
          timestamp: now.subtract(const Duration(days: 1)),
          value: 79,
        ),
      ],
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(
        cacheKey: 'feed-test-stack-thresholds',
      ),
    );

    final stacks = await service.getCardStacks();

    expect(stacks.map((stack) => stack.title), ['Last Workout']);
    expect(
      stacks.single.cards.single.type,
      InsightFeedCardType.latestWorkoutComparison,
    );
  });

  test('applies max cards per stack', () async {
    final now = DateTime(2026, 6, 20, 12);
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "stacks": [
    {"id": "last_workout", "title": "Last Workout", "enabled": true, "priority": 100, "minCompletedWorkouts": 1, "maxCards": 1}
  ],
  "rules": [
    {"id": "latest", "stackId": "last_workout", "type": "latestWorkoutComparison", "enabled": true, "priority": 90, "params": {"baselineWorkouts": 2, "minBaselineWorkouts": 1}, "visual": {"enabled": true, "type": "baselineBars", "size": "wide", "params": {}}},
    {"id": "comeback", "stackId": "last_workout", "type": "comebackCard", "enabled": true, "priority": 80, "params": {"minGapDays": 7}}
  ]
}
''',
      }),
      workoutsProvider: () async => [
        _workout(
          id: 'older',
          completedAt: now.subtract(const Duration(days: 20)),
        ),
        _workout(
          id: 'baseline',
          completedAt: now.subtract(const Duration(days: 10)),
        ),
        _workout(
          id: 'latest',
          completedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-stack-max'),
    );

    final stacks = await service.getCardStacks();

    expect(stacks.single.cards, hasLength(1));
    expect(
      stacks.single.cards.single.type,
      InsightFeedCardType.latestWorkoutComparison,
    );
  });

  test('legacy getCards remains globally capped and priority sorted', () async {
    final now = DateTime(2026, 6, 20, 12);
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "stacks": [
    {"id": "last_workout", "title": "Last Workout", "enabled": true, "priority": 100, "minCompletedWorkouts": 1, "maxCards": 2},
    {"id": "recent_trends", "title": "Recent Trends", "enabled": true, "priority": 80, "minCompletedWorkouts": 1, "maxCards": 2}
  ],
  "rules": [
    {"id": "latest", "stackId": "last_workout", "type": "latestWorkoutComparison", "enabled": true, "priority": 90, "params": {"baselineWorkouts": 2, "minBaselineWorkouts": 1}, "visual": {"enabled": true, "type": "baselineBars", "size": "wide", "params": {}}},
    {"id": "consistency", "stackId": "recent_trends", "type": "consistencyPulse", "enabled": true, "priority": 80, "params": {"recentDays": 14, "minimumWorkouts": 2}}
  ]
}
''',
      }),
      workoutsProvider: () async => [
        _workout(
          id: 'older',
          completedAt: now.subtract(const Duration(days: 8)),
        ),
        _workout(
          id: 'latest',
          completedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-flat-compat'),
    );

    final cards = await service.getCards(maxCards: 1);

    expect(cards, hasLength(1));
    expect(cards.single.type, InsightFeedCardType.latestWorkoutComparison);
  });

  test('latest workout comparison uses a recent one-month baseline', () async {
    final now = DateTime(2026, 6, 20, 12);
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "rules": [
    {"id": "latest", "type": "latestWorkoutComparison", "enabled": true, "priority": 90, "params": {"baselineDays": 30, "minBaselineWorkouts": 2}, "visual": {"enabled": true, "type": "baselineBars", "size": "wide", "params": {}}}
  ]
}
''',
      }),
      workoutsProvider: () async => [
        _workout(
          id: 'older',
          completedAt: now.subtract(const Duration(days: 45)),
          setCount: 4,
          weight: 80,
        ),
        _workout(
          id: 'baseline-1',
          completedAt: now.subtract(const Duration(days: 20)),
          setCount: 3,
          weight: 50,
        ),
        _workout(
          id: 'baseline-2',
          completedAt: now.subtract(const Duration(days: 10)),
          setCount: 3,
          weight: 50,
        ),
        _workout(
          id: 'latest',
          completedAt: now.subtract(const Duration(days: 1)),
          setCount: 4,
          weight: 50,
        ),
      ],
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(
        cacheKey: 'feed-test-latest-baseline',
      ),
    );

    final cards = await service.getCards(maxCards: 10);
    final latest = cards.singleWhere(
      (card) => card.type == InsightFeedCardType.latestWorkoutComparison,
    );

    expect(latest.title, 'Workout progress');
    expect(latest.body, 'Workout latest compared with your recent baseline.');
    expect(latest.comparisonLabel, isNull);
    expect(latest.metric, '+33%');
    expect(latest.visualData['items'], [
      {
        'label': 'Duration',
        'baseline': 45.0,
        'actual': 45.0,
        'deltaLabel': '0%',
        'unit': 'min',
      },
      {
        'label': 'Sets',
        'baseline': 3.0,
        'actual': 4.0,
        'deltaLabel': '33%',
        'unit': 'sets',
      },
      {
        'label': 'Volume',
        'baseline': 1500.0,
        'actual': 2000.0,
        'deltaLabel': '33%',
        'unit': '',
      },
    ]);
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

  test('configured graph-capable rules include visual payloads', () async {
    final now = DateTime(2026, 6, 20, 12);
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "rules": [
    {"id": "velocity", "type": "trainingVelocity", "enabled": true, "priority": 90, "params": {"recentDays": 7, "baselineDays": 90, "minimumDeltaPercent": 10}, "visual": {"enabled": true, "type": "baselineBars", "size": "wide", "params": {}}},
    {"id": "consistency", "type": "consistencyPulse", "enabled": true, "priority": 80, "params": {"recentDays": 14, "minimumWorkouts": 2}, "visual": {"enabled": true, "type": "calendarStrip", "size": "wide", "params": {}}}
  ]
}
''',
      }),
      workoutsProvider: () async => [
        for (var day = 90; day >= 20; day -= 10)
          _workout(
            id: 'baseline-$day',
            completedAt: now.subtract(Duration(days: day)),
          ),
        _workout(
          id: 'recent-1',
          completedAt: now.subtract(const Duration(days: 5)),
        ),
        _workout(
          id: 'recent-2',
          completedAt: now.subtract(const Duration(days: 3)),
        ),
        _workout(
          id: 'latest',
          completedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-visuals'),
    );

    final cards = await service.getCards(maxCards: 10);
    final velocity = cards.firstWhere(
      (card) => card.type == InsightFeedCardType.trainingVelocity,
    );
    final consistency = cards.firstWhere(
      (card) => card.type == InsightFeedCardType.consistencyPulse,
    );

    expect(velocity.visualType, InsightFeedVisualType.baselineBars);
    expect(velocity.visualData['items'], isA<List>());
    expect(consistency.visualType, InsightFeedVisualType.calendarStrip);
    expect(consistency.visualData['recentDays'], isA<List>());
  });

  test('new visual rule types generate only with meaningful data', () async {
    final now = DateTime(2026, 6, 20, 12);
    final benchPress = Exercise(
      slug: 'bench_press',
      name: 'Bench Press',
      primaryMuscleGroup: MuscleGroup.chest,
      secondaryMuscleGroups: const [],
      instructions: const [],
      image: '',
      animation: '',
      muscleActivation: const {MuscleGroup.chest: 1},
    );
    final service = InsightFeedService(
      assetBundle: _StringAssetBundle({
        rulesAsset: '''
{
  "rules": [
    {"id": "radar", "type": "muscleActivationRadar", "enabled": true, "priority": 90, "params": {"recentDays": 30, "minWorkouts": 1}, "visual": {"enabled": true, "type": "radar", "size": "featured", "params": {}}},
    {"id": "latest", "type": "latestWorkoutComparison", "enabled": true, "priority": 80, "params": {"baselineWorkouts": 8, "minBaselineWorkouts": 2}, "visual": {"enabled": true, "type": "baselineBars", "size": "wide", "params": {}}},
    {"id": "weight", "type": "bodyWeightTrend", "enabled": true, "priority": 70, "params": {"lookbackDays": 90, "minSamples": 2}, "visual": {"enabled": true, "type": "bodyWeightLine", "size": "wide", "params": {}}}
  ]
}
''',
      }),
      workoutsProvider: () async => [
        _workout(
          id: 'baseline-1',
          completedAt: now.subtract(const Duration(days: 10)),
        ),
        _workout(
          id: 'baseline-2',
          completedAt: now.subtract(const Duration(days: 6)),
        ),
        _workout(
          id: 'latest',
          completedAt: now.subtract(const Duration(days: 1)),
          setCount: 5,
        ),
      ],
      weightHistoryProvider: () => [
        WeightEntry(
          timestamp: now.subtract(const Duration(days: 30)),
          value: 80,
        ),
        WeightEntry(
          timestamp: now.subtract(const Duration(days: 1)),
          value: 79.2,
        ),
      ],
      exerciseCatalogProvider: () => {'bench_press': benchPress},
      activationService: _FakeWorkoutMuscleActivationService(),
      nowProvider: () => now,
      cacheStore: const InsightsCacheStore(cacheKey: 'feed-test-new-rules'),
    );

    final cards = await service.getCards(maxCards: 10);
    final types = cards.map((card) => card.type).toSet();

    expect(types, contains(InsightFeedCardType.muscleActivationRadar));
    expect(types, contains(InsightFeedCardType.latestWorkoutComparison));
    expect(types, contains(InsightFeedCardType.bodyWeightTrend));
    final latest = cards.firstWhere(
      (card) => card.type == InsightFeedCardType.latestWorkoutComparison,
    );
    expect(latest.title, 'Workout progress');
    expect(latest.comparisonLabel, isNull);
    expect(
      (latest.visualData['items'] as List<dynamic>)
          .cast<Map<String, Object?>>()
          .map((item) => item['deltaLabel']),
      ['0%', '67%', '67%'],
    );
    final radar = cards.firstWhere(
      (card) => card.type == InsightFeedCardType.muscleActivationRadar,
    );
    expect(radar.visualType, InsightFeedVisualType.radar);
    expect(radar.title, 'Muscle focus');
    expect(radar.body, 'Latest workout compared with your recent average.');
    expect(radar.comparisonLabel, 'recent average');
    expect(radar.visualData['plannedLabel'], 'recent average');
    expect(radar.visualData['actualLabel'], 'Workout latest');

    final radarPoints = (radar.visualData['points'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final chestPoint = radarPoints.firstWhere(
      (point) => point['axisId'] == 'chest',
    );
    expect(chestPoint['planned'], closeTo(11 / 15, 0.001));
    expect(chestPoint['actual'], 1);

    expect(
      cards
          .firstWhere(
            (card) => card.type == InsightFeedCardType.bodyWeightTrend,
          )
          .visualData['points'],
      isA<List>(),
    );
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

class _FakeWorkoutMuscleActivationService
    extends WorkoutMuscleActivationService {
  @override
  Future<WorkoutMuscleActivationConfig> loadConfig() async {
    return const WorkoutMuscleActivationConfig(
      primaryWeight: 1,
      secondaryWeight: 0.35,
      axes: [
        WorkoutMuscleActivationAxis(id: 'chest', label: 'Chest'),
        WorkoutMuscleActivationAxis(id: 'back', label: 'Back'),
        WorkoutMuscleActivationAxis(id: 'legs', label: 'Legs'),
      ],
      muscleContributions: {
        MuscleGroup.chest: {'chest': 1},
        MuscleGroup.back: {'back': 1},
        MuscleGroup.quads: {'legs': 1},
      },
    );
  }
}
