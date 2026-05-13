import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/services/workout_timeline_grouping_service.dart';

void main() {
  group('WorkoutTimelineGroupingService Repro', () {
    test(
      'should include workouts completed in the immediate future (due to rounding)',
      () {
        final now = DateTime(2025, 12, 15, 12, 0, 0);

        // Workout completed "in the future" (e.g. 30 seconds from now)
        final futureWorkout = Workout(
          id: 'future1',
          name: 'Future Workout',
          status: WorkoutStatus.completed,
          startedAt: now,
          completedAt: now.add(const Duration(seconds: 30)),
          exercises: const [],
        );

        // The service uses "now" as the upper bound.
        // If we pass "now" as the current time, and the workout is at now+30s,
        // it should still be included in "recent".

        final result = WorkoutTimelineGroupingService.splitWorkouts(
          [futureWorkout],
          now: now,
          recentDays: 7,
        );

        expect(
          result.recent.length,
          1,
          reason: 'Future workout should be included in recent',
        );
        expect(result.recent.first.id, 'future1');
      },
    );
  });
}
