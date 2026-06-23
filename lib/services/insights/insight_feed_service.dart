import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:logging/logging.dart';

import '../../models/exercise.dart';
import '../../models/insight_feed.dart';
import '../../models/user_data.dart';
import '../../models/workout.dart';
import '../exercise_service.dart';
import '../insights_service.dart';
import '../user_service.dart';
import '../workout_muscle_activation_service.dart';
import 'cache/insights_cache_store.dart';

// policy: allow-public-api generates and caches the unfiltered insights feed.
class InsightFeedService {
  InsightFeedService({
    AssetBundle? assetBundle,
    Future<List<Workout>> Function()? workoutsProvider,
    List<WeightEntry> Function()? weightHistoryProvider,
    Map<String, Exercise> Function()? exerciseCatalogProvider,
    DateTime Function()? nowProvider,
    InsightsCacheStore? cacheStore,
    WorkoutMuscleActivationService? activationService,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _workoutsProvider = workoutsProvider,
       _weightHistoryProvider = weightHistoryProvider,
       _exerciseCatalogProvider = exerciseCatalogProvider,
       _nowProvider = nowProvider ?? DateTime.now,
       _activationService =
           activationService ?? WorkoutMuscleActivationService(),
       _cacheStore =
           cacheStore ?? const InsightsCacheStore(cacheKey: _feedCacheKey);

  static final InsightFeedService instance = InsightFeedService();

  static const String defaultRulesAsset =
      'assets/insights/insight_feed_rules.json';
  static const String _feedCacheKey = 'insight_feed_cache';
  static const int _feedCacheVersion = 5;
  static const int _feedStackCacheVersion = 4;

  final AssetBundle _assetBundle;
  final Future<List<Workout>> Function()? _workoutsProvider;
  final List<WeightEntry> Function()? _weightHistoryProvider;
  final Map<String, Exercise> Function()? _exerciseCatalogProvider;
  final DateTime Function() _nowProvider;
  final WorkoutMuscleActivationService _activationService;
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
        await _generateCards(
            rules: rules.where((rule) => rule.enabled).toList(growable: false),
            workouts: workouts,
            now: now,
          )
          ..sort((a, b) {
            return _compareCards(a, b);
          });

    final capped = List<InsightFeedCard>.unmodifiable(cards.take(maxCards));
    await _writeCachedCards(cacheEntryKey, capped, now);
    return capped;
  }

  Future<List<InsightFeedStack>> getCardStacks({
    bool forceRefresh = false,
  }) async {
    final now = _nowProvider();
    final cacheEntryKey = '${_cacheEntryKeyFor(now)}_stacks';

    if (!forceRefresh) {
      final cached = await _readCachedStacks(cacheEntryKey);
      if (cached != null) {
        return cached;
      }
    }

    final config = await _loadConfig();
    final workouts = await _loadWorkouts();
    final stacks = await _generateStacks(
      config: config,
      workouts: workouts,
      now: now,
    );

    await _writeCachedStacks(cacheEntryKey, stacks, now);
    return stacks;
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
      if (rawEntry['version'] != _feedCacheVersion) {
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

  Future<List<InsightFeedStack>?> _readCachedStacks(
    String cacheEntryKey,
  ) async {
    try {
      final snapshot = await _cacheStore.load();
      final rawEntry = snapshot?.cache[cacheEntryKey];
      if (rawEntry is! Map) {
        return null;
      }
      final rawStacks = rawEntry['stacks'];
      if (rawStacks is! List) {
        return null;
      }
      if (rawEntry['version'] != _feedStackCacheVersion) {
        return null;
      }
      return rawStacks
          .map(
            (entry) => InsightFeedStack.fromMap(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      _logger.warning(
        'Failed to read insight feed stack cache',
        error,
        stackTrace,
      );
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
          cacheEntryKey: {
            'version': _feedCacheVersion,
            'cards': cards.map((card) => card.toMap()).toList(),
          },
        },
        lastUpdate: now,
      );
    } catch (error, stackTrace) {
      _logger.warning('Failed to write insight feed cache', error, stackTrace);
    }
  }

  Future<void> _writeCachedStacks(
    String cacheEntryKey,
    List<InsightFeedStack> stacks,
    DateTime now,
  ) async {
    try {
      await _cacheStore.save(
        cache: {
          cacheEntryKey: {
            'version': _feedStackCacheVersion,
            'stacks': stacks.map((stack) => stack.toMap()).toList(),
          },
        },
        lastUpdate: now,
      );
    } catch (error, stackTrace) {
      _logger.warning(
        'Failed to write insight feed stack cache',
        error,
        stackTrace,
      );
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

  Future<InsightFeedConfig> _loadConfig() async {
    final raw = await _assetBundle.loadString(defaultRulesAsset);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Insight feed rules root must be an object');
    }
    return InsightFeedConfig.fromMap(decoded);
  }

  Future<List<InsightFeedRule>> _loadRules() async {
    return (await _loadConfig()).rules;
  }

  Future<List<InsightFeedStack>> _generateStacks({
    required InsightFeedConfig config,
    required List<Workout> workouts,
    required DateTime now,
  }) async {
    if (workouts.isEmpty) {
      return const [];
    }

    final enabledStacks =
        config.stacks
            .where(
              (stack) =>
                  stack.enabled &&
                  workouts.length >= stack.minCompletedWorkouts &&
                  stack.maxCards > 0,
            )
            .toList(growable: false)
          ..sort((a, b) {
            final priorityCompare = b.priority.compareTo(a.priority);
            if (priorityCompare != 0) {
              return priorityCompare;
            }
            return a.title.compareTo(b.title);
          });
    if (enabledStacks.isEmpty) {
      return const [];
    }

    final enabledStackIds = enabledStacks.map((stack) => stack.id).toSet();
    final cards = await _generateCards(
      rules: config.rules
          .where(
            (rule) => rule.enabled && enabledStackIds.contains(rule.stackId),
          )
          .toList(growable: false),
      workouts: workouts,
      now: now,
    );
    final cardsByStack = <String, List<InsightFeedCard>>{};
    for (final card in cards) {
      final rule = config.rules.firstWhere(
        (candidate) => candidate.type == card.type,
      );
      cardsByStack.putIfAbsent(rule.stackId, () => []).add(card);
    }

    final stacks = <InsightFeedStack>[];
    for (final stackConfig in enabledStacks) {
      final stackCards = cardsByStack[stackConfig.id];
      if (stackCards == null || stackCards.isEmpty) {
        continue;
      }
      stackCards.sort(_compareCards);
      stacks.add(
        InsightFeedStack(
          id: stackConfig.id,
          title: stackConfig.title,
          priority: stackConfig.priority,
          cards: List<InsightFeedCard>.unmodifiable(
            stackCards.take(stackConfig.maxCards),
          ),
        ),
      );
    }
    return List<InsightFeedStack>.unmodifiable(stacks);
  }

  int _compareCards(InsightFeedCard a, InsightFeedCard b) {
    final priorityCompare = b.priority.compareTo(a.priority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return a.title.compareTo(b.title);
  }

  Future<List<InsightFeedCard>> _generateCards({
    required List<InsightFeedRule> rules,
    required List<Workout> workouts,
    required DateTime now,
  }) async {
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
        InsightFeedCardType.muscleActivationRadar =>
          await _muscleActivationRadar(rule, workouts, now),
        InsightFeedCardType.latestWorkoutComparison => _latestWorkoutComparison(
          rule,
          workouts,
          now,
        ),
        InsightFeedCardType.bodyWeightTrend => _bodyWeightTrend(rule, now),
        InsightFeedCardType.trainingBalance => await _trainingBalance(
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
    if (recentDays <= 0 || baselineDays <= 0) {
      return null;
    }
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
    return _card(
      rule: rule,
      id: rule.id,
      title: 'Training velocity',
      body:
          '${recentWeeklyPace.toStringAsFixed(1)} workouts/week in the last $recentDays days.',
      metric: percentText,
      accent: up ? 'success' : 'warning',
      icon: 'bolt',
      generatedAt: now,
      detailMetricLabel: 'Workout rate',
      comparisonLabel:
          'Previous $baselineDays days average: ${baselineWeeklyPace.toStringAsFixed(1)} workouts/week',
      visualData: _trainingVelocityVisualData(
        workouts: workouts,
        now: now,
        recentDays: recentDays,
        baselineDays: baselineDays,
        recentValue: recentWeeklyPace,
        baselineValue: baselineWeeklyPace,
      ),
    );
  }

  InsightFeedCard? _recentAchievementShoutout(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    final maxAgeDays = _intParam(rule, 'maxAgeDays', 14);
    if (maxAgeDays <= 0) {
      return null;
    }
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
    return _card(
      rule: rule,
      id: '${rule.id}_${entry.$2.id}',
      title: entry.$2.title,
      body: entry.$2.reason,
      metric: '',
      accent: 'primary',
      icon: 'award',
      generatedAt: now,
      sourceWorkoutId: entry.$1.id,
      detailMetricLabel: 'Awards gained',
      visualData: {
        'achievements': [entry.$2.toMap()],
      },
    );
  }

  InsightFeedCard? _highIntensityShoutout(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    final lookbackDays = _intParam(rule, 'lookbackDays', 90);
    final minimumPercentile = _numParam(rule, 'minimumPercentile', 90);
    if (lookbackDays <= 0 || minimumPercentile <= 0) {
      return null;
    }
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

    return _card(
      rule: rule,
      id: '${rule.id}_${latest.id}',
      title: 'High intensity session',
      body:
          '${latest.name} landed in your top ${(100 - percentile).ceil().clamp(1, 10)}% for set count recently.',
      metric: '${percentile.round()}th',
      accent: 'warning',
      icon: 'flame',
      generatedAt: now,
      sourceWorkoutId: latest.id,
      detailMetricLabel: 'Set count percentile',
      comparisonLabel: 'Last $lookbackDays days',
      visualData: {
        'current': latest.totalSets,
        'values': history.map((workout) => workout.totalSets).toList(),
        'percentile': percentile,
        'unit': 'sets',
      },
    );
  }

  InsightFeedCard? _consistencyPulse(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    final recentDays = _intParam(rule, 'recentDays', 7);
    final minimumWorkouts = _intParam(rule, 'minimumWorkouts', 2);
    if (recentDays <= 0 || minimumWorkouts <= 0) {
      return null;
    }
    final cutoff = now.subtract(Duration(days: recentDays));
    final recentCount = workouts.where((workout) {
      final date = _workoutDate(workout);
      return !date.isBefore(cutoff) && !date.isAfter(now);
    }).length;

    if (recentCount < minimumWorkouts) {
      return null;
    }

    final baselineStart = cutoff.subtract(Duration(days: recentDays));
    final recentDaysSet = _workoutDayKeys(
      workouts.where((workout) {
        final date = _workoutDate(workout);
        return !date.isBefore(cutoff) && !date.isAfter(now);
      }),
    );
    final baselineDaysSet = _workoutDayKeys(
      workouts.where((workout) {
        final date = _workoutDate(workout);
        return !date.isBefore(baselineStart) && date.isBefore(cutoff);
      }),
    );

    final recentDates = List.generate(recentDays, (index) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: recentDays - index - 1));
    });
    final baselineDates = List.generate(recentDays, (index) {
      return DateTime(
        cutoff.year,
        cutoff.month,
        cutoff.day,
      ).subtract(Duration(days: recentDays - index));
    });
    final futureDates = List.generate(3, (index) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: index + 1));
    });

    return _card(
      rule: rule,
      id: rule.id,
      title: 'Training rhythm',
      body: _trainingRhythmBody(
        recentCount: recentCount,
        recentActiveDays: recentDaysSet.length,
        baselineActiveDays: baselineDaysSet.length,
        recentDays: recentDays,
      ),
      metric: '$recentCount/$recentDays',
      accent: 'info',
      icon: 'calendar',
      generatedAt: now,
      detailMetricLabel: 'Active days',
      visualData: {
        'recentDays': recentDates
            .map((date) {
              return recentDaysSet.contains(_dayKey(date));
            })
            .toList(growable: false),
        'recentLabels': recentDates.map(_dayTickLabel).toList(growable: false),
        'baselineDays': baselineDates
            .map((date) {
              return baselineDaysSet.contains(_dayKey(date));
            })
            .toList(growable: false),
        'baselineLabels': baselineDates
            .map(_dayTickLabel)
            .toList(growable: false),
        'futureLabels': futureDates.map(_dayTickLabel).toList(growable: false),
        'recentCount': recentCount,
        'baselineCount': baselineDaysSet.length,
      },
    );
  }

