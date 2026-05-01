import 'dart:async';
import 'package:logging/logging.dart';
import '../models/insights.dart';
import '../models/workout.dart';
import 'insights/cache/insights_cache_store.dart';
import 'insights/exercise_insights_provider.dart';
import 'insights/insights_timeframe_resolver.dart';
import 'insights/workout_insights_provider.dart';
import 'insights/workout_trend_provider.dart';
import 'workout_service.dart';

export '../models/insights.dart';

class InsightsService {
  static final InsightsService _instance = InsightsService._internal();
  factory InsightsService() => _instance;
  InsightsService._internal();

  final Logger _logger = Logger('InsightsService');
  static InsightsService get instance => _instance;

  static const String _cacheKey = 'insights_cache';
  static const Duration _cacheExpiry = Duration(hours: 1);

  final InsightsCacheStore _cacheStore = const InsightsCacheStore(
    cacheKey: _cacheKey,
  );

  static InsightsGrouping getGroupingForTimeframe(String timeframe) {
    if (timeframe == '1W' || timeframe == '1M') {
      return InsightsGrouping.day;
    } else if (timeframe == '3M' || timeframe == '6M') {
      return InsightsGrouping.week;
    } else {
      return InsightsGrouping.month;
    }
  }

  // Cache structure
  Map<String, dynamic>? _cache;
  DateTime? _lastCacheUpdate;

  // Concurrency lock for calculations
  final Map<String, Future<dynamic>> _ongoingRequests = {};

  // For testing purposes, allow dependency injection
  Future<List<Workout>> Function()? _workoutsProvider;

  /// For testing purposes, allow injecting a custom workouts provider
  void setWorkoutsProvider(Future<List<Workout>> Function() provider) {
    _workoutsProvider = provider;
  }

  Future<List<Workout>> getWorkouts() async {
    _logger.fine('Getting workouts for insights calculation');
    try {
      if (_workoutsProvider != null) {
        _logger.fine('Using custom workouts provider');
        return await _workoutsProvider!();
      }
      return await WorkoutService.instance.getWorkoutsSortedByStartedAt();
    } catch (e) {
      _logger.severe('Failed to get workouts: $e');
      return [];
    }
  }

  // Deprecated: Use getWorkouts() instead
  Future<List<Workout>> _getWorkouts() => getWorkouts();

  Future<List<String>> getAvailableWorkoutNames() async {
    final workouts = await _getWorkouts();
    return workouts
        .where((w) => w.name.isNotEmpty)
        .map((w) => w.name)
        .toSet()
        .toList()
      ..sort();
  }

  Future<T> _withCache<T>({
    required String key,
    required Future<T> Function() calculator,
    required T Function(Map<String, dynamic>) fromMap,
    required Map<String, dynamic> Function(T) toMap,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedItem = _getCachedItem<T>(key, fromMap);
      if (cachedItem != null) {
        _logger.finer('Returning cached item for key: $key');
        return cachedItem;
      }

      if (_ongoingRequests.containsKey(key)) {
        _logger.finer('Waiting for ongoing request for key: $key');
        return await _ongoingRequests[key]!;
      }
    } else {
      _logger.fine('Forcing refresh for key: $key');
    }

    _logger.fine('Calculating value for key: $key');
    final completer = Completer<T>();
    _ongoingRequests[key] = completer.future;

    try {
      final result = await calculator();
      await _updateCache(key, toMap(result));
      completer.complete(result);
      _logger.fine('Successfully calculated and cached value for key: $key');
      return result;
    } catch (e, s) {
      _logger.severe('Failed to calculate value for key: $key: $e');
      completer.completeError(e, s);
      rethrow;
    } finally {
      unawaited(_ongoingRequests.remove(key));
    }
  }

