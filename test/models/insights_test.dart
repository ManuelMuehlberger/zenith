import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/insights.dart';

void main() {
  group('Insights models', () {
    test('InsightsGrouping exposes the expected values', () {
      expect(InsightsGrouping.values, [
        InsightsGrouping.day,
        InsightsGrouping.week,
        InsightsGrouping.month,
      ]);
    });

    test('WorkoutInsights.fromMap accepts legacy monthly trend keys', () {
      final mayStart = DateTime(2026, 5, 1).millisecondsSinceEpoch;

      final insights = WorkoutInsights.fromMap({
        'totalWorkouts': '3',
        'totalHours': '1.5',
        'totalWeight': 250,
        'monthlyWorkouts': [
          <String, dynamic>{'date': mayStart, 'value': 2},
        ],
        'monthlyHours': [
          <String, dynamic>{'date': mayStart, 'value': 1.5},
        ],
        'monthlyWeight': [
          <String, dynamic>{'date': mayStart, 'value': 250},
        ],
        'averageWorkoutDuration': '0.5',
        'averageWeightPerWorkout': 83.33,
        'lastUpdated': DateTime(2026, 5, 3).millisecondsSinceEpoch,
      });

      expect(insights.totalWorkouts, 3);
      expect(insights.totalHours, 1.5);
      expect(insights.totalWeight, 250);
      expect(insights.trendWorkouts.single.value, 2);
      expect(insights.trendHours.single.date.millisecondsSinceEpoch, mayStart);
      expect(insights.trendWeight.single.value, 250);
      expect(insights.averageWorkoutDuration, 0.5);
    });

    test('ExerciseInsights.empty creates six zeroed monthly points', () {
      final insights = ExerciseInsights.empty('bench-press');

      expect(insights.exerciseName, 'bench-press');
      expect(insights.totalSessions, 0);
      expect(insights.monthlyVolume, hasLength(6));
      expect(insights.monthlyVolume.every((point) => point.value == 0), isTrue);
      expect(insights.monthlyMaxWeight, hasLength(6));
      expect(insights.monthlyFrequency, hasLength(6));
    });
  });
}
