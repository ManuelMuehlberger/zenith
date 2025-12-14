import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/insights_service.dart';

void main() {
  group('InsightsService Max Weight Logic', () {
    late InsightsService service;

    setUp(() {
      service = InsightsService();
      service.reset();
    });

    test('Max weight should be cumulative (PR progression)', () async {
      final exerciseSlug = 'bench_press';
      
      final workout1 = Workout(
        id: '1',
        name: 'W1',
        startedAt: DateTime(2023, 10, 1),
        completedAt: DateTime(2023, 10, 1).add(const Duration(hours: 1)),
        status: WorkoutStatus.completed,
        exercises: [
          WorkoutExercise(
            id: 'e1',
            workoutId: '1',
            exerciseSlug: exerciseSlug,
            sets: [
              WorkoutSet(
                workoutExerciseId: 'e1',
                setIndex: 0,
                targetWeight: 100,
                targetReps: 5,
                actualWeight: 100,
                actualReps: 5,
                isCompleted: true,
              ),
            ],
          ),
        ],
      );

      final workout2 = Workout(
        id: '2',
        name: 'W2',
        startedAt: DateTime(2023, 11, 1),
        completedAt: DateTime(2023, 11, 1).add(const Duration(hours: 1)),
        status: WorkoutStatus.completed,
        exercises: [
          WorkoutExercise(
            id: 'e2',
            workoutId: '2',
            exerciseSlug: exerciseSlug,
            sets: [
              WorkoutSet(
                workoutExerciseId: 'e2',
                setIndex: 0,
                targetWeight: 63,
                targetReps: 10,
                actualWeight: 63,
                actualReps: 10,
                isCompleted: true,
              ),
            ],
          ),
        ],
      );

      final workout3 = Workout(
        id: '3',
        name: 'W3',
        startedAt: DateTime(2023, 12, 1),
        completedAt: DateTime(2023, 12, 1).add(const Duration(hours: 1)),
        status: WorkoutStatus.completed,
        exercises: [
          WorkoutExercise(
            id: 'e3',
            workoutId: '3',
            exerciseSlug: exerciseSlug,
            sets: [
              WorkoutSet(
                workoutExerciseId: 'e3',
                setIndex: 0,
                targetWeight: 105,
                targetReps: 3,
                actualWeight: 105,
                actualReps: 3,
                isCompleted: true,
              ),
            ],
          ),
        ],
      );

      // Adjust dates to be relative to now to ensure they fall into the "last 3 months" window
      final now = DateTime.now();
      // We want 3 months back.
      // Month 1: 2 months ago
      // Month 2: 1 month ago
      // Month 3: This month
      
      final dateMonth1 = DateTime(now.year, now.month - 2, 15);
      final dateMonth2 = DateTime(now.year, now.month - 1, 15);
      final dateMonth3 = DateTime(now.year, now.month, 15);
      
      final w1 = workout1.copyWith(startedAt: dateMonth1, completedAt: dateMonth1.add(const Duration(hours: 1)));
      final w2 = workout2.copyWith(startedAt: dateMonth2, completedAt: dateMonth2.add(const Duration(hours: 1)));
      final w3 = workout3.copyWith(startedAt: dateMonth3, completedAt: dateMonth3.add(const Duration(hours: 1)));
      
      service.setWorkoutsProvider(() async => [w1, w2, w3]);
      
      final insights = await service.getExerciseInsights(
        exerciseName: exerciseSlug,
        monthsBack: 3,
        grouping: InsightsGrouping.month,
      );
      
      final maxWeights = insights.monthlyMaxWeight;
      
      // Expect 3 data points
      expect(maxWeights.length, 3);
      
      // Month 1: 100kg
      expect(maxWeights[0].value, 100.0, reason: 'Month 1 max should be 100');
      
      // Month 2: Should be 100kg (cumulative), even though lifted 63kg
      expect(maxWeights[1].value, 100.0, reason: 'Month 2 max should be 100 (cumulative)');
      
      // Month 3: 105kg (new PR)
      expect(maxWeights[2].value, 105.0, reason: 'Month 3 max should be 105');
    });
  });
}
