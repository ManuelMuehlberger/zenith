import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/insights/workout_trend_provider.dart';
import 'package:zenith/services/insights_service.dart';

Workout _buildWorkout({
  required String id,
  required DateTime startedAt,
  required int reps,
  required double weight,
}) {
  return Workout(
    id: id,
    name: 'Push Day',
    status: WorkoutStatus.completed,
    startedAt: startedAt,
    completedAt: startedAt.add(const Duration(minutes: 50)),
    exercises: [
      WorkoutExercise(
        id: 'exercise-$id',
        workoutId: id,
        exerciseSlug: 'bench-press',
        sets: [
          WorkoutSet(
            workoutExerciseId: 'exercise-$id',
            setIndex: 0,
            actualReps: reps,
            actualWeight: weight,
            isCompleted: true,
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('WorkoutTrendProvider', () {
    setUp(() {
      InsightsService.instance.reset();
    });

    tearDown(() {
      InsightsService.instance.reset();
    });

    test('uses month-to-date daily slots for 1M count trends', () async {
      InsightsService.instance.setWorkoutsProvider(
        () async => [
          _buildWorkout(
            id: 'w-april',
            startedAt: DateTime(2026, 4, 30, 9),
            reps: 5,
            weight: 75,
          ),
          _buildWorkout(
            id: 'w-may-1',
            startedAt: DateTime(2026, 5, 1, 9),
            reps: 8,
            weight: 80,
          ),
          _buildWorkout(
            id: 'w-may-11',
            startedAt: DateTime(2026, 5, 11, 9),
            reps: 6,
            weight: 82.5,
          ),
        ],
      );

      final data = await WorkoutTrendProvider(
        WorkoutTrendType.count,
      ).getData(timeframe: '1M', monthsBack: 1);

      expect(data, hasLength(11));
      expect(data.first.date, DateTime(2026, 5, 1));
      expect(data.last.date, DateTime(2026, 5, 11));
      expect(data.first.value, 1);
      expect(data.last.value, 1);
    });

    test('aggregates workout volume per slot', () async {
      InsightsService.instance.setWorkoutsProvider(
        () async => [
          _buildWorkout(
            id: 'w-may-5',
            startedAt: DateTime(2026, 5, 5, 9),
            reps: 5,
            weight: 100,
          ),
        ],
      );

      final data = await WorkoutTrendProvider(
        WorkoutTrendType.volume,
      ).getData(timeframe: '1M', monthsBack: 1);

      final may5Point = data.firstWhere(
        (point) => point.date == DateTime(2026, 5, 5),
      );
      expect(may5Point.value, 500);
      expect(may5Point.count, 1);
    });
  });
}