  String _trainingRhythmBody({
    required int recentCount,
    required int recentActiveDays,
    required int baselineActiveDays,
    required int recentDays,
  }) {
    final activeRate = recentActiveDays / recentDays;
    final band = recentActiveDays > baselineActiveDays
        ? 'rising'
        : recentActiveDays < baselineActiveDays
        ? 'dipped'
        : activeRate >= 0.4
        ? 'steady'
        : 'building';
    final workoutLabel = _pluralize(recentCount, 'workout');
    final activeDayLabel = _pluralize(recentActiveDays, 'active day');
    final windowLabel = _pluralize(recentDays, 'day');
    final candidates = <({String band, int impact, String text})>[
      (
        band: 'rising',
        impact: 100,
        text:
            'Your rhythm is picking up: $workoutLabel across $activeDayLabel recently.',
      ),
      (
        band: 'rising',
        impact: 80,
        text:
            'You found more training days than the prior window. $workoutLabel in the last $windowLabel.',
      ),
      (
        band: 'steady',
        impact: 90,
        text:
            'A steady rhythm: $workoutLabel across $activeDayLabel in this window.',
      ),
      (
        band: 'steady',
        impact: 70,
        text:
            'Your training cadence is holding nicely. $activeDayLabel logged in the last $windowLabel.',
      ),
      (
        band: 'dipped',
        impact: 85,
        text:
            'This stretch was a little lighter, with $workoutLabel in the last $windowLabel.',
      ),
      (
        band: 'dipped',
        impact: 65,
        text:
            'A lighter stretch: $activeDayLabel recently. There is room to ease back into the next slot.',
      ),
      (
        band: 'building',
        impact: 75,
        text:
            'You logged $workoutLabel in the last $windowLabel. Keep the next slot in view.',
      ),
      (
        band: 'building',
        impact: 55,
        text:
            'A few recent sessions are on the board. You can build from $activeDayLabel.',
      ),
    ];
    return candidates
        .where((candidate) => candidate.band == band)
        .reduce(
          (best, candidate) =>
              candidate.impact > best.impact ? candidate : best,
        )
        .text;
  }

