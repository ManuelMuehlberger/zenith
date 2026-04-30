import 'package:flutter_test/flutter_test.dart';

import 'package:zenith/models/workout.dart';
import 'package:zenith/services/workout_timeline_grouping_service.dart';

void main() {
  group('WorkoutTimelineGroupingService', () {
    test('splits into recent and month-grouped archive, computing aggregates', () {
      final now = DateTime(2025, 12, 15, 12);

      // Recent (within 7 days)
      final recent1 = Workout(
        id: 'r1',
        name: 'Recent 1',
        status: WorkoutStatus.completed,
        startedAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1)),
        exercises: const [],
      );

      // Archive: October 2025
      final oct1 = Workout(
        id: 'o1',
        name: 'Oct 1',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2025, 10, 10, 10),
        completedAt: DateTime(2025, 10, 10, 11),
        exercises: const [],
      );
      final oct2 = Workout(
        id: 'o2',
        name: 'Oct 2',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2025, 10, 20, 10),
        completedAt: DateTime(2025, 10, 20, 12),
        exercises: const [],
      );

      // Archive: September 2025
      final sep1 = Workout(
        id: 's1',
        name: 'Sep 1',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2025, 9, 2, 10),
        completedAt: DateTime(2025, 9, 2, 10, 30),
        exercises: const [],
      );

      // Not completed => ignored
      final inProgress = Workout(
        id: 'ip',
        name: 'IP',
        status: WorkoutStatus.inProgress,
        startedAt: now.subtract(const Duration(days: 1)),
        exercises: const [],
      );

      final result = WorkoutTimelineGroupingService.splitWorkouts(
        [inProgress, oct1, sep1, recent1, oct2],
        now: now,
        recentDays: 7,
      );

      expect(result.recent.length, 1);
      expect(result.recent.first.id, 'r1');

      expect(result.archive.length, 2);
      expect(result.archive[0].key, const MonthKey(year: 2025, month: 10));
      expect(result.archive[0].workoutCount, 2);
      expect(result.archive[0].totalTime, const Duration(hours: 3));

      expect(result.archive[1].key, const MonthKey(year: 2025, month: 9));
      expect(result.archive[1].workoutCount, 1);
      expect(result.archive[1].totalTime, const Duration(minutes: 30));

      // Ensure month group sorting within each month is newest first
      expect(result.archive[0].workouts.map((w) => w.id).toList(), ['o2', 'o1']);
    });
  });
}
