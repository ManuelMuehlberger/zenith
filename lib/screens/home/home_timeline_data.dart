import '../../models/workout.dart';
import '../../widgets/timeline/timeline_list_item.dart';

class HomeTimelineData {
  final List<TimelineListItem> items;
  final HomeOverviewData overview;

  const HomeTimelineData({required this.items, required this.overview});
}

class HomeTimelineAssembler {
  static const int recentWorkoutLimit = 3;

  static HomeTimelineData build(List<Workout> workouts) {
    final overview = HomeOverviewAssembler.build(workouts);
    final recentWorkouts = workouts.where((workout) {
      return workout.status == WorkoutStatus.completed &&
          _timestampOf(workout) != null;
    }).toList()..sort((a, b) => _timestampOf(b)!.compareTo(_timestampOf(a)!));

    final recentLimited = recentWorkouts.take(recentWorkoutLimit).toList();
    final items = <TimelineListItem>[];

    if (recentLimited.isNotEmpty) {
      DateTime? currentDay;
      List<Workout> currentGroup = [];

      for (final workout in recentLimited) {
        final date = workout.completedAt ?? workout.startedAt ?? DateTime.now();
        final day = DateTime(date.year, date.month, date.day);

        if (currentDay == null) {
          currentDay = day;
          currentGroup.add(workout);
          continue;
        }

        if (currentDay == day) {
          currentGroup.add(workout);
          continue;
        }

        items.add(
          TimelineDayGroupItem(
            date: currentDay,
            workouts: List<Workout>.from(currentGroup),
          ),
        );
        currentDay = day;
        currentGroup = [workout];
      }

      if (currentGroup.isNotEmpty && currentDay != null) {
        items.add(
          TimelineDayGroupItem(
            date: currentDay,
            workouts: List<Workout>.from(currentGroup),
          ),
        );
      }

      items.add(
        TimelineHistoryEndcapItem(completedWorkoutCount: recentWorkouts.length),
      );
    }

    return HomeTimelineData(items: items, overview: overview);
  }

  static DateTime? _timestampOf(Workout workout) =>
      workout.completedAt ?? workout.startedAt;
}

// policy: allow-public-api overview payload shared by Home screen widgets and tests.
class HomeOverviewData {
  final List<Workout> suggestedWorkouts;
  final HomeWeekSummary weekSummary;
  final int weeklyStreak;
  final HomeMetricTrend durationTrend;

  const HomeOverviewData({
    required this.suggestedWorkouts,
    required this.weekSummary,
    required this.weeklyStreak,
    required this.durationTrend,
  });
}

// policy: allow-public-api weekly consistency summary consumed by the Home overview UI.
class HomeWeekSummary {
  final List<HomeWeekDay> days;
  final int workoutCount;
  final String weekLabel;

  const HomeWeekSummary({
    required this.days,
    required this.workoutCount,
    required this.weekLabel,
  });
}

// policy: allow-public-api display model for the Home weekly consistency row.
class HomeWeekDay {
  final String label;
  final bool hasWorkout;
  final bool isToday;

  const HomeWeekDay({
    required this.label,
    required this.hasWorkout,
    required this.isToday,
  });
}

// policy: allow-public-api trend direction contract shared with the Home overview UI.
enum HomeTrendDirection { up, down, flat, none }

// policy: allow-public-api trend metric payload shared with the Home overview UI.
class HomeMetricTrend {
  final String label;
  final String value;
  final String unit;
  final String comparisonLabel;
  final HomeTrendDirection direction;
  final double? percentChange;

  const HomeMetricTrend({
    required this.label,
    required this.value,
    required this.unit,
    required this.comparisonLabel,
    required this.direction,
    required this.percentChange,
  });
}

// policy: allow-public-api assembler is exercised directly by Home data tests.
class HomeOverviewAssembler {
  static HomeOverviewData build(List<Workout> workouts, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    final today = DateTime(
      effectiveNow.year,
      effectiveNow.month,
      effectiveNow.day,
    );
    final completedWorkouts = _completedWorkouts(workouts);
    final workoutDays = {
      for (final workout in completedWorkouts)
        _dayOf(_timestampOf(workout)!): true,
    };
    final workoutWeeks = {
      for (final workout in completedWorkouts)
        _startOfWeek(_timestampOf(workout)!): true,
    };

    return HomeOverviewData(
      suggestedWorkouts: _suggestedWorkouts(workouts),
      weekSummary: _weekSummary(today: today, workoutDays: workoutDays.keys),
      weeklyStreak: _weeklyStreak(
        today: today,
        completedWorkouts: completedWorkouts,
        workoutWeeks: workoutWeeks.keys,
      ),
      durationTrend: _durationTrend(today: today, workouts: completedWorkouts),
    );
  }

