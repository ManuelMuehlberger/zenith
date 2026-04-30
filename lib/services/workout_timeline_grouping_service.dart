import 'package:intl/intl.dart';

import '../models/workout.dart';

/// Groups workouts for the Home timeline into:
/// - recent: workouts within the last [recentDays] (inclusive)
/// - archive: older workouts grouped by month+year
///
/// Also calculates aggregate metrics per group.
class WorkoutTimelineGroupingService {
  static const int defaultRecentDays = 10;

  /// Split a list of workouts into [WorkoutTimelineBuckets].
  ///
  /// Rules:
  /// - Only considers completed workouts (status == completed)
  /// - Uses completedAt (fallback to startedAt) as the timestamp
  /// - recent: timestamp >= now - recentDays
  /// - archive: timestamp < now - recentDays, grouped by Month+Year
  static WorkoutTimelineBuckets splitWorkouts(
    List<Workout> workouts, {
    DateTime? now,
    int recentDays = defaultRecentDays,
  }) {
    final effectiveNow = now ?? DateTime.now();
    // Use start of day for cutoff to ensure we include workouts from the full 'recentDays' window
    // regardless of the current time of day.
    final startOfToday = DateTime(effectiveNow.year, effectiveNow.month, effectiveNow.day);
    final cutoff = startOfToday.subtract(Duration(days: recentDays));

    final completed = workouts.where((w) {
      if (w.status != WorkoutStatus.completed) return false;
      return _timestampOf(w) != null;
    }).toList(growable: false);

    final recent = <Workout>[];
    final Map<MonthKey, List<Workout>> byMonth = {};

    for (final w in completed) {
      final t = _timestampOf(w)!;
      if (!t.isBefore(cutoff)) {
        recent.add(w);
      } else {
        final key = MonthKey(year: t.year, month: t.month);
        (byMonth[key] ??= <Workout>[]).add(w);
      }
    }

    // Sort recent desc
    recent.sort((a, b) => _timestampOf(b)!.compareTo(_timestampOf(a)!));

    // Build archive groups sorted desc by month
    final keys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    final archiveGroups = <MonthlyWorkoutGroup>[];
    for (final key in keys) {
      final items = byMonth[key]!;
      items.sort((a, b) => _timestampOf(b)!.compareTo(_timestampOf(a)!));
      archiveGroups.add(MonthlyWorkoutGroup.fromWorkouts(key: key, workouts: items));
    }

    return WorkoutTimelineBuckets(
      recent: recent,
      archive: archiveGroups,
    );
  }

  static DateTime? _timestampOf(Workout workout) => workout.completedAt ?? workout.startedAt;
}

class WorkoutTimelineBuckets {
  final List<Workout> recent;
  final List<MonthlyWorkoutGroup> archive;

  const WorkoutTimelineBuckets({
    required this.recent,
    required this.archive,
  });
}

/// Year+month identifier with ordering.
class MonthKey implements Comparable<MonthKey> {
  final int year;
  final int month; // 1-12

  const MonthKey({required this.year, required this.month});

  DateTime get startOfMonth => DateTime(year, month, 1);

  String get monthName => DateFormat.MMMM().format(startOfMonth);

  String get monthYearLabel => DateFormat('MMMM yyyy').format(startOfMonth);

  @override
  int compareTo(MonthKey other) {
    if (year != other.year) return year.compareTo(other.year);
    return month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthKey && other.year == year && other.month == month;
  }

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// Aggregate metrics for a month group.
class MonthlyWorkoutGroup {
  final MonthKey key;
  final List<Workout> workouts;

  final int workoutCount;
  final double totalVolume; // from Workout.totalWeight
  final Duration totalTime; // sum of completedAt-startedAt if both present

  const MonthlyWorkoutGroup({
    required this.key,
    required this.workouts,
    required this.workoutCount,
    required this.totalVolume,
    required this.totalTime,
  });

  factory MonthlyWorkoutGroup.fromWorkouts({
    required MonthKey key,
    required List<Workout> workouts,
  }) {
    final count = workouts.length;
    final totalVolume = workouts.fold<double>(0, (sum, w) => sum + w.totalWeight);
    final totalTime = workouts.fold<Duration>(Duration.zero, (sum, w) {
      final s = w.startedAt;
      final c = w.completedAt;
      if (s == null || c == null) return sum;
      final d = c.difference(s);
      if (d.isNegative) return sum;
      return sum + d;
    });

    return MonthlyWorkoutGroup(
      key: key,
      workouts: workouts,
      workoutCount: count,
      totalVolume: totalVolume,
      totalTime: totalTime,
    );
  }
}
