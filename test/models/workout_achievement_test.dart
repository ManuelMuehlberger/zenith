import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_achievement.dart';

void main() {
  group('WorkoutAchievement', () {
    test('serializes and restores persisted award snapshots', () {
      final earnedAt = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final achievement = WorkoutAchievement(
        id: 'achievement-1',
        workoutId: 'workout-1',
        ruleId: 'high_volume',
        type: WorkoutAchievementType.highVolume,
        title: 'High Volume',
        reason: 'Completed 24 sets.',
        earnedAt: earnedAt,
        metrics: const {
          'totalSets': 24,
          'totalWeight': 12000.5,
          'totalSetsPercentileLast90Days': 80.0,
        },
      );

      final map = achievement.toMap();

      expect(map['type'], 'highVolume');
      expect(jsonDecode(map['metricsJson'] as String), {
        'totalSets': 24,
        'totalWeight': 12000.5,
        'totalSetsPercentileLast90Days': 80.0,
      });

      final restored = WorkoutAchievement.fromMap(map);

      expect(restored.id, achievement.id);
      expect(restored.workoutId, achievement.workoutId);
      expect(restored.ruleId, achievement.ruleId);
      expect(restored.type, WorkoutAchievementType.highVolume);
      expect(restored.title, achievement.title);
      expect(restored.reason, achievement.reason);
      expect(restored.earnedAt, earnedAt);
      expect(restored.metrics['totalSets'], 24);
    });
  });
}
