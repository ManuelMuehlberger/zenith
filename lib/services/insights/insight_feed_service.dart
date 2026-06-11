import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:logging/logging.dart';

import '../../models/insight_feed.dart';
import '../../models/workout.dart';
import '../insights_service.dart';
import 'cache/insights_cache_store.dart';

// policy: allow-public-api generates and caches the unfiltered insights feed.
class InsightFeedService {
  InsightFeedService({
    AssetBundle? assetBundle,
    Future<List<Workout>> Function()? workoutsProvider,
    DateTime Function()? nowProvider,
    InsightsCacheStore? cacheStore,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _workoutsProvider = workoutsProvider,
       _nowProvider = nowProvider ?? DateTime.now,
       _cacheStore =
           cacheStore ?? const InsightsCacheStore(cacheKey: _feedCacheKey);

  static final InsightFeedService instance = InsightFeedService();

  static const String defaultRulesAsset =
      'assets/insights/insight_feed_rules.json';
  static const String _feedCacheKey = 'insight_feed_cache';

  final AssetBundle _assetBundle;
  final Future<List<Workout>> Function()? _workoutsProvider;
  final DateTime Function() _nowProvider;
  final InsightsCacheStore _cacheStore;
  final Logger _logger = Logger('InsightFeedService');

  Future<List<InsightFeedCard>> getCards({
    bool forceRefresh = false,
    int maxCards = 5,
  }) async {
    final now = _nowProvider();
    final cacheEntryKey = _cacheEntryKeyFor(now);

    if (!forceRefresh) {
      final cached = await _readCachedCards(cacheEntryKey);
      if (cached != null) {
        return cached;
      }
    }

    final rules = await _loadRules();
    final workouts = await _loadWorkouts();
    final cards =
        _generateCards(
          rules: rules.where((rule) => rule.enabled).toList(growable: false),
          workouts: workouts,
          now: now,
        )..sort((a, b) {
          final priorityCompare = b.priority.compareTo(a.priority);
          if (priorityCompare != 0) {
            return priorityCompare;
          }
          return a.title.compareTo(b.title);
        });

    final capped = List<InsightFeedCard>.unmodifiable(cards.take(maxCards));
    await _writeCachedCards(cacheEntryKey, capped, now);
    return capped;
  }

  Future<void> invalidateCache() async {
    await _cacheStore.clear();
  }

  Future<List<InsightFeedCard>?> _readCachedCards(String cacheEntryKey) async {
    try {
      final snapshot = await _cacheStore.load();
      final rawEntry = snapshot?.cache[cacheEntryKey];
      if (rawEntry is! Map) {
        return null;
      }
      final rawCards = rawEntry['cards'];
      if (rawCards is! List) {
        return null;
      }
      return rawCards
          .map(
            (entry) => InsightFeedCard.fromMap(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      _logger.warning('Failed to read insight feed cache', error, stackTrace);
      return null;
    }
  }

  Future<void> _writeCachedCards(
    String cacheEntryKey,
    List<InsightFeedCard> cards,
    DateTime now,
  ) async {
    try {
      await _cacheStore.save(
        cache: {
          cacheEntryKey: {'cards': cards.map((card) => card.toMap()).toList()},
        },
        lastUpdate: now,
      );
    } catch (error, stackTrace) {
      _logger.warning('Failed to write insight feed cache', error, stackTrace);
    }
  }

  String _cacheEntryKeyFor(DateTime now) {
    final local = now.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return 'insight_feed_${local.year}-$month-$day';
  }

  Future<List<Workout>> _loadWorkouts() async {
    final provider = _workoutsProvider;
    final workouts = provider != null
        ? await provider()
        : await InsightsService.instance.getWorkouts();
    return workouts
        .where((workout) => workout.status == WorkoutStatus.completed)
        .toList(growable: false)
      ..sort((a, b) => _workoutDate(a).compareTo(_workoutDate(b)));
  }

  Future<List<InsightFeedRule>> _loadRules() async {
    final raw = await _assetBundle.loadString(defaultRulesAsset);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Insight feed rules root must be an object');
    }
    final rulesJson = decoded['rules'];
    if (rulesJson is! List) {
      throw const FormatException('Insight feed rules must contain a list');
    }
    return rulesJson
        .map(
          (entry) =>
              InsightFeedRule.fromMap(Map<String, dynamic>.from(entry as Map)),
        )
        .toList(growable: false);
  }

  List<InsightFeedCard> _generateCards({
    required List<InsightFeedRule> rules,
    required List<Workout> workouts,
    required DateTime now,
  }) {
    if (workouts.isEmpty) {
      return const [];
    }

    final cards = <InsightFeedCard>[];
    for (final rule in rules) {
      final card = switch (rule.type) {
        InsightFeedCardType.trainingVelocity => _trainingVelocity(
          rule,
          workouts,
          now,
        ),
        InsightFeedCardType.recentAchievementShoutout =>
          _recentAchievementShoutout(rule, workouts, now),
        InsightFeedCardType.highIntensityShoutout => _highIntensityShoutout(
          rule,
          workouts,
          now,
        ),
        InsightFeedCardType.consistencyPulse => _consistencyPulse(
          rule,
          workouts,
          now,
        ),
        InsightFeedCardType.comebackCard => _comebackCard(rule, workouts, now),
        InsightFeedCardType.personalBestMomentum => _personalBestMomentum(
          rule,
          workouts,
          now,
        ),
      };
      if (card != null) {
        cards.add(card);
      }
    }
    return cards;
  }

  InsightFeedCard? _trainingVelocity(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    final recentDays = _intParam(rule, 'recentDays', 7);
    final baselineDays = _intParam(rule, 'baselineDays', 90);
    final minimumDeltaPercent = _numParam(rule, 'minimumDeltaPercent', 20);
    final recentStart = now.subtract(Duration(days: recentDays));
    final baselineStart = recentStart.subtract(Duration(days: baselineDays));
    final recent = workouts
        .where((workout) {
          final date = _workoutDate(workout);
          return !date.isBefore(recentStart) && !date.isAfter(now);
        })
        .toList(growable: false);
    final baseline = workouts
        .where((workout) {
          final date = _workoutDate(workout);
          return !date.isBefore(baselineStart) && date.isBefore(recentStart);
        })
        .toList(growable: false);

    if (recent.isEmpty || baseline.length < 3) {
      return null;
    }

    final recentWeeklyPace = recent.length / recentDays * 7;
    final baselineWeeklyPace = baseline.length / baselineDays * 7;
    if (baselineWeeklyPace <= 0) {
      return null;
    }

    final deltaPercent =
        ((recentWeeklyPace - baselineWeeklyPace) / baselineWeeklyPace) * 100;
    if (deltaPercent.abs() < minimumDeltaPercent) {
      return null;
    }

    final up = deltaPercent > 0;
    final percentText = '${up ? '+' : ''}${deltaPercent.round()}%';
    return InsightFeedCard(
      id: rule.id,
      type: rule.type,
      priority: rule.priority,
      title: 'Training velocity',
      body: up
          ? 'Your last $recentDays days are moving faster than your recent baseline.'
          : 'Your last $recentDays days are lighter than your recent baseline.',
      metric: percentText,
      accent: up ? 'success' : 'warning',
      icon: 'bolt',
      generatedAt: now,
    );
  }

  InsightFeedCard? _recentAchievementShoutout(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    final maxAgeDays = _intParam(rule, 'maxAgeDays', 14);
    final cutoff = now.subtract(Duration(days: maxAgeDays));
    final achievements =
        workouts
            .expand((workout) {
              return workout.achievements.map(
                (achievement) => (workout, achievement),
              );
            })
            .where((entry) => !entry.$2.earnedAt.isBefore(cutoff))
            .toList()
          ..sort((a, b) => b.$2.earnedAt.compareTo(a.$2.earnedAt));

    if (achievements.isEmpty) {
      return null;
    }

    final entry = achievements.first;
    return InsightFeedCard(
      id: '${rule.id}_${entry.$2.id}',
      type: rule.type,
      priority: rule.priority,
      title: entry.$2.title,
      body: entry.$2.reason,
      metric: 'Earned',
      accent: 'primary',
      icon: 'award',
      generatedAt: now,
      sourceWorkoutId: entry.$1.id,
    );
  }

  InsightFeedCard? _highIntensityShoutout(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    final lookbackDays = _intParam(rule, 'lookbackDays', 90);
    final minimumPercentile = _numParam(rule, 'minimumPercentile', 90);
    final latest = workouts.last;
    final latestDate = _workoutDate(latest);
    final historyStart = latestDate.subtract(Duration(days: lookbackDays));
    final history = workouts
        .where((workout) {
          final date = _workoutDate(workout);
          return workout.id != latest.id &&
              !date.isBefore(historyStart) &&
              date.isBefore(latestDate);
        })
        .toList(growable: false);

    if (history.length < 5) {
      return null;
    }

    final percentile = _percentileAbove(
      latest.totalSets,
      history.map((workout) => workout.totalSets),
    );
    if (percentile < minimumPercentile) {
      return null;
    }

    return InsightFeedCard(
      id: '${rule.id}_${latest.id}',
      type: rule.type,
      priority: rule.priority,
      title: 'High intensity session',
      body:
          '${latest.name} landed in your top ${(100 - percentile).ceil().clamp(1, 10)}% for set count recently.',
      metric: '${percentile.round()}th',
      accent: 'warning',
      icon: 'flame',
      generatedAt: now,
      sourceWorkoutId: latest.id,
    );
  }

  InsightFeedCard? _consistencyPulse(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    final recentDays = _intParam(rule, 'recentDays', 7);
    final minimumWorkouts = _intParam(rule, 'minimumWorkouts', 2);
    final cutoff = now.subtract(Duration(days: recentDays));
    final recentCount = workouts.where((workout) {
      final date = _workoutDate(workout);
      return !date.isBefore(cutoff) && !date.isAfter(now);
    }).length;

    if (recentCount < minimumWorkouts) {
      return null;
    }

    return InsightFeedCard(
      id: rule.id,
      type: rule.type,
      priority: rule.priority,
      title: 'Consistency pulse',
      body: 'You trained $recentCount times in the last $recentDays days.',
      metric: '$recentCount/$recentDays',
      accent: 'info',
      icon: 'calendar',
      generatedAt: now,
    );
  }

  InsightFeedCard? _comebackCard(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    final minGapDays = _intParam(rule, 'minGapDays', 7);
    if (workouts.length < 2) {
      return null;
    }

    final latest = workouts.last;
    final previous = workouts[workouts.length - 2];
    final gapDays = _workoutDate(
      latest,
    ).difference(_workoutDate(previous)).inDays;
    if (gapDays < minGapDays) {
      return null;
    }

    return InsightFeedCard(
      id: '${rule.id}_${latest.id}',
      type: rule.type,
      priority: rule.priority,
      title: 'Back in motion',
      body: 'You returned with ${latest.name} after $gapDays days away.',
      metric: '${gapDays}d',
      accent: 'primary',
      icon: 'return',
      generatedAt: now,
      sourceWorkoutId: latest.id,
    );
  }

  InsightFeedCard? _personalBestMomentum(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    if (workouts.length < 2) {
      return null;
    }

    final latest = workouts.last;
    final previousBest = workouts
        .take(workouts.length - 1)
        .map((workout) => workout.totalWeight)
        .fold<double>(0, math.max);
    if (latest.totalWeight <= 0 || latest.totalWeight <= previousBest) {
      return null;
    }

    return InsightFeedCard(
      id: '${rule.id}_${latest.id}',
      type: rule.type,
      priority: rule.priority,
      title: 'New volume best',
      body: '${latest.name} moved more total volume than any prior workout.',
      metric: latest.totalWeight.round().toString(),
      accent: 'success',
      icon: 'chart',
      generatedAt: now,
      sourceWorkoutId: latest.id,
    );
  }

  DateTime _workoutDate(Workout workout) {
    return workout.completedAt ??
        workout.startedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  double _percentileAbove(num current, Iterable<num> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      return 0;
    }
    final lower = list.where((value) => current > value).length;
    return math.min(100, math.max(0, lower / list.length * 100));
  }

  int _intParam(InsightFeedRule rule, String key, int fallback) {
    final value = rule.params[key];
    return value is num ? value.round() : fallback;
  }

  double _numParam(InsightFeedRule rule, String key, num fallback) {
    final value = rule.params[key];
    return value is num ? value.toDouble() : fallback.toDouble();
  }
}
