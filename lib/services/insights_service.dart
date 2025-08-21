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

  Future<WorkoutInsights> getWorkoutInsights({
    int monthsBack = 6,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'insights_${monthsBack}m';
    
    // Check if we have valid cached data
    if (!forceRefresh && _cache != null && _lastCacheUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastCacheUpdate!);
      if (timeSinceUpdate < _cacheExpiry && _cache!.containsKey(cacheKey)) {
        return WorkoutInsights.fromMap(_cache![cacheKey]);
      }
    }

    // Calculate fresh insights
    final insights = await _calculateInsights(monthsBack);
    
    // Update cache
    await _updateCache(cacheKey, insights);
    
    return insights;
  }

  Future<ExerciseInsights> getExerciseInsights({
    required String exerciseName,
    int monthsBack = 6,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'exercise_${exerciseName}_${monthsBack}m';
    
    // Check if we have valid cached data
    if (!forceRefresh && _cache != null && _lastCacheUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastCacheUpdate!);
      if (timeSinceUpdate < _cacheExpiry && _cache!.containsKey(cacheKey)) {
        return ExerciseInsights.fromMap(_cache![cacheKey]);
      }
    }

    // Calculate fresh exercise insights
    final insights = await _calculateExerciseInsights(exerciseName, monthsBack);
    
    // Update cache
    await _updateExerciseCache(cacheKey, insights);
    
    return insights;
  }

  Future<WorkoutInsights> _calculateInsights(int monthsBack) async {
    final allWorkouts = await DatabaseService.instance.getWorkouts();
    final cutoffDate = DateTime.now().subtract(Duration(days: monthsBack * 30));
    
    // Filter workouts within the specified time range
    final recentWorkouts = allWorkouts.where((workout) => 
        workout.startedAt != null && workout.startedAt!.isAfter(cutoffDate) && 
        workout.status == WorkoutStatus.completed).toList();

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
    final allWorkouts = await DatabaseService.instance.getWorkouts();
    final cutoffDate = DateTime.now().subtract(Duration(days: monthsBack * 30));
    
    // Filter workouts within the specified time range
    final recentWorkouts = allWorkouts.where((workout) => 
        workout.startedAt != null && workout.startedAt!.isAfter(cutoffDate) && 
        workout.status == WorkoutStatus.completed).toList();

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
        monthlyVolume: [],
        monthlyMaxWeight: [],
        monthlyFrequency: [],
        lastUpdated: DateTime.now(),
      );
    }

    // Calculate totals
    final totalSessions = exerciseInstances.length;
    final totalSets = exerciseInstances.fold<int>(0, (sum, instance) => sum + instance.totalSets);
    final totalReps = exerciseInstances.fold<int>(0, (sum, instance) => sum + instance.totalReps);
    final totalWeight = exerciseInstances.fold<double>(0, (sum, instance) => sum + instance.totalWeight);
    final maxWeight = exerciseInstances.isEmpty ? 0.0 : exerciseInstances.map((i) => i.maxWeight).reduce((a, b) => a > b ? a : b);

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
    final monthlyWorkouts = <MonthlyDataPoint>[];
    final monthlyHours = <MonthlyDataPoint>[];
    final monthlyWeight = <MonthlyDataPoint>[];

    for (int i = monthsBack - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthWorkouts = workouts.where((workout) {
        return workout.startedAt != null && 
               workout.startedAt!.year == monthDate.year &&
               workout.startedAt!.month == monthDate.month;
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
        month: monthDate,
        value: workoutCount.toDouble(),
      ));
      
      monthlyHours.add(MonthlyDataPoint(
        month: monthDate,
        value: totalHours,
      ));
      
      monthlyWeight.add(MonthlyDataPoint(
        month: monthDate,
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
    final monthlyVolume = <MonthlyDataPoint>[];
    final monthlyMaxWeight = <MonthlyDataPoint>[];
    final monthlyFrequency = <MonthlyDataPoint>[];

    for (int i = monthsBack - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthInstances = instances.where((instance) {
        return instance.date.year == monthDate.year &&
               instance.date.month == monthDate.month;
      }).toList();

      final volume = monthInstances.fold<double>(0, (sum, instance) => sum + instance.totalWeight);
      final maxWeight = monthInstances.isEmpty ? 0.0 : monthInstances.map((i) => i.maxWeight).reduce((a, b) => a > b ? a : b);
      final frequency = monthInstances.length.toDouble();

      monthlyVolume.add(MonthlyDataPoint(
        month: monthDate,
        value: volume,
      ));
      
      monthlyMaxWeight.add(MonthlyDataPoint(
        month: monthDate,
        value: maxWeight,
      ));
      
      monthlyFrequency.add(MonthlyDataPoint(
        month: monthDate,
        value: frequency,
      ));
    }

    return {
      'volume': monthlyVolume,
      'maxWeight': monthlyMaxWeight,
      'frequency': monthlyFrequency,
    };
  }

  Future<void> _updateCache(String key, WorkoutInsights insights) async {
    try {
      _cache ??= {};
      _cache![key] = insights.toMap();
      _lastCacheUpdate = DateTime.now();

      // Persist cache to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': _cache,
        'lastUpdate': _lastCacheUpdate!.millisecondsSinceEpoch,
      };
      await prefs.setString(_cacheKey, jsonEncode(cacheData));
    } catch (e) {
    }
  }

  Future<void> _updateExerciseCache(String key, ExerciseInsights insights) async {
    try {
      _cache ??= {};
      _cache![key] = insights.toMap();
      _lastCacheUpdate = DateTime.now();

      // Persist cache to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': _cache,
        'lastUpdate': _lastCacheUpdate!.millisecondsSinceEpoch,
      };
      await prefs.setString(_cacheKey, jsonEncode(cacheData));
    } catch (e) {
    }
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      
      if (cacheJson != null) {
        final cacheData = jsonDecode(cacheJson);
        _cache = Map<String, dynamic>.from(cacheData['data'] ?? {});
        _lastCacheUpdate = DateTime.fromMillisecondsSinceEpoch(
            cacheData['lastUpdate'] ?? 0);
      }
    } catch (e) {
      _cache = null;
      _lastCacheUpdate = null;
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
    return WorkoutInsights(
      totalWorkouts: map['totalWorkouts'] ?? 0,
      totalHours: (map['totalHours'] ?? 0.0).toDouble(),
      totalWeight: (map['totalWeight'] ?? 0.0).toDouble(),
      monthlyWorkouts: (map['monthlyWorkouts'] as List<dynamic>?)
          ?.map((e) => MonthlyDataPoint.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      monthlyHours: (map['monthlyHours'] as List<dynamic>?)
          ?.map((e) => MonthlyDataPoint.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      monthlyWeight: (map['monthlyWeight'] as List<dynamic>?)
          ?.map((e) => MonthlyDataPoint.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      averageWorkoutDuration: (map['averageWorkoutDuration'] ?? 0.0).toDouble(),
      averageWeightPerWorkout: (map['averageWeightPerWorkout'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
    );
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