  String _pluralize(int count, String noun) {
    return '$count $noun${count == 1 ? '' : 's'}';
  }

  InsightFeedCard? _comebackCard(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    final minGapDays = _intParam(rule, 'minGapDays', 7);
    if (minGapDays <= 0) {
      return null;
    }
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

    return _card(
      rule: rule,
      id: '${rule.id}_${latest.id}',
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

    return _card(
      rule: rule,
      id: '${rule.id}_${latest.id}',
      title: 'New volume best',
      body: '${latest.name} moved more total volume than any prior workout.',
      metric: latest.totalWeight.round().toString(),
      accent: 'success',
      icon: 'chart',
      generatedAt: now,
      sourceWorkoutId: latest.id,
      detailMetricLabel: 'Total volume',
      comparisonLabel: 'Previous best ${previousBest.round()}',
      visualData: _volumeSparklineVisualData(
        workouts,
        _intVisualParam(rule, 'lookbackDays', 120),
        now,
        previousBest,
      ),
    );
  }

  Future<InsightFeedCard?> _muscleActivationRadar(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) async {
    if (!rule.visual.enabled) {
      return null;
    }
    final recentDays = _intParam(rule, 'recentDays', 30);
    final minWorkouts = _intParam(rule, 'minWorkouts', 1);
    if (recentDays <= 0 || minWorkouts <= 0) {
      return null;
    }
    final windowStart = now.subtract(Duration(days: recentDays));
    final recentWorkouts = _hydrateWorkouts(
      workouts
          .where((workout) {
            final date = _workoutDate(workout);
            return !date.isBefore(windowStart) && !date.isAfter(now);
          })
          .toList(growable: false),
    )..sort((a, b) => _workoutDate(b).compareTo(_workoutDate(a)));

    if (recentWorkouts.length < minWorkouts) {
      return null;
    }

    final config = await _activationService.loadConfig();
    final windowTotals =
        WorkoutMuscleActivationService.buildWorkoutsAxisActivation(
          recentWorkouts,
          config,
        );
    final averageWindowTotals = _averageTotals(
      windowTotals,
      recentWorkouts.length,
    );
    final latestTotals =
        WorkoutMuscleActivationService.buildWorkoutAxisActivation(
          recentWorkouts.first,
          config,
        );
    final normalizer = _normalizerFor(averageWindowTotals, latestTotals);
    final points = config.axes
        .map((axis) {
          return {
            'axisId': axis.id,
            'label': axis.label,
            'planned': averageWindowTotals.actualFor(axis.id) / normalizer,
            'actual': latestTotals.actualFor(axis.id) / normalizer,
          };
        })
        .toList(growable: false);

    final hasActivation = points.any((point) {
      return ((point['planned'] as double?) ?? 0) > 0 ||
          ((point['actual'] as double?) ?? 0) > 0;
    });
    if (!hasActivation || points.length < 3) {
      return null;
    }

    const referenceLabel = 'recent average';
    final latestWorkoutLabel = _latestWorkoutLabel(recentWorkouts.first);

    return _card(
      rule: rule,
      id: rule.id,
      title: 'Muscle focus',
      body: 'Latest workout compared with your $referenceLabel.',
      metric: '${recentWorkouts.length}',
      accent: 'primary',
      icon: 'radar',
      generatedAt: now,
      sourceWorkoutId: recentWorkouts.first.id,
      detailMetricLabel: 'Recent workouts',
      comparisonLabel: referenceLabel,
      visualData: {
        'points': points,
        'plannedLabel': referenceLabel,
        'actualLabel': latestWorkoutLabel,
      },
    );
  }

  InsightFeedCard? _latestWorkoutComparison(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) {
    if (!rule.visual.enabled || workouts.length < 2) {
      return null;
    }
    final latest = workouts.last;
    final baselineDays = _intParam(rule, 'baselineDays', 30);
    final minBaselineWorkouts = _intParam(rule, 'minBaselineWorkouts', 2);
    if (baselineDays <= 0 || minBaselineWorkouts <= 0) {
      return null;
    }
    final latestDate = _workoutDate(latest);
    final baselineStart = latestDate.subtract(Duration(days: baselineDays));
    final baseline = workouts
        .take(workouts.length - 1)
        .where((workout) {
          final date = _workoutDate(workout);
          return !date.isBefore(baselineStart) && date.isBefore(latestDate);
        })
        .toList(growable: false);
    if (baseline.length < minBaselineWorkouts) {
      return null;
    }

    final latestDuration = _durationMinutes(latest);
    final baselineDuration =
        baseline.map(_durationMinutes).fold<double>(0, (sum, v) => sum + v) /
        baseline.length;
    final latestSets = latest.completedSets.toDouble();
    final baselineSets =
        baseline
            .map((w) => w.completedSets.toDouble())
            .fold<double>(0, (sum, v) => sum + v) /
        baseline.length;
    final latestVolume = latest.totalWeight;
    final baselineVolume =
        baseline
            .map((w) => w.totalWeight)
            .fold<double>(0, (sum, v) => sum + v) /
        baseline.length;

    final deltaPercent = _deltaPercent(
      baseline: baselineVolume,
      actual: latestVolume,
    );
    final metric = baselineVolume > 0
        ? '${deltaPercent >= 0 ? '+' : ''}${deltaPercent.round()}%'
        : '${latestSets.round()} sets';

    return _card(
      rule: rule,
      id: '${rule.id}_${latest.id}',
      title: 'Workout progress',
      body: '${latest.name} compared with your recent baseline.',
      metric: metric,
      accent: deltaPercent >= 0 ? 'success' : 'info',
      icon: 'chart',
      generatedAt: now,
      sourceWorkoutId: latest.id,
      detailMetricLabel: 'Latest vs baseline',
      visualData: {
        'items': [
          {
            'label': 'Duration',
            'baseline': baselineDuration,
            'actual': latestDuration,
            'deltaLabel': _deltaLabel(
              baseline: baselineDuration,
              actual: latestDuration,
            ),
            'unit': 'min',
          },
          {
            'label': 'Sets',
            'baseline': baselineSets,
            'actual': latestSets,
            'deltaLabel': _deltaLabel(
              baseline: baselineSets,
              actual: latestSets,
            ),
            'unit': 'sets',
          },
          {
            'label': 'Volume',
            'baseline': baselineVolume,
            'actual': latestVolume,
            'deltaLabel': _deltaLabel(
              baseline: baselineVolume,
              actual: latestVolume,
            ),
            'unit': '',
          },
        ],
      },
    );
  }

  InsightFeedCard? _bodyWeightTrend(InsightFeedRule rule, DateTime now) {
    if (!rule.visual.enabled) {
      return null;
    }
    final lookbackDays = _intParam(rule, 'lookbackDays', 90);
    final minSamples = _intParam(rule, 'minSamples', 2);
    if (lookbackDays <= 0 || minSamples < 2) {
      return null;
    }
    final cutoff = now.subtract(Duration(days: lookbackDays));
    final entries = [..._weightHistory()]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final visible = entries
        .where((entry) {
          return !entry.timestamp.isBefore(cutoff) &&
              !entry.timestamp.isAfter(now);
        })
        .toList(growable: false);

    if (visible.length < minSamples) {
      return null;
    }

    final first = visible.first.value;
    final latest = visible.last.value;
    final delta = latest - first;
    final metric = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}';

    return _card(
      rule: rule,
      id: rule.id,
      title: 'Body weight trend',
      body: 'Your latest body weight compared with recent entries.',
      metric: metric,
      accent: 'info',
      icon: 'weight',
      generatedAt: now,
      detailMetricLabel: 'Latest entry',
      visualData: {
        'points': visible
            .map(
              (entry) => {
                'label': '${entry.timestamp.month}/${entry.timestamp.day}',
                'date': entry.timestamp.toIso8601String(),
                'value': entry.value,
              },
            )
            .toList(growable: false),
        'baseline': first,
        'latest': latest,
        'unit': '',
      },
    );
  }

