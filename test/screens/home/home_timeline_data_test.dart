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
}) {
  return Workout(
    id: id,
    name: 'Workout $id',
    status: WorkoutStatus.completed,
    startedAt: completedAt.subtract(const Duration(hours: 1)),
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
  test(
    'HomeTimelineAssembler groups recent workouts and appends metrics/footer',
    () {
      final workouts = [
        _buildCompletedWorkout(
          id: 'recent-a',
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        _buildCompletedWorkout(
          id: 'recent-b',
          completedAt: DateTime.now().subtract(
            const Duration(days: 1, hours: 2),
          ),
          weight: 120,
        ),
        _buildCompletedWorkout(
          id: 'archive-a',
          completedAt: DateTime.now().subtract(const Duration(days: 45)),
        ),
      ];

      final timeline = HomeTimelineAssembler.build(workouts);

      expect(timeline.items.whereType<TimelineDayGroupItem>(), hasLength(1));
      expect(timeline.items.whereType<TimelineMetricsItem>(), hasLength(1));
      expect(timeline.items.whereType<TimelineFooterItem>(), hasLength(1));
      expect(timeline.archiveGroups, isNotEmpty);
    },
  );
}
