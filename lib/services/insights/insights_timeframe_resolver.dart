import '../../models/insights.dart';

class InsightsTimeframeResolver {
  static DateTime resolveWindowStart({
    required DateTime referenceDate,
    required int monthsBack,
    int? weeksBack,
    required InsightsGrouping grouping,
  }) {
    if (weeksBack == 1) {
      final dayStart = _dayStart(referenceDate);
      return DateTime(dayStart.year, dayStart.month, dayStart.day - 6);
    }

    if (grouping == InsightsGrouping.day) {
      return DateTime(
        referenceDate.year,
        referenceDate.month - (monthsBack - 1),
        1,
      );
    }

    if (grouping == InsightsGrouping.week) {
      final weekStart = _weekStart(referenceDate);
      final slots = resolveSlotCount(
        referenceDate: referenceDate,
        monthsBack: monthsBack,
        weeksBack: weeksBack,
        grouping: grouping,
      );
      return DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day - ((slots - 1) * 7),
      );
    }

    return DateTime(
      referenceDate.year,
      referenceDate.month - (monthsBack - 1),
      1,
    );
  }

  static int resolveSlotCount({
    required DateTime referenceDate,
    required int monthsBack,
    int? weeksBack,
    required InsightsGrouping grouping,
  }) {
    if (weeksBack == 1) {
      return 7;
    }
    if (grouping == InsightsGrouping.day) {
      final windowStart = resolveWindowStart(
        referenceDate: referenceDate,
        monthsBack: monthsBack,
        weeksBack: weeksBack,
        grouping: grouping,
      );
      final dayAfterReference = _dayStart(
        referenceDate,
      ).add(const Duration(days: 1));
      return dayAfterReference.difference(windowStart).inDays;
    }
    if (grouping == InsightsGrouping.week) {
      return (monthsBack * 4.33).ceil();
    }
    return monthsBack;
  }

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

  static DateTime _weekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return _dayStart(date).subtract(Duration(days: daysFromMonday));
  }

  static DateTime _dayStart(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