  Future<InsightFeedCard?> _trainingBalance(
    InsightFeedRule rule,
    List<Workout> workouts,
    DateTime now,
  ) async {
    if (!rule.visual.enabled) {
      return null;
    }
    final lookbackDays = _intParam(rule, 'lookbackDays', 180);
    final minCompletedWorkouts = _intParam(rule, 'minCompletedWorkouts', 8);
    if (lookbackDays <= 0 || minCompletedWorkouts <= 0) {
      return null;
    }

    final cutoff = now.subtract(Duration(days: lookbackDays));
    final visibleWorkouts = _hydrateWorkouts(
      workouts
          .where((workout) {
            final date = _workoutDate(workout);
            return !date.isBefore(cutoff) && !date.isAfter(now);
          })
          .toList(growable: false),
    );
    if (visibleWorkouts.length < minCompletedWorkouts) {
      return null;
    }

    final config = await _activationService.loadConfig();
    final totals = WorkoutMuscleActivationService.buildWorkoutsAxisActivation(
      visibleWorkouts,
      config,
    );
    final activeAxes = config.axes
        .map((axis) {
          return (axis: axis, value: totals.actualFor(axis.id));
        })
        .where((entry) => entry.value > 0)
        .toList(growable: false);
    if (activeAxes.length < 3) {
      return null;
    }

    final totalActivation = activeAxes.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );
    if (totalActivation <= 0) {
      return null;
    }

