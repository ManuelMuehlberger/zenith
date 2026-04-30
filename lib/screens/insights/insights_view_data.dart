import '../../models/workout.dart';

class WorkoutDisplayItem {
  final Workout workout;
  final Workout? workoutDetails;

  const WorkoutDisplayItem({
    required this.workout,
    this.workoutDetails,
  });
}

class InsightsTimeframeOption {
  final String label;
  final int months;

  const InsightsTimeframeOption({
    required this.label,
    required this.months,
  });
}

class InsightsFilterSnapshot {
  final String timeframe;
  final String? workoutName;
  final String? muscleGroup;
  final String? equipment;
  final bool? isBodyWeight;

  const InsightsFilterSnapshot({
    required this.timeframe,
    this.workoutName,
    this.muscleGroup,
    this.equipment,
    this.isBodyWeight,
  });

  Map<String, dynamic> toProviderFilters() {
    return {
      'workoutName': workoutName,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'isBodyWeight': isBodyWeight,
      'timeframe': timeframe,
    };
  }

  bool get hasAnyFilter {
    return workoutName != null ||
        muscleGroup != null ||
        equipment != null ||
        isBodyWeight != null;
  }
}

const List<InsightsTimeframeOption> insightsTimeframeOptions = [
  InsightsTimeframeOption(label: '1W', months: 0),
  InsightsTimeframeOption(label: '1M', months: 1),
  InsightsTimeframeOption(label: '3M', months: 3),
  InsightsTimeframeOption(label: '6M', months: 6),
  InsightsTimeframeOption(label: '1Y', months: 12),
  InsightsTimeframeOption(label: '2Y', months: 24),
  InsightsTimeframeOption(label: 'All', months: 999),
];