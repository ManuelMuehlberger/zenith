import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/screens/home/home_timeline_data.dart';
import 'package:zenith/widgets/timeline/timeline_list_item.dart';

Workout _buildCompletedWorkout({
  required String id,
  required DateTime completedAt,
  double weight = 100,
  Duration duration = const Duration(hours: 1),
}) {
  return Workout(
    id: id,
    name: 'Workout $id',
    status: WorkoutStatus.completed,
    startedAt: completedAt.subtract(duration),
    completedAt: completedAt,
    exercises: [
      WorkoutExercise(
        id: 'exercise-$id',
        workoutId: id,
        exerciseSlug: 'bench-press',
        sets: [
          WorkoutSet(
            workoutExerciseId: 'exercise-$id',
            setIndex: 0,
            actualWeight: weight,
            actualReps: 5,
            isCompleted: true,
          ),
        ],
      ),
    ],
  );
}

void main() {
  test('HomeTimelineAssembler groups only the latest 3 completed workouts', () {
    final now = DateTime(2026, 6, 4, 12);
    final newest = _buildCompletedWorkout(
      id: 'newest',
      completedAt: now.subtract(const Duration(hours: 1)),
    );
    final second = _buildCompletedWorkout(
      id: 'second',
      completedAt: now.subtract(const Duration(hours: 2)),
    );
    final third = _buildCompletedWorkout(
      id: 'third',
      completedAt: now.subtract(const Duration(days: 1)),
    );
    final older = _buildCompletedWorkout(
      id: 'older',
      completedAt: now.subtract(const Duration(days: 2)),
    );
    final inProgress = Workout(
      id: 'in-progress',
      name: 'In Progress',
      status: WorkoutStatus.inProgress,
      startedAt: now,
      exercises: const [],
    );
    final missingTimestamp = Workout(
      id: 'missing-timestamp',
      name: 'Missing Timestamp',
      status: WorkoutStatus.completed,
      exercises: const [],
    );

    final timeline = HomeTimelineAssembler.build([
      older,
      inProgress,
      newest,
      missingTimestamp,
      third,
      second,
    ]);

    expect(timeline.items.whereType<TimelineDayGroupItem>(), hasLength(2));
    expect(timeline.items.last, isA<TimelineHistoryEndcapItem>());
    expect(
      (timeline.items.last as TimelineHistoryEndcapItem).completedWorkoutCount,
      4,
    );

    final displayedWorkouts = timeline.items
        .whereType<TimelineDayGroupItem>()
        .expand((item) => item.workouts)
        .toList();

    expect(displayedWorkouts, [newest, second, third]);
    expect(displayedWorkouts, isNot(contains(older)));
    expect(displayedWorkouts, isNot(contains(inProgress)));
    expect(displayedWorkouts, isNot(contains(missingTimestamp)));
  });

  test('HomeTimelineAssembler uses startedAt when completedAt is absent', () {
    final now = DateTime(2026, 6, 4, 12);
    final fallbackWorkout = Workout(
      id: 'fallback',
      name: 'Fallback',
      status: WorkoutStatus.completed,
      startedAt: now,
      completedAt: null,
      exercises: const [],
    );

    final timeline = HomeTimelineAssembler.build([
      _buildCompletedWorkout(
        id: 'older-a',
        completedAt: now.subtract(const Duration(hours: 1)),
      ),
      fallbackWorkout,
      _buildCompletedWorkout(
        id: 'older-b',
        completedAt: now.subtract(const Duration(hours: 2)),
      ),
      _buildCompletedWorkout(
        id: 'older-c',
        completedAt: now.subtract(const Duration(hours: 3)),
      ),
    ]);

    final displayedWorkouts = timeline.items
        .whereType<TimelineDayGroupItem>()
        .expand((item) => item.workouts)
        .toList();

    expect(displayedWorkouts.first, fallbackWorkout);
    expect(displayedWorkouts, hasLength(3));
  });

  test('HomeOverviewAssembler shows last week on Mondays', () {
    final monday = DateTime(2026, 6, 8, 9);
    final lastTuesday = _buildCompletedWorkout(
      id: 'last-tuesday',
      completedAt: DateTime(2026, 6, 2, 18),
    );
    final thisMonday = _buildCompletedWorkout(
      id: 'this-monday',
      completedAt: DateTime(2026, 6, 8, 8),
    );

    final overview = HomeOverviewAssembler.build([
      lastTuesday,
      thisMonday,
    ], now: monday);

    expect(overview.weekSummary.weekLabel, 'Last week');
    expect(overview.weekSummary.workoutCount, 1);
    expect(overview.weekSummary.days[1].hasWorkout, isTrue);
    expect(overview.weekSummary.days.any((day) => day.isToday), isFalse);
  });

  test(
    'HomeOverviewAssembler calculates duration trend from recent window',
    () {
      final now = DateTime(2026, 6, 20, 12);
      final recentA = _buildCompletedWorkout(
        id: 'recent-a',
        completedAt: DateTime(2026, 6, 19, 18),
        duration: const Duration(minutes: 75),
      );
      final recentB = _buildCompletedWorkout(
        id: 'recent-b',
        completedAt: DateTime(2026, 6, 12, 18),
        duration: const Duration(minutes: 45),
      );
      final baselineA = _buildCompletedWorkout(
        id: 'baseline-a',
        completedAt: DateTime(2026, 5, 20, 18),
        duration: const Duration(minutes: 30),
      );
      final baselineB = _buildCompletedWorkout(
        id: 'baseline-b',
        completedAt: DateTime(2026, 5, 12, 18),
        duration: const Duration(minutes: 30),
      );

      final overview = HomeOverviewAssembler.build([
        baselineA,
        recentA,
        baselineB,
        recentB,
      ], now: now);

      expect(overview.durationTrend.label, 'Duration Trend');
      expect(overview.durationTrend.value, '1');
      expect(overview.durationTrend.unit, 'hrs avg');
      expect(overview.durationTrend.direction, HomeTrendDirection.up);
      expect(overview.durationTrend.comparisonLabel, '+100% vs avg');
    },
  );
}
