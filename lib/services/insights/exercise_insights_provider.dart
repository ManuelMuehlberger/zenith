import '../../models/workout.dart';
import '../insights_service.dart';

class ExerciseInsightsProvider {
  Future<ExerciseInsights> getData({
    required String exerciseName,
    required int monthsBack,
    int? weeksBack,
    InsightsGrouping? grouping,
  }) async {
    final finalGrouping = grouping ?? _determineGrouping(monthsBack, weeksBack);
    final workouts = await InsightsService.instance.getWorkouts();

    if (exerciseName.trim().isEmpty) {
      return ExerciseInsights.empty(exerciseName);
    }
    
    // Find all instances of this exercise across ALL workouts
    final allExerciseInstances = <ExerciseInstance>[];
    
    for (final workout in workouts) {
      if (workout.startedAt == null || workout.status != WorkoutStatus.completed) continue;
      
      for (final exercise in workout.exercises) {
        if (exercise.exerciseSlug.toLowerCase() == exerciseName.toLowerCase()) {
          allExerciseInstances.add(ExerciseInstance(
            date: workout.startedAt!,
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

    if (allExerciseInstances.isEmpty) {
      return ExerciseInsights.empty(exerciseName);
    }

    // Determine reference date and cutoff for filtering recent instances
    final now = DateTime.now();
    final latestInstanceDate = allExerciseInstances
        .map((i) => i.date)
        .reduce((latest, date) => date.isAfter(latest) ? date : latest);
    final referenceDate = latestInstanceDate.isAfter(now) ? now : latestInstanceDate;
    
    final DateTime cutoffDate;
    if (weeksBack != null && weeksBack > 0) {
      cutoffDate = referenceDate.subtract(Duration(days: weeksBack * 7));
    } else {
      cutoffDate = DateTime(referenceDate.year, referenceDate.month - (monthsBack - 1), 1);
    }

    // Filter for recent stats (totals)
    final recentInstances = allExerciseInstances.where((i) {
      return !i.date.isBefore(cutoffDate) && !i.date.isAfter(now);
    }).toList();

    // Calculate totals based on recent instances
    final totalSessions = recentInstances.length;
    final totalSets = recentInstances.fold<int>(0, (sum, instance) => sum + instance.totalSets);
    final totalReps = recentInstances.fold<int>(0, (sum, instance) => sum + instance.totalReps);
    final totalWeight = recentInstances.fold<double>(0, (sum, instance) => sum + instance.totalWeight);
    final maxWeight = recentInstances.isEmpty ? 0.0 : recentInstances.map((i) => i.maxWeight).reduce((a, b) => a > b ? a : b);
    
    // Calculate trend data
    final trendData = _calculateExerciseTrendData(
      allExerciseInstances, 
      monthsBack, 
      weeksBack, 
      finalGrouping, 
      referenceDate,
    );

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
      monthlyVolume: trendData['volume']!,
      monthlyMaxWeight: trendData['maxWeight']!,
      monthlyFrequency: trendData['frequency']!,
      lastUpdated: DateTime.now(),
    );
  }

  InsightsGrouping _determineGrouping(int monthsBack, int? weeksBack) {
    if (weeksBack == 1) {
      return InsightsGrouping.day;
    } else if (monthsBack == 1) {
      return InsightsGrouping.day;
    } else if (monthsBack <= 6) {
      return InsightsGrouping.week;
    } else {
      return InsightsGrouping.month;
    }
  }

  Map<String, List<InsightDataPoint>> _calculateExerciseTrendData(
      List<ExerciseInstance> allInstances, 
      int monthsBack,
      int? weeksBack,
      InsightsGrouping grouping,
      DateTime referenceDate,
  ) {
    final trendVolume = <InsightDataPoint>[];
    final trendMaxWeight = <InsightDataPoint>[];
    final trendFrequency = <InsightDataPoint>[];

    int slots;
    if (grouping == InsightsGrouping.day) {
      if (weeksBack == 1) {
        slots = 7;
      } else {
        slots = 30 * monthsBack;
      }
    } else if (grouping == InsightsGrouping.week) {
      slots = (monthsBack * 4.33).ceil();
    } else {
      slots = monthsBack;
    }

    // Calculate initial PR (max weight before the first slot)
    DateTime firstSlotStart;
    if (grouping == InsightsGrouping.month) {
      firstSlotStart = DateTime(referenceDate.year, referenceDate.month - (slots - 1), 1);
    } else if (grouping == InsightsGrouping.week) {
      final weekStart = _getWeekStart(referenceDate);
      firstSlotStart = weekStart.subtract(Duration(days: (slots - 1) * 7));
    } else {
      final dayStart = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      firstSlotStart = dayStart.subtract(Duration(days: (slots - 1)));
    }

    double currentMaxWeight = 0;
    final priorInstances = allInstances.where((i) => i.date.isBefore(firstSlotStart));
    if (priorInstances.isNotEmpty) {
      currentMaxWeight = priorInstances.map((i) => i.maxWeight).reduce((a, b) => a > b ? a : b);
    }

    for (int i = slots - 1; i >= 0; i--) {
      final DateTime slotStart;
      final DateTime slotEnd;
      
      if (grouping == InsightsGrouping.month) {
        slotStart = DateTime(referenceDate.year, referenceDate.month - i, 1);
        slotEnd = DateTime(slotStart.year, slotStart.month + 1, 1);
      } else if (grouping == InsightsGrouping.week) {
        final weekStart = _getWeekStart(referenceDate);
        slotStart = weekStart.subtract(Duration(days: i * 7));
        slotEnd = slotStart.add(const Duration(days: 7));
      } else {
        final dayStart = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
        slotStart = dayStart.subtract(Duration(days: i));
        slotEnd = slotStart.add(const Duration(days: 1));
      }

      final slotInstances = allInstances.where((instance) {
        return !instance.date.isBefore(slotStart) && instance.date.isBefore(slotEnd);
      }).toList();

      final volume = slotInstances.fold<double>(0, (sum, instance) => sum + instance.totalWeight);
      final frequency = slotInstances.length.toDouble();
      
      if (slotInstances.isNotEmpty) {
        final slotMax = slotInstances.map((i) => i.maxWeight).reduce((a, b) => a > b ? a : b);
        if (slotMax > currentMaxWeight) {
          currentMaxWeight = slotMax;
        }
      }

      trendVolume.add(InsightDataPoint(
        date: slotStart,
        value: volume,
      ));
      
      trendMaxWeight.add(InsightDataPoint(
        date: slotStart,
        value: currentMaxWeight,
      ));
      
      trendFrequency.add(InsightDataPoint(
        date: slotStart,
        value: frequency,
      ));
    }

    return {
      'volume': trendVolume,
      'maxWeight': trendMaxWeight,
      'frequency': trendFrequency,
    };
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }
}
