import '../../models/insights.dart';

class InsightsTimeframeResolver {
  static InsightsGrouping resolveGrouping({
    required int monthsBack,
    int? weeksBack,
    InsightsGrouping? grouping,
  }) {
    if (grouping != null) {
      return grouping;
    }
    if (weeksBack == 1 || monthsBack == 1) {
      return InsightsGrouping.day;
    }
    if (monthsBack <= 6) {
      return InsightsGrouping.week;
    }
    return InsightsGrouping.month;
  }

  static int weeklyTimeSlots({
    required InsightsGrouping grouping,
    required int effectiveMonths,
    int? weeksBack,
  }) {
    if (grouping == InsightsGrouping.day) {
      return weeksBack == 1 ? 7 : 30;
    }
    if (grouping == InsightsGrouping.week) {
      return (effectiveMonths * 4.33).ceil();
    }
    return effectiveMonths;
  }

  static String weeklyTimeframeLabel({
    required int effectiveMonths,
    int? weeksBack,
  }) {
    if (weeksBack == 1) {
      return '1W';
    }
    if (effectiveMonths == 1) {
      return '1M';
    }
    if (effectiveMonths > 6) {
      return '1Y';
    }
    return '6M';
  }

  static String workoutInsightsCacheKey({
    required int monthsBack,
    required int? weeksBack,
    required InsightsGrouping grouping,
    required String? workoutName,
    required String? muscleGroup,
    required String? equipment,
    required bool? isBodyWeight,
  }) {
    return 'insights_${monthsBack}m_${weeksBack ?? 0}w_${grouping.name}_${workoutName ?? "all"}_${muscleGroup ?? "all"}_${equipment ?? "all"}_${isBodyWeight ?? "all"}';
  }

  static String exerciseInsightsCacheKey({
    required String exerciseName,
    required int monthsBack,
    required int? weeksBack,
    required InsightsGrouping grouping,
  }) {
    return 'exercise_${exerciseName.trim().toLowerCase()}_${monthsBack}m_${weeksBack ?? 0}w_${grouping.name}';
  }

  static String weeklyInsightsCacheKey({
    required int effectiveMonths,
    required int timeSlots,
    required InsightsGrouping grouping,
    required String? workoutName,
    required String? muscleGroup,
    required String? equipment,
    required bool? isBodyWeight,
  }) {
    return 'weekly_insights_${effectiveMonths}m_${timeSlots}_${grouping.name}_${workoutName ?? "all"}_${muscleGroup ?? "all"}_${equipment ?? "all"}_${isBodyWeight ?? "all"}';
  }
}