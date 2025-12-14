
enum InsightsGrouping {
  day,
  week,
  month
}

class WorkoutInsights {
  final int totalWorkouts;
  final double totalHours;
  final double totalWeight;
  final List<InsightDataPoint> trendWorkouts;
  final List<InsightDataPoint> trendHours;
  final List<InsightDataPoint> trendWeight;
  final double averageWorkoutDuration;
  final double averageWeightPerWorkout;
  final DateTime lastUpdated;

  WorkoutInsights({
    required this.totalWorkouts,
    required this.totalHours,
    required this.totalWeight,
    required this.trendWorkouts,
    required this.trendHours,
    required this.trendWeight,
    required this.averageWorkoutDuration,
    required this.averageWeightPerWorkout,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalWorkouts': totalWorkouts,
      'totalHours': totalHours,
      'totalWeight': totalWeight,
      'trendWorkouts': trendWorkouts.map((e) => e.toMap()).toList(),
      'trendHours': trendHours.map((e) => e.toMap()).toList(),
      'trendWeight': trendWeight.map((e) => e.toMap()).toList(),
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
        trendWorkouts: _safeParseInsightDataList(map['trendWorkouts'] ?? map['monthlyWorkouts']),
        trendHours: _safeParseInsightDataList(map['trendHours'] ?? map['monthlyHours']),
        trendWeight: _safeParseInsightDataList(map['trendWeight'] ?? map['monthlyWeight']),
        averageWorkoutDuration: _safeParseDouble(map['averageWorkoutDuration']),
        averageWeightPerWorkout: _safeParseDouble(map['averageWeightPerWorkout']),
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(_safeParseInt(map['lastUpdated'])),
      );
    } catch (e) {
      return WorkoutInsights(
        totalWorkouts: 0,
        totalHours: 0.0,
        totalWeight: 0.0,
        trendWorkouts: [],
        trendHours: [],
        trendWeight: [],
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

  static List<InsightDataPoint> _safeParseInsightDataList(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    try {
      return value
          .whereType<Map<String, dynamic>>()
          .map((e) => InsightDataPoint.fromMap(e))
          .toList();
    } catch (e) {
      try {
        return value
            .whereType<Map<String, dynamic>>()
            .map((e) {
              if (e.containsKey('month') && !e.containsKey('date')) {
                e['date'] = e['month'];
              }
              return InsightDataPoint.fromMap(e);
            })
            .toList();
      } catch (_) {
        return [];
      }
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
  final List<InsightDataPoint> monthlyVolume;
  final List<InsightDataPoint> monthlyMaxWeight;
  final List<InsightDataPoint> monthlyFrequency;
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
    final emptyMonthlyData = List.generate(6, (i) => InsightDataPoint(date: DateTime(now.year, now.month - 5 + i, 1), value: 0.0));
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
          ?.map((e) => InsightDataPoint.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      monthlyMaxWeight: (map['monthlyMaxWeight'] as List<dynamic>?)
          ?.map((e) => InsightDataPoint.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      monthlyFrequency: (map['monthlyFrequency'] as List<dynamic>?)
          ?.map((e) => InsightDataPoint.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
    );
  }
}

class ExerciseInstance {
  final DateTime date;
  final List<dynamic> sets;
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

class InsightDataPoint {
  final DateTime date;
  final double value;
  final double? minValue;
  final double? maxValue;
  final int? count;

  InsightDataPoint({
    required this.date,
    required this.value,
    this.minValue,
    this.maxValue,
    this.count,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'value': value,
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (count != null) 'count': count,
    };
  }

  factory InsightDataPoint.fromMap(Map<String, dynamic> map) {
    return InsightDataPoint(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      value: (map['value'] ?? 0.0).toDouble(),
      minValue: map['minValue'] != null ? (map['minValue'] as num).toDouble() : null,
      maxValue: map['maxValue'] != null ? (map['maxValue'] as num).toDouble() : null,
      count: map['count'] as int?,
    );
  }
}

class WeeklyDataPoint {
  final DateTime weekStart;
  final double minValue;
  final double maxValue;

  WeeklyDataPoint({
    required this.weekStart,
    required this.minValue,
    required this.maxValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekStart': weekStart.millisecondsSinceEpoch,
      'minValue': minValue,
      'maxValue': maxValue,
    };
  }

  factory WeeklyDataPoint.fromMap(Map<String, dynamic> map) {
    return WeeklyDataPoint(
      weekStart: DateTime.fromMillisecondsSinceEpoch(map['weekStart'] ?? 0),
      minValue: (map['minValue'] ?? 0.0).toDouble(),
      maxValue: (map['maxValue'] ?? 0.0).toDouble(),
    );
  }
}

class WeeklyInsights {
  final List<WeeklyDataPoint> weeklyWorkoutCounts;
  final List<WeeklyDataPoint> weeklyDurations;
  final List<WeeklyDataPoint> weeklyVolumes;
  final double averageWorkoutsPerWeek;
  final double averageDuration;
  final double averageVolume;
  final DateTime lastUpdated;

  WeeklyInsights({
    required this.weeklyWorkoutCounts,
    required this.weeklyDurations,
    required this.weeklyVolumes,
    required this.averageWorkoutsPerWeek,
    required this.averageDuration,
    required this.averageVolume,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'weeklyWorkoutCounts': weeklyWorkoutCounts.map((e) => e.toMap()).toList(),
      'weeklyDurations': weeklyDurations.map((e) => e.toMap()).toList(),
      'weeklyVolumes': weeklyVolumes.map((e) => e.toMap()).toList(),
      'averageWorkoutsPerWeek': averageWorkoutsPerWeek,
      'averageDuration': averageDuration,
      'averageVolume': averageVolume,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory WeeklyInsights.fromMap(Map<String, dynamic> map) {
    return WeeklyInsights(
      weeklyWorkoutCounts: _safeParseWeeklyDataList(map['weeklyWorkoutCounts']),
      weeklyDurations: _safeParseWeeklyDataList(map['weeklyDurations']),
      weeklyVolumes: _safeParseWeeklyDataList(map['weeklyVolumes']),
      averageWorkoutsPerWeek: _safeParseDouble(map['averageWorkoutsPerWeek']),
      averageDuration: _safeParseDouble(map['averageDuration']),
      averageVolume: _safeParseDouble(map['averageVolume']),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
    );
  }

  static double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<WeeklyDataPoint> _safeParseWeeklyDataList(dynamic value) {
    if (value == null || value is! List) return [];
    try {
      return value
          .whereType<Map<String, dynamic>>()
          .map((e) => WeeklyDataPoint.fromMap(e))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