  T? _getCachedItem<T>(String key, T Function(Map<String, dynamic>) fromMap) {
    if (_cache != null && _lastCacheUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastCacheUpdate!);
      if (timeSinceUpdate < _cacheExpiry && _cache!.containsKey(key)) {
        return fromMap(_cache![key]);
      }
    }
    return null;
  }

  Future<WorkoutInsights> getWorkoutInsights({
    int monthsBack = 6,
    int? weeksBack,
    String? workoutName,
    String? muscleGroup,
    String? equipment,
    bool? isBodyWeight,
    bool forceRefresh = false,
    InsightsGrouping? grouping,
  }) {
    final finalGrouping = InsightsTimeframeResolver.resolveGrouping(
      monthsBack: monthsBack,
      weeksBack: weeksBack,
      grouping: grouping,
    );

    final cacheKey = InsightsTimeframeResolver.workoutInsightsCacheKey(
      monthsBack: monthsBack,
      weeksBack: weeksBack,
      grouping: finalGrouping,
      workoutName: workoutName,
      muscleGroup: muscleGroup,
      equipment: equipment,
      isBodyWeight: isBodyWeight,
    );
    return _withCache<WorkoutInsights>(
      key: cacheKey,
      calculator: () => WorkoutInsightsProvider().getData(
        monthsBack: monthsBack,
        weeksBack: weeksBack,
        grouping: finalGrouping,
        filters: {
          'workoutName': workoutName,
          'muscleGroup': muscleGroup,
          'equipment': equipment,
          'isBodyWeight': isBodyWeight,
        },
      ),
      fromMap: (map) => WorkoutInsights.fromMap(map),
      toMap: (insights) => insights.toMap(),
      forceRefresh: forceRefresh,
    );
  }

  Future<ExerciseInsights> getExerciseInsights({
    required String exerciseName,
    int monthsBack = 6,
    int? weeksBack,
    InsightsGrouping? grouping,
    bool forceRefresh = false,
  }) {
    final finalGrouping = InsightsTimeframeResolver.resolveGrouping(
      monthsBack: monthsBack,
      weeksBack: weeksBack,
      grouping: grouping,
    );

    final cacheKey = InsightsTimeframeResolver.exerciseInsightsCacheKey(
      exerciseName: exerciseName,
      monthsBack: monthsBack,
      weeksBack: weeksBack,
      grouping: finalGrouping,
    );
    return _withCache<ExerciseInsights>(
      key: cacheKey,
      calculator: () => ExerciseInsightsProvider().getData(
        exerciseName: exerciseName,
        monthsBack: monthsBack,
        weeksBack: weeksBack,
        grouping: finalGrouping,
      ),
      fromMap: (map) => ExerciseInsights.fromMap(map),
      toMap: (insights) => insights.toMap(),
      forceRefresh: forceRefresh,
    );
  }

  Future<WeeklyInsights> getWeeklyInsights({
    int? weeksBack,
    int? monthsBack,
    String? workoutName,
    String? muscleGroup,
    String? equipment,
    bool? isBodyWeight,
    bool forceRefresh = false,
    InsightsGrouping? grouping,
  }) async {
    final int effectiveMonths = monthsBack ?? 6;
    final finalGrouping = InsightsTimeframeResolver.resolveGrouping(
      monthsBack: effectiveMonths,
      weeksBack: weeksBack,
      grouping: grouping,
    );
    final timeSlots = InsightsTimeframeResolver.weeklyTimeSlots(
      grouping: finalGrouping,
      effectiveMonths: effectiveMonths,
      weeksBack: weeksBack,
    );

    final cacheKey = InsightsTimeframeResolver.weeklyInsightsCacheKey(
      effectiveMonths: effectiveMonths,
      timeSlots: timeSlots,
      grouping: finalGrouping,
      workoutName: workoutName,
      muscleGroup: muscleGroup,
      equipment: equipment,
      isBodyWeight: isBodyWeight,
    );
    return _withCache<WeeklyInsights>(
      key: cacheKey,
      calculator: () async {
        final filters = {
          'workoutName': workoutName,
          'muscleGroup': muscleGroup,
          'equipment': equipment,
          'isBodyWeight': isBodyWeight,
        };

        final timeframe = InsightsTimeframeResolver.weeklyTimeframeLabel(
          effectiveMonths: effectiveMonths,
          weeksBack: weeksBack,
        );

        final countProvider = WorkoutTrendProvider(WorkoutTrendType.count);
        final durationProvider = WorkoutTrendProvider(
          WorkoutTrendType.duration,
        );
        final volumeProvider = WorkoutTrendProvider(WorkoutTrendType.sets);

        final countData = await countProvider.getData(
          timeframe: timeframe,
          monthsBack: effectiveMonths,
          filters: filters,
        );

        final durationData = await durationProvider.getData(
          timeframe: timeframe,
          monthsBack: effectiveMonths,
          filters: filters,
        );

        final volumeData = await volumeProvider.getData(
          timeframe: timeframe,
          monthsBack: effectiveMonths,
          filters: filters,
        );

        final weeklyWorkoutCounts = countData
            .map(
              (e) => WeeklyDataPoint(
                weekStart: e.date,
                minValue: e.minValue ?? 0,
                maxValue: e.maxValue ?? e.value,
              ),
            )
            .toList();

        final weeklyDurations = durationData
            .map(
              (e) => WeeklyDataPoint(
                weekStart: e.date,
                minValue: e.minValue ?? 0,
                maxValue: e.maxValue ?? e.value,
              ),
            )
            .toList();

        final weeklyVolumes = volumeData
            .map(
              (e) => WeeklyDataPoint(
                weekStart: e.date,
                minValue: e.minValue ?? 0,
                maxValue: e.maxValue ?? e.value,
              ),
            )
            .toList();

        double avgCount = 0;
        final activeWeeks = countData.where((e) => e.value > 0).toList();
        if (activeWeeks.isNotEmpty) {
          avgCount =
              activeWeeks.fold(0.0, (sum, e) => sum + e.value) /
              activeWeeks.length;
        }

        double avgDuration = 0;
        int totalWorkoutsDuration = 0;
        double totalDurationMins = 0;
        for (var d in durationData) {
          totalDurationMins += d.value * 60;
          totalWorkoutsDuration += d.count ?? 0;
        }
        if (totalWorkoutsDuration > 0) {
          avgDuration = totalDurationMins / totalWorkoutsDuration;
        }

        double avgVolume = 0;
        int totalWorkoutsVolume = 0;
        double totalSets = 0;
        for (var d in volumeData) {
          totalSets += d.value;
          totalWorkoutsVolume += d.count ?? 0;
        }
        if (totalWorkoutsVolume > 0) {
          avgVolume = totalSets / totalWorkoutsVolume;
        }

        return WeeklyInsights(
          weeklyWorkoutCounts: weeklyWorkoutCounts,
          weeklyDurations: weeklyDurations,
          weeklyVolumes: weeklyVolumes,
          averageWorkoutsPerWeek: avgCount,
          averageDuration: avgDuration,
          averageVolume: avgVolume,
          lastUpdated: DateTime.now(),
        );
      },
      fromMap: (map) => WeeklyInsights.fromMap(map),
      toMap: (insights) => insights.toMap(),
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _updateCache(
    String key,
    Map<String, dynamic> insightsMap,
  ) async {
    _logger.fine('Updating cache for key: $key');
    try {
      _cache ??= {};
      _cache![key] = insightsMap;
      _lastCacheUpdate = DateTime.now();
      await _cacheStore.save(cache: _cache!, lastUpdate: _lastCacheUpdate!);
      _logger.fine('Cache updated successfully');
    } catch (e) {
      _logger.severe('Failed to update cache: $e');
    }
  }

  Future<void> _loadCache() async {
    _logger.info('Loading insights cache from SharedPreferences');
    try {
      final snapshot = await _cacheStore.load();

      if (snapshot != null) {
        _cache = snapshot.cache;
        _lastCacheUpdate = snapshot.lastUpdate;
        _logger.info('Insights cache loaded successfully');
      } else {
        _logger.info('No insights cache found');
      }
    } catch (e) {
      _logger.warning('Failed to load insights cache, clearing it: $e');
      _cache = null;
      _lastCacheUpdate = null;
      await clearCache();
    }
  }

  Future<void> clearCache() async {
    _logger.info('Clearing insights cache');
    try {
      _cache = null;
      _lastCacheUpdate = null;

      await _cacheStore.clear();
      _logger.info('Insights cache cleared successfully');
    } catch (e) {
      _logger.severe('Failed to clear insights cache: $e');
    }
  }

  /// For testing purposes only. Resets the singleton's state.
  void reset() {
    _logger.warning('Resetting InsightsService state for testing');
    _cache = null;
    _lastCacheUpdate = null;
    _ongoingRequests.clear();
    _workoutsProvider = null;
    clearCache();
  }

  // Initialize cache on service creation
  Future<void> initialize() async {
    await _loadCache();
  }
}