    final distribution =
        activeAxes
            .map(
              (entry) => (
                axis: entry.axis,
                value: entry.value,
                percent: entry.value / totalActivation,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.value.compareTo(a.value));

    final dominant = distribution.first;
    final focus = distribution.reduce(
      (lowest, entry) => entry.percent < lowest.percent ? entry : lowest,
    );
    final balanceScore = _balanceScore(
      distribution.map((entry) => entry.percent),
    );
    final metric = '${balanceScore.round()}%';
    final segments = _balanceFingerprintSegments(distribution);

    if (segments.length < 3) {
      return null;
    }

    return _card(
      rule: rule,
      id: rule.id,
      title: 'Training balance',
      body: _trainingBalanceBody(
        score: balanceScore,
        dominantLabel: dominant.axis.label,
        focusLabel: focus.axis.label,
      ),
      metric: metric,
      accent: balanceScore >= 72 ? 'success' : 'info',
      icon: 'chart',
      generatedAt: now,
      detailMetricLabel: 'Balance score',
      comparisonLabel: 'Last $lookbackDays days',
      visualData: {
        'segments': segments,
        'dominantLabel': dominant.axis.label,
        'focusLabel': focus.axis.label,
        'balanceScore': balanceScore,
        'lookbackDays': lookbackDays,
      },
    );
  }

