import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../insights_service.dart';
import '../exercise_service.dart';
import '../../models/exercise.dart';
import 'insight_data_provider.dart';

enum WorkoutTrendType {
  count,
  duration,
  volume,
  sets
}

class WorkoutTrendProvider implements InsightDataProvider {
  final WorkoutTrendType type;

  WorkoutTrendProvider(this.type);

  @override
  Future<List<InsightDataPoint>> getData({
    required String timeframe,
    required int monthsBack,
    Map<String, dynamic> filters = const {},
  }) async {
    final grouping = InsightsService.getGroupingForTimeframe(timeframe);
    final workouts = await InsightsService.instance.getWorkouts();
    
    final workoutName = filters['workoutName'] as String?;
    final muscleGroup = filters['muscleGroup'] as String?;
    final equipment = filters['equipment'] as String?;
    final isBodyWeight = filters['isBodyWeight'] as bool?;
    final weeksBack = (timeframe == '1W' && monthsBack <= 1) ? 1 : null;

    // Filter workouts
    final now = DateTime.now();
    final workoutsWithDates = workouts
        .where((w) => w.startedAt != null && w.status == WorkoutStatus.completed)
        .toList();

    if (workoutsWithDates.isEmpty) return [];

    final latestWorkoutDate = workoutsWithDates
        .map((w) => w.startedAt!)
        .reduce((latest, date) => date.isAfter(latest) ? date : latest);
    final referenceDate = latestWorkoutDate.isAfter(now) ? now : latestWorkoutDate;

    final DateTime cutoffDate;
    if (weeksBack != null && weeksBack > 0) {
      cutoffDate = referenceDate.subtract(Duration(days: weeksBack * 7));
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

    // Calculate trend data
    return _calculateTrendData(
      recentWorkouts,
      monthsBack,
      weeksBack,
      grouping,
      referenceDate: referenceDate,
      muscleGroup: muscleGroup,
      equipment: equipment,
      isBodyWeight: isBodyWeight,
    );
  }

  Exercise? _getExerciseDetail(String slug) {
    try {
      return ExerciseService.instance.exercises.firstWhere((e) => e.slug == slug);
    } catch (e) {
      return null;
    }
  }

  List<InsightDataPoint> _calculateTrendData(
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

      double value = 0;
      double? minValue;
      double? maxValue;

      switch (type) {
        case WorkoutTrendType.count:
          value = slotWorkouts.length.toDouble();
          minValue = 0;
          maxValue = value;
          break;
        case WorkoutTrendType.duration:
          // Value is total duration in hours (for TrendInsightCard)
          value = slotWorkouts.fold<double>(0, (sum, workout) => 
              sum + ((workout.completedAt != null && workout.startedAt != null 
                  ? workout.completedAt!.difference(workout.startedAt!).inMinutes 
                  : 0) / 60.0));
          
          // Min/Max is duration in minutes (for WorkoutDurationCard)
          if (slotWorkouts.isNotEmpty) {
            final durations = slotWorkouts
                .where((w) => w.completedAt != null && w.startedAt != null)
                .map((w) => w.completedAt!.difference(w.startedAt!).inMinutes.toDouble())
                .toList();
            
            if (durations.isNotEmpty) {
              minValue = durations.reduce((a, b) => a < b ? a : b);
              maxValue = durations.reduce((a, b) => a > b ? a : b);
            } else {
              minValue = 0;
              maxValue = 0;
            }
          } else {
            minValue = 0;
            maxValue = 0;
          }
          break;
        case WorkoutTrendType.volume:
          // Value is total volume (for TrendInsightCard)
          value = slotWorkouts.fold<double>(0, (sum, workout) => 
              sum + _calculateWorkoutVolume(workout, muscleGroup, equipment, isBodyWeight));
          
          // Min/Max is volume per workout (for WorkoutVolumeCard)
          if (slotWorkouts.isNotEmpty) {
            final volumes = slotWorkouts.map((w) => 
                _calculateWorkoutVolume(w, muscleGroup, equipment, isBodyWeight)).toList();
            
            if (volumes.isNotEmpty) {
              minValue = volumes.reduce((a, b) => a < b ? a : b);
              maxValue = volumes.reduce((a, b) => a > b ? a : b);
            } else {
              minValue = 0;
              maxValue = 0;
            }
          } else {
            minValue = 0;
            maxValue = 0;
          }
          break;
        case WorkoutTrendType.sets:
          // Value is total sets
          value = slotWorkouts.fold<double>(0, (sum, workout) => 
              sum + _calculateWorkoutSets(workout, muscleGroup, equipment, isBodyWeight));
          
          // Min/Max is sets per workout
          if (slotWorkouts.isNotEmpty) {
            final sets = slotWorkouts.map((w) => 
                _calculateWorkoutSets(w, muscleGroup, equipment, isBodyWeight)).toList();
            
            if (sets.isNotEmpty) {
              minValue = sets.reduce((a, b) => a < b ? a : b);
              maxValue = sets.reduce((a, b) => a > b ? a : b);
            } else {
              minValue = 0;
              maxValue = 0;
            }
          } else {
            minValue = 0;
            maxValue = 0;
          }
          break;
      }

      trendData.add(InsightDataPoint(
        date: slotStart,
        value: value,
        minValue: minValue,
        maxValue: maxValue,
        count: slotWorkouts.length,
      ));
    }

    return trendData;
  }

  double _calculateWorkoutVolume(Workout workout, String? muscleGroup, String? equipment, bool? isBodyWeight) {
    return workout.exercises.fold(0.0, (exerciseSum, exercise) {
      if (!_matchesFilters(exercise, muscleGroup, equipment, isBodyWeight)) return exerciseSum;

      return exerciseSum + exercise.sets.fold(0.0, (setSum, set) => 
            setSum + (set.actualWeight ?? 0.0) * (set.actualReps ?? 0));
    });
  }

  double _calculateWorkoutSets(Workout workout, String? muscleGroup, String? equipment, bool? isBodyWeight) {
    return workout.exercises.fold(0.0, (exerciseSum, exercise) {
      if (!_matchesFilters(exercise, muscleGroup, equipment, isBodyWeight)) return exerciseSum;

      return exerciseSum + exercise.sets.length;
    });
  }

  bool _matchesFilters(WorkoutExercise exercise, String? muscleGroup, String? equipment, bool? isBodyWeight) {
    if (muscleGroup == null && equipment == null && isBodyWeight == null) return true;

    final exerciseDetail = _getExerciseDetail(exercise.exerciseSlug);
    if (exerciseDetail == null) return false;

    if (muscleGroup != null && exerciseDetail.primaryMuscleGroup.name != muscleGroup) return false;
    if (equipment != null) {
        final normalizedExerciseEquipment = exerciseDetail.equipment == 'Dumbell' ? 'Dumbbell' : exerciseDetail.equipment;
        if (normalizedExerciseEquipment != equipment) return false;
    }
    if (isBodyWeight != null && exerciseDetail.isBodyWeightExercise != isBodyWeight) return false;

    return true;
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }
}
