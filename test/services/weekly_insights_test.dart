import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/insights_service.dart';

void main() {
  group('InsightsService - Weekly Insights Tests', () {
    late InsightsService insightsService;
    late List<Workout> mockWorkouts;

    // Helper to create a workout
    Workout createWorkout(String id, DateTime startedAt, int durationMinutes, int sets, double weight, int reps) {
      return Workout(
        id: id,
        name: 'Test Workout',
        status: WorkoutStatus.completed,
        startedAt: startedAt,
        completedAt: startedAt.add(Duration(minutes: durationMinutes)),
        exercises: [
          WorkoutExercise(
            id: 'ex_$id',
            workoutId: id,
            exerciseSlug: 'test-exercise',
            sets: List.generate(sets, (i) => WorkoutSet(
              id: 'set_${id}_$i',
              workoutExerciseId: 'ex_$id',
              setIndex: i,
              actualReps: reps,
              actualWeight: weight,
              isCompleted: true,
            )),
          ),
        ],
      );
    }

    setUp(() {
      // Reset singleton and clear cache before each test
      InsightsService.instance.reset();
      SharedPreferences.setMockInitialValues({});
      insightsService = InsightsService.instance;

      // Create deterministic test data with fixed dates
      final baseDate = DateTime(2023, 10, 19); // A Thursday

      // This week (Oct 16 - Oct 22)
      final workout1 = createWorkout('w1', baseDate, 60, 10, 50, 10); // 10 sets
      final workout2 = createWorkout('w2', baseDate.subtract(const Duration(days: 2)), 90, 15, 60, 8); // 15 sets

      // Last week (Oct 9 - Oct 15)
      final workout3 = createWorkout('w3', baseDate.subtract(const Duration(days: 7)), 75, 12, 55, 10); // 12 sets

      // Two weeks ago (Oct 2 - Oct 8)
      final workout4 = createWorkout('w4', baseDate.subtract(const Duration(days: 14)), 45, 8, 40, 12); // 8 sets
      
      // Four weeks ago (Sep 18 - Sep 24)
      final workout5 = createWorkout('w5', baseDate.subtract(const Duration(days: 28)), 80, 14, 65, 8); // 14 sets

      mockWorkouts = [workout1, workout2, workout3, workout4, workout5];
    });

    test('should calculate weekly insights correctly for default 6 months', () async {
      insightsService.setWorkoutsProvider(() async => mockWorkouts);
      
      // Default is 6 months, which uses weekly grouping with 6-8 slots
      final insights = await insightsService.getWeeklyInsights(monthsBack: 6);
      
      expect(insights, isNotNull);
      
      // Check averages
      // 5 workouts over 4 weeks with data
      expect(insights.averageWorkoutsPerWeek, 5 / 4); 
      // Total duration: 60+90+75+45+80 = 350 mins. 350/5 workouts = 70
      expect(insights.averageDuration, 70.0); 
      // Total sets: 10+15+12+8+14 = 59 sets. 59/5 workouts = 11.8
      expect(insights.averageVolume, 11.8);

      // Check weekly data points (expecting 6-8 slots for 6 months)
      expect(insights.weeklyWorkoutCounts.length, greaterThanOrEqualTo(6));
      expect(insights.weeklyDurations.length, greaterThanOrEqualTo(6));
      expect(insights.weeklyVolumes.length, greaterThanOrEqualTo(6));

      // Check data for "This Week" (the last data point)
      final thisWeekCounts = insights.weeklyWorkoutCounts.last;
      expect(thisWeekCounts.maxValue, 2); // workout1 and workout2

      final thisWeekDurations = insights.weeklyDurations.last;
      expect(thisWeekDurations.minValue, 60); // workout1
      expect(thisWeekDurations.maxValue, 90); // workout2

      final thisWeekVolumes = insights.weeklyVolumes.last;
      expect(thisWeekVolumes.minValue, 10); // workout1
      expect(thisWeekVolumes.maxValue, 15); // workout2
    });

    test('should use monthly grouping for longer timeframes (1 year)', () async {
      insightsService.setWorkoutsProvider(() async => mockWorkouts);
      
      final insights = await insightsService.getWeeklyInsights(monthsBack: 12);
      
      // For 1 year, it should group by month and show 12 slots (since we changed logic to show all months)
      expect(insights.weeklyWorkoutCounts.length, 12);
      expect(insights.weeklyDurations.length, 12);
      expect(insights.weeklyVolumes.length, 12);

      // All workouts are in Oct and Sep 2023.
      // The last slot is "This Month" (October)
      final thisMonthCounts = insights.weeklyWorkoutCounts.last;
      expect(thisMonthCounts.maxValue, 4); // w1, w2, w3, w4

      // The second to last slot is "Last Month" (September)
      final lastMonthCounts = insights.weeklyWorkoutCounts[insights.weeklyWorkoutCounts.length - 2];
      expect(lastMonthCounts.maxValue, 1); // w5
    });

    test('should return empty insights for no workouts', () async {
      insightsService.setWorkoutsProvider(() async => []);
      
      final insights = await insightsService.getWeeklyInsights();
      
      expect(insights.averageWorkoutsPerWeek, 0);
      expect(insights.averageDuration, 0);
      expect(insights.averageVolume, 0);
      expect(insights.weeklyWorkoutCounts, isEmpty);
      expect(insights.weeklyDurations, isEmpty);
      expect(insights.weeklyVolumes, isEmpty);
    });

    test('should handle workouts with no completion time', () async {
      final workoutWithNoCompletion = Workout(
        id: 'no-complete',
        name: 'Test',
        status: WorkoutStatus.completed,
        startedAt: DateTime(2023, 10, 18),
        completedAt: null, // No completion time
        exercises: [
          WorkoutExercise(id: 'ex', workoutId: 'no-complete', exerciseSlug: 'slug', sets: [])
        ],
      );

      insightsService.setWorkoutsProvider(() async => [workoutWithNoCompletion]);
      
      final insights = await insightsService.getWeeklyInsights();
      
      // Duration should be 0
      expect(insights.averageDuration, 0);
      expect(insights.weeklyDurations.last.minValue, 0);
      expect(insights.weeklyDurations.last.maxValue, 0);
    });

    group('WeeklyInsights Model Serialization', () {
      test('should convert to and from map correctly', () {
        final insights = WeeklyInsights(
          weeklyWorkoutCounts: [WeeklyDataPoint(weekStart: DateTime(2023, 1, 1), minValue: 0, maxValue: 5)],
          weeklyDurations: [WeeklyDataPoint(weekStart: DateTime(2023, 1, 1), minValue: 30, maxValue: 90)],
          weeklyVolumes: [WeeklyDataPoint(weekStart: DateTime(2023, 1, 1), minValue: 10, maxValue: 20)],
          averageWorkoutsPerWeek: 2.5,
          averageDuration: 60.5,
          averageVolume: 15.2,
          lastUpdated: DateTime(2023, 1, 1),
        );

        final map = insights.toMap();
        final restored = WeeklyInsights.fromMap(map);

        expect(restored.averageWorkoutsPerWeek, insights.averageWorkoutsPerWeek);
        expect(restored.averageDuration, insights.averageDuration);
        expect(restored.averageVolume, insights.averageVolume);
        expect(restored.lastUpdated, insights.lastUpdated);
        expect(restored.weeklyWorkoutCounts.first.maxValue, 5);
        expect(restored.weeklyDurations.first.minValue, 30);
        expect(restored.weeklyVolumes.first.maxValue, 20);
      });

      test('should handle malformed map data gracefully', () {
        final malformedMap = <String, dynamic>{
          'weeklyWorkoutCounts': 'not-a-list',
          'averageWorkoutsPerWeek': 'invalid-double',
          'lastUpdated': null,
        };

        final restored = WeeklyInsights.fromMap(malformedMap);

        expect(restored.weeklyWorkoutCounts, isEmpty);
        expect(restored.averageWorkoutsPerWeek, 0.0);
        expect(restored.lastUpdated, isNotNull); // Should default to a value
      });
    });
  });
}