  static List<Workout> _suggestedWorkouts(List<Workout> workouts) {
    final templates = workouts
        .where((workout) => workout.status == WorkoutStatus.template)
        .toList();

    templates.sort((a, b) {
      final aLastUsed = _parseDate(a.lastUsed);
      final bLastUsed = _parseDate(b.lastUsed);
      if (aLastUsed != null || bLastUsed != null) {
        return (bLastUsed ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          aLastUsed ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      }

      final aOrder = a.orderIndex;
      final bOrder = b.orderIndex;
      if (aOrder != null || bOrder != null) {
        return (aOrder ?? 1 << 30).compareTo(bOrder ?? 1 << 30);
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return templates.take(3).toList();
  }

  static List<Workout> _completedWorkouts(List<Workout> workouts) {
    return workouts.where((workout) {
      return workout.status == WorkoutStatus.completed &&
          _timestampOf(workout) != null;
    }).toList()..sort((a, b) => _timestampOf(b)!.compareTo(_timestampOf(a)!));
  }

  static HomeWeekSummary _weekSummary({
    required DateTime today,
    required Iterable<DateTime> workoutDays,
  }) {
    final currentMonday = _startOfWeek(today);
    final displayMonday = today.weekday == DateTime.monday
        ? currentMonday.subtract(const Duration(days: 7))
        : currentMonday;
    final workoutDaySet = workoutDays.toSet();
    final days = List.generate(7, (index) {
      final date = displayMonday.add(Duration(days: index));
      return HomeWeekDay(
        label: _weekdayLabel(index),
        hasWorkout: workoutDaySet.contains(date),
        isToday: date == today,
      );
    });

    return HomeWeekSummary(
      days: days,
      workoutCount: days.where((day) => day.hasWorkout).length,
      weekLabel: displayMonday == currentMonday ? 'This week' : 'Last week',
    );
  }

  static int _weeklyStreak({
    required DateTime today,
    required List<Workout> completedWorkouts,
    required Iterable<DateTime> workoutWeeks,
  }) {
    if (completedWorkouts.isEmpty) {
      return 0;
    }

    final workoutWeekSet = workoutWeeks.toSet();
    final latestWorkoutWeek = _startOfWeek(
      _timestampOf(completedWorkouts.first)!,
    );
    var weekStreak = 0;

    for (
      var cursor = latestWorkoutWeek;
      workoutWeekSet.contains(cursor);
      cursor = cursor.subtract(const Duration(days: 7))
    ) {
      weekStreak++;
    }

    return weekStreak;
  }

  static HomeMetricTrend _durationTrend({
    required DateTime today,
    required List<Workout> workouts,
  }) {
    final recentStart = today.subtract(const Duration(days: 13));
    final recentDurations = <Duration>[];
    final baselineDurations = <Duration>[];

    for (final workout in workouts) {
      final timestamp = _timestampOf(workout);
      final duration = _durationOf(workout);
      if (timestamp == null || duration == null) {
        continue;
      }

      final workoutDay = _dayOf(timestamp);
      if (!workoutDay.isBefore(recentStart) && !workoutDay.isAfter(today)) {
        recentDurations.add(duration);
      } else if (workoutDay.isBefore(recentStart)) {
        baselineDurations.add(duration);
      }
    }

    final recentAverage = _averageDuration(recentDurations);
    final baselineAverage = _averageDuration(baselineDurations);

    if (recentAverage == null) {
      return const HomeMetricTrend(
        label: 'Duration Trend',
        value: '0',
        unit: 'min avg',
        comparisonLabel: 'last 14 days',
        direction: HomeTrendDirection.none,
        percentChange: null,
      );
    }

    if (baselineAverage == null || baselineAverage.inMilliseconds == 0) {
      return HomeMetricTrend(
        label: 'Duration Trend',
        value: _formatDurationValue(recentAverage),
        unit: _formatDurationUnit(recentAverage),
        comparisonLabel: 'new baseline',
        direction: HomeTrendDirection.none,
        percentChange: null,
      );
    }

    final percentChange =
        (recentAverage.inMilliseconds - baselineAverage.inMilliseconds) /
        baselineAverage.inMilliseconds;
    final direction = percentChange.abs() < 0.05
        ? HomeTrendDirection.flat
        : percentChange > 0
        ? HomeTrendDirection.up
        : HomeTrendDirection.down;
    final comparison = switch (direction) {
      HomeTrendDirection.up =>
        '+${(percentChange.abs() * 100).round()}% vs avg',
      HomeTrendDirection.down =>
        '-${(percentChange.abs() * 100).round()}% vs avg',
      HomeTrendDirection.flat => 'steady vs avg',
      HomeTrendDirection.none => 'new baseline',
    };

    return HomeMetricTrend(
      label: 'Duration Trend',
      value: _formatDurationValue(recentAverage),
      unit: _formatDurationUnit(recentAverage),
      comparisonLabel: comparison,
      direction: direction,
      percentChange: percentChange,
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static DateTime? _timestampOf(Workout workout) =>
      workout.completedAt ?? workout.startedAt;

  static Duration? _durationOf(Workout workout) {
    final startedAt = workout.startedAt;
    final completedAt = workout.completedAt;
    if (startedAt == null || completedAt == null) {
      return null;
    }

    final duration = completedAt.difference(startedAt);
    if (duration.isNegative) {
      return null;
    }
    return duration;
  }

  static Duration? _averageDuration(List<Duration> durations) {
    if (durations.isEmpty) {
      return null;
    }

    return Duration(
      milliseconds:
          durations.fold<int>(
            0,
            (sum, duration) => sum + duration.inMilliseconds,
          ) ~/
          durations.length,
    );
  }

  static DateTime _startOfWeek(DateTime date) {
    final day = _dayOf(date);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime _dayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _weekdayLabel(int index) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[index];
  }

  static String _formatDurationValue(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      if (minutes == 0) {
        return '$hours';
      }
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    }

    return '${duration.inMinutes}';
  }

  static String _formatDurationUnit(Duration duration) {
    if (duration.inHours > 0) {
      return 'hrs avg';
    }
    return 'min avg';
  }
}
