import '../../models/workout.dart';
import '../insights_service.dart';
import 'insight_data_provider.dart';

enum ExerciseTrendType {
  volume,
  maxWeight,
  frequency
}

class ExerciseTrendProvider implements InsightDataProvider {
  final String exerciseName;
  final ExerciseTrendType type;

  ExerciseTrendProvider(this.exerciseName, this.type);

  @override
  Future<List<InsightDataPoint>> getData({
    required String timeframe,
    required int monthsBack,
    Map<String, dynamic> filters = const {},
  }) async {
    final grouping = InsightsService.getGroupingForTimeframe(timeframe);
    final workouts = await InsightsService.instance.getWorkouts();
    final weeksBack = (timeframe == '1W' && monthsBack <= 1) ? 1 : null;

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
      return [];
    }

    // Determine reference date
    final now = DateTime.now();
    final latestInstanceDate = allExerciseInstances
        .map((i) => i.date)
        .reduce((latest, date) => date.isAfter(latest) ? date : latest);
    final referenceDate = latestInstanceDate.isAfter(now) ? now : latestInstanceDate;

    // Calculate trend data
    return _calculateExerciseTrendData(
      allExerciseInstances,
      monthsBack,
      weeksBack,
      grouping,
      referenceDate,
    );
  }

  List<InsightDataPoint> _calculateExerciseTrendData(
      List<ExerciseInstance> allInstances, 
      int monthsBack,
      int? weeksBack,
      InsightsGrouping grouping,
      DateTime referenceDate,
  ) {
    final trendData = <InsightDataPoint>[];

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
    if (type == ExerciseTrendType.maxWeight) {
      final priorInstances = allInstances.where((i) => i.date.isBefore(firstSlotStart));
      if (priorInstances.isNotEmpty) {
        currentMaxWeight = priorInstances.map((i) => i.maxWeight).reduce((a, b) => a > b ? a : b);
      }
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

      double value = 0;
      switch (type) {
        case ExerciseTrendType.volume:
          value = slotInstances.fold<double>(0, (sum, instance) => sum + instance.totalWeight);
          break;
        case ExerciseTrendType.frequency:
          value = slotInstances.length.toDouble();
          break;
        case ExerciseTrendType.maxWeight:
          if (slotInstances.isNotEmpty) {
            final slotMax = slotInstances.map((i) => i.maxWeight).reduce((a, b) => a > b ? a : b);
            if (slotMax > currentMaxWeight) {
              currentMaxWeight = slotMax;
            }
          }
          value = currentMaxWeight;
          break;
      }

      trendData.add(InsightDataPoint(
        date: slotStart,
        value: value,
      ));
    }

    return trendData;
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }
}
