import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import 'database_service.dart';

class InsightsService {
  static final InsightsService _instance = InsightsService._internal();
  factory InsightsService() => _instance;
  InsightsService._internal();

  final Logger _logger = Logger('InsightsService');
  static InsightsService get instance => _instance;

  static const String _cacheKey = 'insights_cache';
  static const Duration _cacheExpiry = Duration(hours: 1);

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

  Future<List<Workout>> _getWorkouts() async {
    _logger.fine('Getting workouts for insights calculation');
    try {
      if (_workoutsProvider != null) {
        _logger.fine('Using custom workouts provider');
        return await _workoutsProvider!();
      }
      return await DatabaseService.instance.getWorkouts();
    } catch (e) {
      _logger.severe('Failed to get workouts: $e');
      return [];
    }
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
      _ongoingRequests.remove(key);
    }
  }

  T? _getCachedItem<T>(
      String key, T Function(Map<String, dynamic>) fromMap) {
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
    bool forceRefresh = false,
  }) {
    final cacheKey = 'insights_${monthsBack}m';
    return _withCache<WorkoutInsights>(
      key: cacheKey,
      calculator: () => _calculateInsights(monthsBack),
      fromMap: (map) => WorkoutInsights.fromMap(map),
      toMap: (insights) => insights.toMap(),
      forceRefresh: forceRefresh,
    );
  }

  Future<ExerciseInsights> getExerciseInsights({
    required String exerciseName,
    int monthsBack = 6,
    bool forceRefresh = false,
  }) {
    final cacheKey = 'exercise_${exerciseName.trim().toLowerCase()}_${monthsBack}m';
    return _withCache<ExerciseInsights>(
      key: cacheKey,
      calculator: () => _calculateExerciseInsights(exerciseName, monthsBack),
      fromMap: (map) => ExerciseInsights.fromMap(map),
      toMap: (insights) => insights.toMap(),
      forceRefresh: forceRefresh,
    );
  }

  List<Workout> _filterWorkouts(List<Workout> allWorkouts, int monthsBack) {
    final workoutsWithDates = allWorkouts
        .where((w) => w.startedAt != null && w.status == WorkoutStatus.completed)
        .toList();


    if (workoutsWithDates.isEmpty) {
        return [];
    }

    final now = DateTime.now();
    final latestWorkoutDate = workoutsWithDates
        .map((w) => w.startedAt!)
        .reduce((latest, date) => date.isAfter(latest) ? date : latest);

    final referenceDate =
        latestWorkoutDate.isAfter(now) ? now : latestWorkoutDate;

    // We want to include workouts from the last N calendar months.
    // If monthsBack is 1, we want this month. If 6, this month and the previous 5.
    // The cutoff should be the first day of the start month.
    final cutoffDate =
        DateTime(referenceDate.year, referenceDate.month - (monthsBack - 1), 1);


    final filteredWorkouts = workoutsWithDates.where((workout) {
      final startedAt = workout.startedAt!;
      // We include workouts that are on or after the cutoff date and not in the future relative to the reference date.
      final isAfterReference = startedAt.isAfter(referenceDate);
      final isBeforeCutoff = startedAt.isBefore(cutoffDate);
      final include = !isAfterReference && !isBeforeCutoff;

      return include;
    }).toList();

    return filteredWorkouts;
  }

  Future<WorkoutInsights> _calculateInsights(int monthsBack) async {
    _logger.info('Calculating workout insights for $monthsBack months');
    final allWorkouts = await _getWorkouts();
    final recentWorkouts = _filterWorkouts(allWorkouts, monthsBack);
    _logger.fine('Found ${recentWorkouts.length} recent workouts');

    // Calculate total statistics
    final totalWorkouts = recentWorkouts.length;
    final totalHours = recentWorkouts.fold<double>(0, (sum, workout) => 
        sum + ((workout.completedAt != null && workout.startedAt != null 
            ? workout.completedAt!.difference(workout.startedAt!).inMinutes 
            : 0) / 60.0));
    final totalWeight = recentWorkouts.fold<double>(0, (sum, workout) => 
        sum + workout.exercises.fold(0.0, (exerciseSum, exercise) => 
            exerciseSum + exercise.sets.fold(0.0, (setSum, set) => 
                setSum + (set.actualWeight ?? 0.0) * (set.actualReps ?? 0))));
    _logger.finer('Total stats: workouts=$totalWorkouts, hours=$totalHours, weight=$totalWeight');

    // Calculate monthly data for charts
    final monthlyData = _calculateMonthlyData(recentWorkouts, monthsBack);

    final insights = WorkoutInsights(
      totalWorkouts: totalWorkouts,
      totalHours: totalHours,
      totalWeight: totalWeight,
      monthlyWorkouts: monthlyData['workouts']!,
      monthlyHours: monthlyData['hours']!,
      monthlyWeight: monthlyData['weight']!,
      averageWorkoutDuration: totalWorkouts > 0 ? totalHours / totalWorkouts : 0,
      averageWeightPerWorkout: totalWorkouts > 0 ? totalWeight / totalWorkouts : 0,
      lastUpdated: DateTime.now(),
    );
    _logger.info('Workout insights calculation complete');
    return insights;
  }

  Future<ExerciseInsights> _calculateExerciseInsights(String exerciseName, int monthsBack) async {
    _logger.info('Calculating exercise insights for "$exerciseName" for $monthsBack months');
    if (exerciseName.trim().isEmpty) {
      _logger.warning('Exercise name is empty, returning empty insights');
      return ExerciseInsights.empty(exerciseName);
    }
    
    final allWorkouts = await _getWorkouts();
    final recentWorkouts = _filterWorkouts(allWorkouts, monthsBack);
    _logger.fine('Found ${recentWorkouts.length} recent workouts for exercise insights');

    // Find all instances of this exercise across all workouts
    final exerciseInstances = <ExerciseInstance>[];
    
    for (final workout in recentWorkouts) {
      for (final exercise in workout.exercises) {
        // For now, we'll use the exercise slug to match exercises
        if (exercise.exerciseSlug.toLowerCase() == exerciseName.toLowerCase()) {
          exerciseInstances.add(ExerciseInstance(
            date: workout.startedAt ?? DateTime.now(),
            sets: exercise.sets,
            totalWeight: exercise.sets.fold<double>(0, (sum, set) => 
                sum + ((set.actualWeight ?? 0.0) * (set.actualReps ?? 0))),
            totalReps: exercise.sets.fold<int>(0, (sum, set) => 
                sum + (set.actualReps ?? 0)),
            maxWeight: exercise.sets.isEmpty ? 0 : exercise.sets.map((s) => s.actualWeight ?? 0.0).reduce((a, b) => a > b ? a : b),
            totalSets: exercise.sets.length,
          ));
        }
      }
    }

    if (exerciseInstances.isEmpty) {
      _logger.fine('No instances of exercise "$exerciseName" found in recent workouts');
      return ExerciseInsights.empty(exerciseName);
    }
    _logger.fine('Found ${exerciseInstances.length} instances of exercise "$exerciseName"');

    // Calculate totals
    final totalSessions = exerciseInstances.length;
    final totalSets = exerciseInstances.fold<int>(0, (sum, instance) => sum + instance.totalSets);
    final totalReps = exerciseInstances.fold<int>(0, (sum, instance) => sum + instance.totalReps);
    final totalWeight = exerciseInstances.fold<double>(0, (sum, instance) => sum + instance.totalWeight);
    final maxWeight = exerciseInstances.map((i) => i.maxWeight).reduce((a, b) => a > b ? a : b);
    _logger.finer('Total stats for "$exerciseName": sessions=$totalSessions, sets=$totalSets, reps=$totalReps, weight=$totalWeight, maxWeight=$maxWeight');

    // Calculate monthly data
    final monthlyData = _calculateExerciseMonthlyData(exerciseInstances, monthsBack);

    final insights = ExerciseInsights(
      exerciseName: exerciseName,
      totalSessions: totalSessions,
      totalSets: totalSets,
      totalReps: totalReps,
      totalWeight: totalWeight,
      maxWeight: maxWeight,
      averageWeight: totalSets > 0 ? totalWeight / totalSets : 0,
      averageReps: totalSets > 0 ? totalReps / totalSets : 0,
      averageSets: totalSessions > 0 ? totalSets / totalSessions : 0,
      monthlyVolume: monthlyData['volume']!,
      monthlyMaxWeight: monthlyData['maxWeight']!,
      monthlyFrequency: monthlyData['frequency']!,
      lastUpdated: DateTime.now(),
    );
    _logger.info('Exercise insights calculation for "$exerciseName" complete');
    return insights;
  }

  Map<String, List<MonthlyDataPoint>> _calculateMonthlyData(
      List<Workout> workouts, int monthsBack) {
    final now = DateTime.now();
    final referenceDate = workouts.isEmpty 
        ? now
        : workouts
            .where((w) => w.startedAt != null)
            .map((w) => w.startedAt!)
            .fold<DateTime>(now, (latest, date) => date.isAfter(latest) && !date.isAfter(now) ? date : latest);
    
    final monthlyWorkouts = <MonthlyDataPoint>[];
    final monthlyHours = <MonthlyDataPoint>[];
    final monthlyWeight = <MonthlyDataPoint>[];

    for (int i = monthsBack - 1; i >= 0; i--) {
      // Use proper month arithmetic to handle month boundaries correctly
      final normalizedMonthDate = DateTime(referenceDate.year, referenceDate.month - i, 1);
      
      final monthWorkouts = workouts.where((workout) {
        return workout.startedAt != null && 
               workout.startedAt!.year == normalizedMonthDate.year &&
               workout.startedAt!.month == normalizedMonthDate.month;
      }).toList();

      final workoutCount = monthWorkouts.length;
      final totalHours = monthWorkouts.fold<double>(0, (sum, workout) => 
          sum + ((workout.completedAt != null && workout.startedAt != null 
              ? workout.completedAt!.difference(workout.startedAt!).inMinutes 
              : 0) / 60.0));
      final totalWeight = monthWorkouts.fold<double>(0, (sum, workout) => 
          sum + workout.exercises.fold(0.0, (exerciseSum, exercise) => 
              exerciseSum + exercise.sets.fold(0.0, (setSum, set) => 
                  setSum + (set.actualWeight ?? 0.0) * (set.actualReps ?? 0))));

      monthlyWorkouts.add(MonthlyDataPoint(
        month: normalizedMonthDate,
        value: workoutCount.toDouble(),
      ));
      
      monthlyHours.add(MonthlyDataPoint(
        month: normalizedMonthDate,
        value: totalHours,
      ));
      
      monthlyWeight.add(MonthlyDataPoint(
        month: normalizedMonthDate,
        value: totalWeight,
      ));
    }

    return {
      'workouts': monthlyWorkouts,
      'hours': monthlyHours,
      'weight': monthlyWeight,
    };
  }

  Map<String, List<MonthlyDataPoint>> _calculateExerciseMonthlyData(
      List<ExerciseInstance> instances, int monthsBack) {
    final now = DateTime.now();
    final referenceDate = instances.isEmpty 
        ? now
        : instances
            .map((i) => i.date)
            .fold<DateTime>(now, (latest, date) => date.isAfter(latest) && !date.isAfter(now) ? date : latest);
    
    final monthlyVolume = <MonthlyDataPoint>[];
    final monthlyMaxWeight = <MonthlyDataPoint>[];
    final monthlyFrequency = <MonthlyDataPoint>[];

    for (int i = monthsBack - 1; i >= 0; i--) {
      // Use proper month arithmetic to handle month boundaries correctly
      final normalizedMonthDate = DateTime(referenceDate.year, referenceDate.month - i, 1);
      
      final monthInstances = instances.where((instance) {
        return instance.date.year == normalizedMonthDate.year &&
               instance.date.month == normalizedMonthDate.month;
      }).toList();

      final volume = monthInstances.fold<double>(0, (sum, instance) => sum + instance.totalWeight);
      final maxWeight = monthInstances.isEmpty ? 0.0 : monthInstances.map((i) => i.maxWeight).reduce((a, b) => a > b ? a : b);
      final frequency = monthInstances.length.toDouble();

      monthlyVolume.add(MonthlyDataPoint(
        month: normalizedMonthDate,
        value: volume,
      ));
      
      monthlyMaxWeight.add(MonthlyDataPoint(
        month: normalizedMonthDate,
        value: maxWeight,
      ));
      
      monthlyFrequency.add(MonthlyDataPoint(
        month: normalizedMonthDate,
        value: frequency,
      ));
    }

    return {
      'volume': monthlyVolume,
      'maxWeight': monthlyMaxWeight,
      'frequency': monthlyFrequency,
    };
  }

  Future<void> _updateCache(String key, Map<String, dynamic> insightsMap) async {
    _logger.fine('Updating cache for key: $key');
    try {
      _cache ??= {};
      _cache![key] = insightsMap;
      _lastCacheUpdate = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': _cache,
        'lastUpdate': _lastCacheUpdate!.toIso8601String(),
      };
      await prefs.setString(_cacheKey, jsonEncode(cacheData));
      _logger.fine('Cache updated successfully');
    } catch (e) {
      _logger.severe('Failed to update cache: $e');
    }
  }

  Future<void> _loadCache() async {
    _logger.info('Loading insights cache from SharedPreferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      if (cacheJson != null) {
        final cacheData = jsonDecode(cacheJson);
        _cache = Map<String, dynamic>.from(cacheData['data']);
        _lastCacheUpdate = DateTime.parse(cacheData['lastUpdate']);
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
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
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

class WorkoutInsights {
  final int totalWorkouts;
  final double totalHours;
  final double totalWeight;
  final List<MonthlyDataPoint> monthlyWorkouts;
  final List<MonthlyDataPoint> monthlyHours;
  final List<MonthlyDataPoint> monthlyWeight;
  final double averageWorkoutDuration;
  final double averageWeightPerWorkout;
  final DateTime lastUpdated;

  WorkoutInsights({
    required this.totalWorkouts,
    required this.totalHours,
    required this.totalWeight,
    required this.monthlyWorkouts,
    required this.monthlyHours,
    required this.monthlyWeight,
    required this.averageWorkoutDuration,
    required this.averageWeightPerWorkout,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalWorkouts': totalWorkouts,
      'totalHours': totalHours,
      'totalWeight': totalWeight,
      'monthlyWorkouts': monthlyWorkouts.map((e) => e.toMap()).toList(),
      'monthlyHours': monthlyHours.map((e) => e.toMap()).toList(),
      'monthlyWeight': monthlyWeight.map((e) => e.toMap()).toList(),
      'averageWorkoutDuration': averageWorkoutDuration,
      'averageWeightPerWorkout': averageWeightPerWorkout,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory WorkoutInsights.fromMap(Map<String, dynamic> map) {
    try {
      return WorkoutInsights(
        totalWorkouts: _safeParseInt(map['totalWorkouts']),
        totalHours: _safeParseDouble(map['totalHours']),
        totalWeight: _safeParseDouble(map['totalWeight']),
        monthlyWorkouts: _safeParseMonthlyDataList(map['monthlyWorkouts']),
        monthlyHours: _safeParseMonthlyDataList(map['monthlyHours']),
        monthlyWeight: _safeParseMonthlyDataList(map['monthlyWeight']),
        averageWorkoutDuration: _safeParseDouble(map['averageWorkoutDuration']),
        averageWeightPerWorkout: _safeParseDouble(map['averageWeightPerWorkout']),
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(_safeParseInt(map['lastUpdated'])),
      );
    } catch (e) {
      // Return default instance if parsing fails completely
      return WorkoutInsights(
        totalWorkouts: 0,
        totalHours: 0.0,
        totalWeight: 0.0,
        monthlyWorkouts: [],
        monthlyHours: [],
        monthlyWeight: [],
        averageWorkoutDuration: 0.0,
        averageWeightPerWorkout: 0.0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  static int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<MonthlyDataPoint> _safeParseMonthlyDataList(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    try {
      return value
          .whereType<Map<String, dynamic>>()
          .map((e) => MonthlyDataPoint.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

class ExerciseInsights {
  final String exerciseName;
  final int totalSessions;
  final int totalSets;
  final int totalReps;
  final double totalWeight;
  final double maxWeight;
  final double averageWeight;
  final double averageReps;
  final double averageSets;
  final List<MonthlyDataPoint> monthlyVolume;
  final List<MonthlyDataPoint> monthlyMaxWeight;
  final List<MonthlyDataPoint> monthlyFrequency;
  final DateTime lastUpdated;

  ExerciseInsights({
    required this.exerciseName,
    required this.totalSessions,
    required this.totalSets,
    required this.totalReps,
    required this.totalWeight,
    required this.maxWeight,
    required this.averageWeight,
    required this.averageReps,
    required this.averageSets,
    required this.monthlyVolume,
    required this.monthlyMaxWeight,
    required this.monthlyFrequency,
    required this.lastUpdated,
  });

  factory ExerciseInsights.empty(String exerciseName) {
    final now = DateTime.now();
    final emptyMonthlyData = List.generate(6, (i) => MonthlyDataPoint(month: DateTime(now.year, now.month - 5 + i, 1), value: 0.0));
    return ExerciseInsights(
      exerciseName: exerciseName,
      totalSessions: 0,
      totalSets: 0,
      totalReps: 0,
      totalWeight: 0,
      maxWeight: 0,
      averageWeight: 0,
      averageReps: 0,
      averageSets: 0,
      monthlyVolume: emptyMonthlyData,
      monthlyMaxWeight: emptyMonthlyData,
      monthlyFrequency: emptyMonthlyData,
      lastUpdated: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'totalSessions': totalSessions,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'totalWeight': totalWeight,
      'maxWeight': maxWeight,
      'averageWeight': averageWeight,
      'averageReps': averageReps,
      'averageSets': averageSets,
      'monthlyVolume': monthlyVolume.map((e) => e.toMap()).toList(),
      'monthlyMaxWeight': monthlyMaxWeight.map((e) => e.toMap()).toList(),
      'monthlyFrequency': monthlyFrequency.map((e) => e.toMap()).toList(),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory ExerciseInsights.fromMap(Map<String, dynamic> map) {
    return ExerciseInsights(
      exerciseName: map['exerciseName'] ?? '',
      totalSessions: map['totalSessions'] ?? 0,
      totalSets: map['totalSets'] ?? 0,
      totalReps: map['totalReps'] ?? 0,
      totalWeight: (map['totalWeight'] ?? 0.0).toDouble(),
      maxWeight: (map['maxWeight'] ?? 0.0).toDouble(),
      averageWeight: (map['averageWeight'] ?? 0.0).toDouble(),
      averageReps: (map['averageReps'] ?? 0.0).toDouble(),
      averageSets: (map['averageSets'] ?? 0.0).toDouble(),
      monthlyVolume: (map['monthlyVolume'] as List<dynamic>?)
          ?.map((e) => MonthlyDataPoint.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      monthlyMaxWeight: (map['monthlyMaxWeight'] as List<dynamic>?)
          ?.map((e) => MonthlyDataPoint.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      monthlyFrequency: (map['monthlyFrequency'] as List<dynamic>?)
          ?.map((e) => MonthlyDataPoint.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
    );
  }
}

class ExerciseInstance {
  final DateTime date;
  final List<dynamic> sets; // Using dynamic to match WorkoutSet structure
  final double totalWeight;
  final int totalReps;
  final double maxWeight;
  final int totalSets;

  ExerciseInstance({
    required this.date,
    required this.sets,
    required this.totalWeight,
    required this.totalReps,
    required this.maxWeight,
    required this.totalSets,
  });
}

class MonthlyDataPoint {
  final DateTime month;
  final double value;

  MonthlyDataPoint({
    required this.month,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month.millisecondsSinceEpoch,
      'value': value,
    };
  }

  factory MonthlyDataPoint.fromMap(Map<String, dynamic> map) {
    return MonthlyDataPoint(
      month: DateTime.fromMillisecondsSinceEpoch(map['month'] ?? 0),
      value: (map['value'] ?? 0.0).toDouble(),
    );
  }
}
