import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/insights/exercise_trend_provider.dart';
import 'package:zenith/services/insights_service.dart';

Workout _buildExerciseWorkout({
  required DateTime startedAt,
  required double weight,
  required int reps,
}) {
  return Workout(
    id: 'workout-${startedAt.toIso8601String()}',
    name: 'Bench Session',
    status: WorkoutStatus.completed,
    startedAt: startedAt,
    completedAt: startedAt.add(const Duration(hours: 1)),
    exercises: [
      WorkoutExercise(
        id: 'exercise-${startedAt.toIso8601String()}',
        workoutId: 'workout-${startedAt.toIso8601String()}',
        exerciseSlug: 'bench-press',
        sets: [
          WorkoutSet(
            workoutExerciseId: 'exercise-${startedAt.toIso8601String()}',
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
  group('ExerciseTrendProvider', () {
    setUp(() {
      InsightsService.instance.reset();
    });

    tearDown(() {
      InsightsService.instance.reset();
    });

    test('uses month-to-date daily slots for 1M frequency trends', () async {
      InsightsService.instance.setWorkoutsProvider(
        () async => [
          _buildExerciseWorkout(
            startedAt: DateTime(2026, 4, 30, 9),
            weight: 75,
            reps: 5,
          ),
          _buildExerciseWorkout(
            startedAt: DateTime(2026, 5, 1, 9),
            weight: 80,
            reps: 5,
          ),
          _buildExerciseWorkout(
            startedAt: DateTime(2026, 5, 11, 9),
            weight: 82.5,
            reps: 6,
          ),
        ],
      );

      final data = await ExerciseTrendProvider(
        'bench-press',
        ExerciseTrendType.frequency,
      ).getData(timeframe: '1M', monthsBack: 1);

      expect(data, hasLength(11));
      expect(data.first.date, DateTime(2026, 5, 1));
      expect(data.last.date, DateTime(2026, 5, 11));
      expect(data.where((point) => point.value > 0), hasLength(2));
    });

    test('carries prior PRs forward for max weight trends', () async {
      InsightsService.instance.setWorkoutsProvider(
        () async => [
          _buildExerciseWorkout(
            startedAt: DateTime(2026, 4, 29, 9),
            weight: 100,
            reps: 1,
          ),
          _buildExerciseWorkout(
            startedAt: DateTime(2026, 5, 2, 9),
            weight: 95,
            reps: 3,
          ),
          _buildExerciseWorkout(
            startedAt: DateTime(2026, 5, 11, 9),
            weight: 105,
            reps: 1,
          ),
        ],
      );

      final data = await ExerciseTrendProvider(
        'bench-press',
        ExerciseTrendType.maxWeight,
      ).getData(timeframe: '1M', monthsBack: 1);

      expect(data.first.value, 100);
      expect(data.last.value, 105);
    });
  });
}