  String _trainingBalanceBody({
    required double score,
    required String dominantLabel,
    required String focusLabel,
  }) {
    final band = score < 50
        ? 'low'
        : score < 75
        ? 'medium'
        : 'high';
    final candidates = <({String band, int impact, String text})>[
      (
        band: 'low',
        impact: 100,
        text:
            'Your long-term work is heavily tilted toward $dominantLabel. Prioritize $focusLabel next.',
      ),
      (
        band: 'low',
        impact: 80,
        text:
            '$dominantLabel has dominated this block. Give $focusLabel the next clear slot.',
      ),
      (
        band: 'low',
        impact: 70,
        text:
            'The biggest balance gain is $focusLabel. $dominantLabel is already well covered.',
      ),
      (
        band: 'medium',
        impact: 90,
        text:
            'Your long-term work leans $dominantLabel. Prioritize $focusLabel next.',
      ),
      (
        band: 'medium',
        impact: 75,
        text:
            '$dominantLabel is leading the mix. Add more $focusLabel to even it out.',
      ),
      (
        band: 'medium',
        impact: 65,
        text:
            '$focusLabel is the quiet spot in this block while $dominantLabel carries more load.',
      ),
      (
        band: 'high',
        impact: 60,
        text:
            'Your long-term split is fairly balanced. Keep $focusLabel in rotation.',
      ),
      (
        band: 'high',
        impact: 50,
        text:
            'Good overall balance. $focusLabel is still the area to protect next.',
      ),
      (
        band: 'high',
        impact: 40,
        text:
            'The mix is steady, with $dominantLabel slightly ahead and $focusLabel worth a nudge.',
      ),
    ];
    return candidates
        .where((candidate) => candidate.band == band)
        .reduce(
          (best, candidate) =>
              candidate.impact > best.impact ? candidate : best,
        )
        .text;
  }

