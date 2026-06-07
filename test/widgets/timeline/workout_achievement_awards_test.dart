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
                ruleId: 'hundredth_workout',
                type: WorkoutAchievementType.workoutMilestone,
                title: '100 Workouts',
                reason: 'Workout 100',
                earnedAt: DateTime(2026, 1, 1),
              ),
              WorkoutAchievement(
                workoutId: 'workout-1',
                ruleId: 'seven_day_streak',
                type: WorkoutAchievementType.workoutStreak,
                title: '7-Day Streak',
                reason: 'Seven days',
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

    expect(awards, hasLength(4));
    expect(awards.first.title, 'First Workout');
    expect(awards.first.icon, Icons.hexagon_outlined);
    expect(
      awards.first.compactThumbnailAsset,
      'assets/achievements/achievement_workout_1_compact.png',
    );
    expect(awards[1].title, '100 Workouts');
    expect(awards[1].icon, Icons.hexagon_outlined);
    expect(
      awards[1].compactThumbnailAsset,
      'assets/achievements/achievement_workout_100_compact.png',
    );
    expect(awards[1].color, isNotNull);
    expect(awards[2].title, '7-Day Streak');
    expect(awards[2].icon, Icons.calendar_month);
    expect(
      awards[2].compactThumbnailAsset,
      'assets/achievements/achievement_streak_7_compact.png',
    );
    expect(awards[2].color, isNotNull);
    expect(awards.last.title, 'High Volume');
    expect(awards.last.icon, Icons.local_fire_department);
    expect(
      awards.last.compactThumbnailAsset,
      'assets/achievements/achievement_cup_compact.png',
    );
  });
}
