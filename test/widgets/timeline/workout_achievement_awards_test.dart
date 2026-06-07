import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_achievement.dart';
import 'package:zenith/widgets/timeline/award_stack.dart';
import 'package:zenith/widgets/timeline/workout_achievement_awards.dart';

void main() {
  testWidgets('maps persisted achievement types to the right award visuals', (
    tester,
  ) async {
    late final List<Award> awards;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            awards = buildWorkoutAchievementAwards(context, [
              WorkoutAchievement(
                workoutId: 'workout-1',
                ruleId: 'first_workout',
                type: WorkoutAchievementType.firstWorkout,
                title: 'First Workout',
                reason: 'First workout',
                earnedAt: DateTime(2026, 1, 1),
              ),
              WorkoutAchievement(
                workoutId: 'workout-1',
                ruleId: 'high_volume',
                type: WorkoutAchievementType.highVolume,
                title: 'High Volume',
                reason: 'High volume',
                earnedAt: DateTime(2026, 1, 1),
              ),
            ]);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(awards, hasLength(2));
    expect(awards.first.title, 'First Workout');
    expect(awards.first.icon, Icons.check_circle);
    expect(
      awards.first.compactThumbnailAsset,
      'assets/achievements/achievement_medal_compact.png',
    );
    expect(awards.last.title, 'High Volume');
    expect(awards.last.icon, Icons.local_fire_department);
    expect(
      awards.last.compactThumbnailAsset,
      'assets/achievements/achievement_cup_compact.png',
    );
  });
}