  InsightFeedCard _card({
    required InsightFeedRule rule,
    required String id,
    required String title,
    required String body,
    required String metric,
    required String accent,
    required String icon,
    required DateTime generatedAt,
    String? sourceWorkoutId,
    String? detailMetricLabel,
    String? comparisonLabel,
    Map<String, Object?> visualData = const {},
  }) {
    final hasVisual = rule.visual.enabled && visualData.isNotEmpty;
    return InsightFeedCard(
      id: id,
      type: rule.type,
      priority: rule.priority,
      title: title,
      body: body,
      metric: metric,
      accent: accent,
      icon: icon,
      generatedAt: generatedAt,
      sourceWorkoutId: sourceWorkoutId,
      visualType: hasVisual ? rule.visual.type : InsightFeedVisualType.none,
      size: hasVisual ? rule.visual.size : InsightFeedCardSize.wide,
      visualData: hasVisual ? Map.unmodifiable(visualData) : const {},
      detailMetricLabel: detailMetricLabel,
      comparisonLabel: comparisonLabel,
    );
  }

  Map<String, Object?> _trainingVelocityVisualData({
    required List<Workout> workouts,
    required DateTime now,
    required int recentDays,
    required int baselineDays,
    required double recentValue,
    required double baselineValue,
  }) {
    final totalDays = recentDays + baselineDays;
    final windowDays = math.max(1, recentDays);
    final sampleStepDays = math.min(7, windowDays);
    final earliestAnchor = now
        .subtract(Duration(days: totalDays))
        .add(Duration(days: windowDays));
    final points = <Map<String, Object?>>[];
    var anchor = earliestAnchor;

    while (anchor.isBefore(now)) {
      points.add(_trainingVelocityPoint(workouts, anchor, windowDays));
      anchor = anchor.add(Duration(days: sampleStepDays));
    }
    points.add(_trainingVelocityPoint(workouts, now, windowDays));

    return {
      'points': points,
      'average': baselineValue,
      'averageLabel': 'base',
      'seriesLabel': 'weekly',
      'unit': 'workouts/week',
      'summaryItems': [
        {
          'color': 'accent',
          'label': 'Recent',
          'value': recentValue,
          'displayValue': '${recentValue.toStringAsFixed(1)}/wk',
        },
        {
          'color': 'baseline',
          'label': 'Baseline',
          'value': baselineValue,
          'displayValue': '${baselineValue.toStringAsFixed(1)}/wk',
        },
      ],
    };
  }

  Map<String, Object?> _trainingVelocityPoint(
    List<Workout> workouts,
    DateTime anchor,
    int windowDays,
  ) {
    final windowStart = anchor.subtract(Duration(days: windowDays));
    final count = workouts.where((workout) {
      final date = _workoutDate(workout);
      return !date.isBefore(windowStart) && !date.isAfter(anchor);
    }).length;

    return {
      'label': '${anchor.month}/${anchor.day}',
      'value': count / windowDays * 7,
    };
  }

  Map<String, Object?> _volumeSparklineVisualData(
    List<Workout> workouts,
    int lookbackDays,
    DateTime now,
    double previousBest,
  ) {
    if (lookbackDays <= 0) {
      return const {};
    }
    final cutoff = now.subtract(Duration(days: lookbackDays));
    final visible = workouts
        .where((workout) {
          final date = _workoutDate(workout);
          return !date.isBefore(cutoff) && !date.isAfter(now);
        })
        .toList(growable: false);
    if (visible.length < 2) {
      return const {};
    }

    return {
      'points': visible
          .map(
            (workout) => {
              'label':
                  '${_workoutDate(workout).month}/${_workoutDate(workout).day}',
              'value': workout.totalWeight,
            },
          )
          .toList(growable: false),
      'baseline': previousBest,
      'unit': 'volume',
    };
  }

  double _balanceScore(Iterable<double> percentages) {
    final values = percentages.toList(growable: false);
    if (values.length < 2) {
      return 0;
    }
    final ideal = 1 / values.length;
    final deviation = values.fold<double>(
      0,
      (sum, value) => sum + (value - ideal).abs(),
    );
    final maxDeviation = 2 * (1 - ideal);
    if (maxDeviation <= 0) {
      return 0;
    }
    return ((1 - deviation / maxDeviation) * 100).clamp(0, 100).toDouble();
  }

  List<Map<String, Object?>> _balanceFingerprintSegments(
    List<({WorkoutMuscleActivationAxis axis, double value, double percent})>
    distribution,
  ) {
    const tinySegmentThreshold = 0.06;
    final shouldGroupTinySegments = distribution.length > 5;
    final visible = <Map<String, Object?>>[];
    var otherValue = 0.0;
    var otherPercent = 0.0;

    for (final entry in distribution) {
      if (shouldGroupTinySegments && entry.percent < tinySegmentThreshold) {
        otherValue += entry.value;
        otherPercent += entry.percent;
        continue;
      }
      visible.add({
        'axisId': entry.axis.id,
        'label': entry.axis.label,
        'value': entry.value,
        'percent': entry.percent,
      });
    }

    if (otherValue > 0 && otherPercent > 0) {
      visible.add({
        'axisId': 'other',
        'label': 'Other',
        'value': otherValue,
        'percent': otherPercent,
      });
    }

    return visible;
  }

