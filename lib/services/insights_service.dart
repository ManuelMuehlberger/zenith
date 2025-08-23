import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import 'database_service.dart';

class InsightsService {
  static final InsightsService _instance = InsightsService._internal();
  factory InsightsService() => _instance;
  InsightsService._internal();

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
    try {
      if (_workoutsProvider != null) {
        return await _workoutsProvider!();
      }
      return await DatabaseService.instance.getWorkouts();
    } catch (e) {
      // Return empty list on error to prevent crashes
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
      // 1. Check memory cache for the final result.
      final cachedItem = _getCachedItem<T>(key, fromMap);
      if (cachedItem != null) {
          return cachedItem;
      }

      // 2. Check if a request for this key is already in progress.
      if (_ongoingRequests.containsKey(key)) {
          return await _ongoingRequests[key]!;
      }
    }

    // 3. No cached item and no ongoing request, so we need to calculate.
    // Create a completer and store its future in the map to lock this key.
    final completer = Completer<T>();
    _ongoingRequests[key] = completer.future;

    try {
      final result = await calculator();
      await _updateCache(key, toMap(result));
      // When the calculation is complete, complete the future.
      completer.complete(result);
      return result;
    } catch (e, s) {
      // If an error occurs, complete the future with an error.
      completer.completeError(e, s);
      // Rethrow the error to the original caller.
      rethrow;
    } finally {
      // 4. After the future is completed (with data or error), remove it from the map.
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
    final allWorkouts = await _getWorkouts();
    final recentWorkouts = _filterWorkouts(allWorkouts, monthsBack);

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

    // Calculate monthly data for charts
    final monthlyData = _calculateMonthlyData(recentWorkouts, monthsBack);

    return WorkoutInsights(
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
  }

  Future<ExerciseInsights> _calculateExerciseInsights(String exerciseName, int monthsBack) async {
    if (exerciseName.trim().isEmpty) {
      return ExerciseInsights.empty(exerciseName);
    }
    
    final allWorkouts = await _getWorkouts();
    final recentWorkouts = _filterWorkouts(allWorkouts, monthsBack);

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
      return ExerciseInsights.empty(exerciseName);
    }

    // Calculate totals
    final totalSessions = exerciseInstances.length;
    final totalSets = exerciseInstances.fold<int>(0, (sum, instance) => sum + instance.totalSets);
    final totalReps = exerciseInstances.fold<int>(0, (sum, instance) => sum + instance.totalReps);
    final totalWeight = exerciseInstances.fold<double>(0, (sum, instance) => sum + instance.totalWeight);
    // Fix: Remove redundant empty check since we already returned early if empty
    final maxWeight = exerciseInstances.map((i) => i.maxWeight).reduce((a, b) => a > b ? a : b);

    // Calculate monthly data
    final monthlyData = _calculateExerciseMonthlyData(exerciseInstances, monthsBack);

    return ExerciseInsights(
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
    } catch (e) {
      print('InsightsService: Failed to update cache - $e');
    }
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      if (cacheJson != null) {
        final cacheData = jsonDecode(cacheJson);
        _cache = Map<String, dynamic>.from(cacheData['data']);
        _lastCacheUpdate = DateTime.parse(cacheData['lastUpdate']);
      }
    } catch (e) {
      _cache = null;
      _lastCacheUpdate = null;
      await clearCache();
    }
  }

  Future<void> clearCache() async {
    try {
      _cache = null;
      _lastCacheUpdate = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
    }
  }

  /// For testing purposes only. Resets the singleton's state.
  void reset() {
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
          .where((e) => e is Map<String, dynamic>)
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
