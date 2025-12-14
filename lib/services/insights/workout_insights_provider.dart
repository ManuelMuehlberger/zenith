import '../../models/workout.dart';
import '../insights_service.dart';
import '../exercise_service.dart';
import '../../models/exercise.dart';

class WorkoutInsightsProvider {
  Future<WorkoutInsights> getData({
    String? timeframe,
    required int monthsBack,
    int? weeksBack,
    InsightsGrouping? grouping,
    Map<String, dynamic> filters = const {},
  }) async {
    final finalGrouping = grouping ?? (timeframe != null ? InsightsService.getGroupingForTimeframe(timeframe) : _determineGrouping(monthsBack, weeksBack));
    final finalWeeksBack = weeksBack ?? (timeframe == '1W' ? 1 : null);
    
    final workouts = await InsightsService.instance.getWorkouts();
    
    final workoutName = filters['workoutName'] as String?;
    final muscleGroup = filters['muscleGroup'] as String?;
    final equipment = filters['equipment'] as String?;
    final isBodyWeight = filters['isBodyWeight'] as bool?;

    final now = DateTime.now();
    final workoutsWithDates = workouts
        .where((w) => w.startedAt != null && w.status == WorkoutStatus.completed)
        .toList();

    final DateTime referenceDate;
    if (workoutsWithDates.isNotEmpty) {
      final latestWorkoutDate = workoutsWithDates
          .map((w) => w.startedAt!)
          .reduce((latest, date) => date.isAfter(latest) ? date : latest);
      referenceDate = latestWorkoutDate.isAfter(now) ? now : latestWorkoutDate;
    } else {
      referenceDate = now;
    }
    
    final DateTime cutoffDate;
    if (finalWeeksBack != null && finalWeeksBack > 0) {
      cutoffDate = referenceDate.subtract(Duration(days: finalWeeksBack * 7));
    } else {
      cutoffDate = DateTime(referenceDate.year, referenceDate.month - (monthsBack - 1), 1);
    }

    final recentWorkouts = workouts.where((workout) {
      if (workout.startedAt == null || workout.status != WorkoutStatus.completed) return false;
      
      final startedAt = workout.startedAt!;
      if (startedAt.isBefore(cutoffDate)) return false;
      if (startedAt.isAfter(now)) return false;

      if (workoutName != null && workout.name != workoutName) return false;

      bool hasMatchingExercise = true;
      if (muscleGroup != null || equipment != null || isBodyWeight != null) {
        hasMatchingExercise = workout.exercises.any((exercise) {
          final exerciseDetail = _getExerciseDetail(exercise.exerciseSlug);
          if (exerciseDetail == null) return false;

          bool matches = true;
          if (muscleGroup != null && exerciseDetail.primaryMuscleGroup.name != muscleGroup) matches = false;
          if (equipment != null) {
             final normalizedExerciseEquipment = exerciseDetail.equipment == 'Dumbell' ? 'Dumbbell' : exerciseDetail.equipment;
             if (normalizedExerciseEquipment != equipment) matches = false;
          }
          if (isBodyWeight != null && exerciseDetail.isBodyWeightExercise != isBodyWeight) matches = false;
          return matches;
        });
      }
      return hasMatchingExercise;
    }).toList();

    final totalWorkouts = recentWorkouts.length;
    final totalHours = recentWorkouts.fold<double>(0, (sum, workout) => 
        sum + ((workout.completedAt != null && workout.startedAt != null 
            ? workout.completedAt!.difference(workout.startedAt!).inMinutes 
            : 0) / 60.0));
    
    final totalWeight = recentWorkouts.fold<double>(0, (sum, workout) => 
        sum + workout.exercises.fold(0.0, (exerciseSum, exercise) {
          if (muscleGroup != null || equipment != null || isBodyWeight != null) {
            final exerciseDetail = _getExerciseDetail(exercise.exerciseSlug);
            if (exerciseDetail == null) return exerciseSum;

            if (muscleGroup != null && exerciseDetail.primaryMuscleGroup.name != muscleGroup) return exerciseSum;
            if (equipment != null) {
               final normalizedExerciseEquipment = exerciseDetail.equipment == 'Dumbell' ? 'Dumbbell' : exerciseDetail.equipment;
               if (normalizedExerciseEquipment != equipment) return exerciseSum;
            }
            if (isBodyWeight != null && exerciseDetail.isBodyWeightExercise != isBodyWeight) return exerciseSum;
          }

          return exerciseSum + exercise.sets.fold(0.0, (setSum, set) => 
                setSum + (set.actualWeight ?? 0.0) * (set.actualReps ?? 0));
        }));

    final trendData = _calculateTrendData(
      recentWorkouts, 
      monthsBack,
      finalWeeksBack,
      finalGrouping,
      referenceDate: referenceDate,
      muscleGroup: muscleGroup,
      equipment: equipment,
      isBodyWeight: isBodyWeight,
    );

    return WorkoutInsights(
      totalWorkouts: totalWorkouts,
      totalHours: totalHours,
      totalWeight: totalWeight,
      trendWorkouts: trendData['workouts']!,
      trendHours: trendData['hours']!,
      trendWeight: trendData['weight']!,
      averageWorkoutDuration: totalWorkouts > 0 ? totalHours / totalWorkouts : 0,
      averageWeightPerWorkout: totalWorkouts > 0 ? totalWeight / totalWorkouts : 0,
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

  Exercise? _getExerciseDetail(String slug) {
    try {
      return ExerciseService.instance.exercises.firstWhere((e) => e.slug == slug);
    } catch (e) {
      return null;
    }
  }

  Map<String, List<InsightDataPoint>> _calculateTrendData(
      List<Workout> workouts, 
      int monthsBack,
      int? weeksBack,
      InsightsGrouping grouping, {
      DateTime? referenceDate,
      String? muscleGroup,
      String? equipment,
      bool? isBodyWeight,
  }) {
    final now = DateTime.now();
    final DateTime refDate = referenceDate ?? now;
    
    final trendWorkouts = <InsightDataPoint>[];
    final trendHours = <InsightDataPoint>[];
    final trendWeight = <InsightDataPoint>[];

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

    for (int i = slots - 1; i >= 0; i--) {
      final DateTime slotStart;
      final DateTime slotEnd;
      
      if (grouping == InsightsGrouping.month) {
        slotStart = DateTime(refDate.year, refDate.month - i, 1);
        slotEnd = DateTime(slotStart.year, slotStart.month + 1, 1);
      } else if (grouping == InsightsGrouping.week) {
        final weekStart = _getWeekStart(refDate);
        slotStart = weekStart.subtract(Duration(days: i * 7));
        slotEnd = slotStart.add(const Duration(days: 7));
      } else {
        final dayStart = DateTime(refDate.year, refDate.month, refDate.day);
        slotStart = dayStart.subtract(Duration(days: i));
        slotEnd = slotStart.add(const Duration(days: 1));
      }

      final slotWorkouts = workouts.where((workout) {
        final workoutDate = workout.startedAt!;
        return !workoutDate.isBefore(slotStart) && workoutDate.isBefore(slotEnd);
      }).toList();

      final workoutCount = slotWorkouts.length;
      final totalHours = slotWorkouts.fold<double>(0, (sum, workout) => 
          sum + ((workout.completedAt != null && workout.startedAt != null 
              ? workout.completedAt!.difference(workout.startedAt!).inMinutes 
              : 0) / 60.0));
      
      final totalWeight = slotWorkouts.fold<double>(0, (sum, workout) => 
          sum + workout.exercises.fold(0.0, (exerciseSum, exercise) {
            if (muscleGroup != null || equipment != null || isBodyWeight != null) {
              final exerciseDetail = _getExerciseDetail(exercise.exerciseSlug);
              if (exerciseDetail == null) return exerciseSum;

              if (muscleGroup != null && exerciseDetail.primaryMuscleGroup.name != muscleGroup) return exerciseSum;
              if (equipment != null) {
                 final normalizedExerciseEquipment = exerciseDetail.equipment == 'Dumbell' ? 'Dumbbell' : exerciseDetail.equipment;
                 if (normalizedExerciseEquipment != equipment) return exerciseSum;
              }
              if (isBodyWeight != null && exerciseDetail.isBodyWeightExercise != isBodyWeight) return exerciseSum;
            }

            return exerciseSum + exercise.sets.fold(0.0, (setSum, set) => 
                  setSum + (set.actualWeight ?? 0.0) * (set.actualReps ?? 0));
          }));

      trendWorkouts.add(InsightDataPoint(
        date: slotStart,
        value: workoutCount.toDouble(),
      ));
      
      trendHours.add(InsightDataPoint(
        date: slotStart,
        value: totalHours,
      ));
      
      trendWeight.add(InsightDataPoint(
        date: slotStart,
        value: totalWeight,
      ));
    }

    return {
      'workouts': trendWorkouts,
      'hours': trendHours,
      'weight': trendWeight,
    };
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }
}