  Set<String> _workoutDayKeys(Iterable<Workout> workouts) {
    return workouts.map((workout) => _dayKey(_workoutDate(workout))).toSet();
  }

  String _dayKey(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  String _dayTickLabel(DateTime date) {
    final local = date.toLocal();
    return '${local.day} ${_monthShortLabel(local.month)}';
  }

  String _monthShortLabel(int month) {
    return switch (month) {
      DateTime.january => 'Jan',
      DateTime.february => 'Feb',
      DateTime.march => 'Mar',
      DateTime.april => 'Apr',
      DateTime.may => 'May',
      DateTime.june => 'Jun',
      DateTime.july => 'Jul',
      DateTime.august => 'Aug',
      DateTime.september => 'Sep',
      DateTime.october => 'Oct',
      DateTime.november => 'Nov',
      DateTime.december => 'Dec',
      _ => '',
    };
  }

  double _durationMinutes(Workout workout) {
    final startedAt = workout.startedAt;
    final completedAt = workout.completedAt;
    if (startedAt == null || completedAt == null) {
      return 0;
    }
    return completedAt.difference(startedAt).inMinutes.toDouble();
  }

  List<Workout> _hydrateWorkouts(List<Workout> workouts) {
    final catalog = _exerciseCatalog();
    if (catalog.isEmpty) {
      return workouts;
    }

    return workouts
        .map((workout) {
          final exercises = workout.exercises
              .map((exercise) {
                if (exercise.exerciseDetail != null) {
                  return exercise;
                }
                final detail = catalog[exercise.exerciseSlug];
                if (detail == null) {
                  return exercise;
                }
                return exercise.copyWith(exerciseDetail: detail);
              })
              .toList(growable: false);
          return workout.copyWith(exercises: exercises);
        })
        .toList(growable: false);
  }

  Map<String, Exercise> _exerciseCatalog() {
    final provider = _exerciseCatalogProvider;
    if (provider != null) {
      return provider();
    }
    return {
      for (final exercise in ExerciseService.instance.exercises)
        exercise.slug: exercise,
    };
  }

  String _latestWorkoutLabel(Workout workout) {
    final trimmedName = workout.name.trim();
    return trimmedName.isEmpty ? 'Last workout' : trimmedName;
  }

  List<WeightEntry> _weightHistory() {
    return _weightHistoryProvider?.call() ??
        UserService.instance.currentProfile?.weightHistory ??
        const [];
  }

  double _normalizerFor(
    WorkoutMuscleActivationTotals windowTotals,
    WorkoutMuscleActivationTotals latestWorkoutTotals,
  ) {
    var maxValue = 0.0;
    for (final value in windowTotals.actualByAxis.values) {
      if (value > maxValue) {
        maxValue = value;
      }
    }
    for (final value in latestWorkoutTotals.actualByAxis.values) {
      if (value > maxValue) {
        maxValue = value;
      }
    }
    return maxValue <= 0 ? 1 : maxValue;
  }

  WorkoutMuscleActivationTotals _averageTotals(
    WorkoutMuscleActivationTotals totals,
    int workoutCount,
  ) {
    if (workoutCount <= 1) {
      return totals;
    }
    return WorkoutMuscleActivationTotals(
      plannedByAxis: {
        for (final entry in totals.plannedByAxis.entries)
          entry.key: entry.value / workoutCount,
      },
      actualByAxis: {
        for (final entry in totals.actualByAxis.entries)
          entry.key: entry.value / workoutCount,
      },
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

  double _deltaPercent({required double baseline, required double actual}) {
    if (baseline <= 0) {
      return 0;
    }
    return ((actual - baseline) / baseline) * 100;
  }

  String _deltaLabel({required double baseline, required double actual}) {
    if (baseline <= 0) {
      return '';
    }
    final delta = _deltaPercent(baseline: baseline, actual: actual).round();
    return '$delta%';
  }

  double _numParam(InsightFeedRule rule, String key, num fallback) {
    final value = rule.params[key];
    return value is num ? value.toDouble() : fallback.toDouble();
  }

  int _intVisualParam(InsightFeedRule rule, String key, int fallback) {
    final value = rule.visual.params[key];
    return value is num ? value.round() : fallback;
  }
}
