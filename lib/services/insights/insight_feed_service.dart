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
  static const int _feedCacheVersion = 2;

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
    return _card(
      rule: rule,
      id: rule.id,
      title: 'Training velocity',
      body: up
          ? 'Your last $recentDays days are moving faster than your recent baseline.'
          : 'Your last $recentDays days are lighter than your recent baseline.',
      metric: percentText,
      accent: up ? 'success' : 'warning',
      icon: 'bolt',
      generatedAt: now,
      detailMetricLabel: 'Recent vs baseline',
      comparisonLabel: 'Baseline ${baselineWeeklyPace.toStringAsFixed(1)} / wk',
      visualData: _baselineVisualData(
        recentLabel: 'Recent',
        recentValue: recentWeeklyPace,
        baselineLabel: 'Baseline',
        baselineValue: baselineWeeklyPace,
        unit: 'workouts / wk',
        deltaPercent: deltaPercent,
      ),
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

    return _card(
      rule: rule,
      id: rule.id,
      title: 'Consistency pulse',
      body: 'You trained $recentCount times in the last $recentDays days.',
      metric: '$recentCount/$recentDays',
      accent: 'info',
      icon: 'calendar',
      generatedAt: now,
      detailMetricLabel: 'Active days',
      comparisonLabel: 'Previous $recentDays days: ${baselineDaysSet.length}',
      visualData: {
        'recentDays': List.generate(recentDays, (index) {
          final date = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: recentDays - index - 1));
          return recentDaysSet.contains(_dayKey(date));
        }),
        'baselineDays': List.generate(recentDays, (index) {
          final date = DateTime(
            cutoff.year,
            cutoff.month,
            cutoff.day,
          ).subtract(Duration(days: recentDays - index));
          return baselineDaysSet.contains(_dayKey(date));
        }),
        'recentCount': recentCount,
        'baselineCount': baselineDaysSet.length,
      },
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
    final recentDays = _intParam(rule, 'recentDays', 14);
    final minWorkouts = _intParam(rule, 'minWorkouts', 1);
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
    final latestTotals =
        WorkoutMuscleActivationService.buildWorkoutAxisActivation(
          recentWorkouts.first,
          config,
        );
    final normalizer = _normalizerFor(windowTotals, latestTotals);
    final points = config.axes
        .map((axis) {
          return {
            'axisId': axis.id,
            'label': axis.label,
            'planned': windowTotals.actualFor(axis.id) / normalizer,
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

    return _card(
      rule: rule,
      id: rule.id,
      title: 'Last $recentDays days',
      body: 'Muscle activation with your latest workout overlay.',
      metric: '${recentWorkouts.length}',
      accent: 'primary',
      icon: 'radar',
      generatedAt: now,
      sourceWorkoutId: recentWorkouts.first.id,
      detailMetricLabel: 'Recent workouts',
      comparisonLabel: 'Latest workout overlay',
      visualData: {'points': points},
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
    final baselineWorkouts = _intParam(rule, 'baselineWorkouts', 8);
    final minBaselineWorkouts = _intParam(rule, 'minBaselineWorkouts', 2);
    final baseline = workouts
        .take(workouts.length - 1)
        .toList(growable: false)
        .reversed
        .take(baselineWorkouts)
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

    final deltaPercent = baselineVolume <= 0
        ? 0.0
        : ((latestVolume - baselineVolume) / baselineVolume) * 100;
    final metric = baselineVolume > 0
        ? '${deltaPercent >= 0 ? '+' : ''}${deltaPercent.round()}%'
        : '${latestSets.round()} sets';

    return _card(
      rule: rule,
      id: '${rule.id}_${latest.id}',
      title: 'Latest workout',
      body: '${latest.name} compared with your recent workout baseline.',
      metric: metric,
      accent: deltaPercent >= 0 ? 'success' : 'info',
      icon: 'chart',
      generatedAt: now,
      sourceWorkoutId: latest.id,
      detailMetricLabel: 'Latest vs baseline',
      comparisonLabel: '${baseline.length} workout baseline',
      visualData: {
        'items': [
          {
            'label': 'Duration',
            'baseline': baselineDuration,
            'actual': latestDuration,
            'unit': 'min',
          },
          {
            'label': 'Sets',
            'baseline': baselineSets,
            'actual': latestSets,
            'unit': 'sets',
          },
          {
            'label': 'Volume',
            'baseline': baselineVolume,
            'actual': latestVolume,
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
      comparisonLabel: '$lookbackDays day trend',
      visualData: {
        'points': visible
            .map(
              (entry) => {
                'label': '${entry.timestamp.month}/${entry.timestamp.day}',
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

  Map<String, Object?> _baselineVisualData({
    required String recentLabel,
    required double recentValue,
    required String baselineLabel,
    required double baselineValue,
    required String unit,
    required double deltaPercent,
  }) {
    return {
      'items': [
        {'label': baselineLabel, 'value': baselineValue},
        {'label': recentLabel, 'value': recentValue},
      ],
      'unit': unit,
      'deltaPercent': deltaPercent,
    };
  }

  Map<String, Object?> _volumeSparklineVisualData(
    List<Workout> workouts,
    int lookbackDays,
    DateTime now,
    double previousBest,
  ) {
    final cutoff = now.subtract(Duration(days: lookbackDays));
    final visible = workouts
        .where((workout) {
          final date = _workoutDate(workout);
          return !date.isBefore(cutoff) && !date.isAfter(now);
        })
        .toList(growable: false);

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

  Set<String> _workoutDayKeys(Iterable<Workout> workouts) {
    return workouts.map((workout) => _dayKey(_workoutDate(workout))).toSet();
  }

  String _dayKey(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
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

  int _intVisualParam(InsightFeedRule rule, String key, int fallback) {
    final value = rule.visual.params[key];
    return value is num ? value.round() : fallback;
  }
}
