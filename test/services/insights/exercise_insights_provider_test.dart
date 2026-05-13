import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/insights/exercise_insights_provider.dart';
import 'package:zenith/services/insights_service.dart';

Workout _buildExerciseWorkout({
  required DateTime startedAt,
  required double weight,
  required int reps,
  String slug = 'bench-press',
}) {
  return Workout(
    id: 'workout-${startedAt.toIso8601String()}-$slug',
    name: 'Session',
    status: WorkoutStatus.completed,
    startedAt: startedAt,
    completedAt: startedAt.add(const Duration(hours: 1)),
    exercises: [
      WorkoutExercise(
        id: 'exercise-${startedAt.toIso8601String()}-$slug',
        workoutId: 'workout-${startedAt.toIso8601String()}-$slug',
        exerciseSlug: slug,
        sets: [
          WorkoutSet(
            workoutExerciseId: 'exercise-${startedAt.toIso8601String()}-$slug',
            setIndex: 0,
            actualWeight: weight,
            actualReps: reps,
            isCompleted: true,
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('ExerciseInsightsProvider', () {
    setUp(() {
      InsightsService.instance.reset();
    });

    tearDown(() {
      InsightsService.instance.reset();
    });

    test('returns an empty snapshot for blank exercise names', () async {
      InsightsService.instance.setWorkoutsProvider(
        () async => [
          _buildExerciseWorkout(
            startedAt: DateTime(2026, 5, 1, 9),
            weight: 80,
            reps: 5,
          ),
        ],
      );

      final insights = await ExerciseInsightsProvider().getData(
        exerciseName: '   ',
        monthsBack: 1,
      );

      expect(insights.totalSessions, 0);
      expect(insights.monthlyVolume, hasLength(6));
    });

    test('aggregates recent totals and carries max weight history', () async {
      InsightsService.instance.setWorkoutsProvider(
        () async => [
          _buildExerciseWorkout(
            startedAt: DateTime(2026, 4, 28, 9),
            weight: 90,
            reps: 3,
          ),
          _buildExerciseWorkout(
            startedAt: DateTime(2026, 5, 2, 9),
            weight: 95,
            reps: 4,
          ),
          _buildExerciseWorkout(
            startedAt: DateTime(2026, 5, 11, 9),
            weight: 100,
            reps: 5,
          ),
        ],
      );

      final insights = await ExerciseInsightsProvider().getData(
        exerciseName: 'bench-press',
        monthsBack: 1,
      );

      expect(insights.totalSessions, 2);
      expect(insights.totalSets, 2);
      expect(insights.totalReps, 9);
      expect(insights.maxWeight, 100);
      expect(insights.monthlyMaxWeight.last.value, 100);
      expect(
        insights.monthlyFrequency.where((point) => point.value > 0),
        isNotEmpty,
      );
    });
  });
}
