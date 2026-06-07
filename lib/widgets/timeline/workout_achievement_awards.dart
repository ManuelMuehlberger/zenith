import 'package:flutter/material.dart';

import '../../models/workout_achievement.dart';
import '../../theme/app_theme.dart';
import 'award_stack.dart';

List<Award> buildWorkoutAchievementAwards(
  BuildContext context,
  Iterable<WorkoutAchievement> achievements,
) {
  return achievements
      .map((achievement) => _awardForAchievement(context, achievement))
      .toList(growable: false);
}

Award _awardForAchievement(
  BuildContext context,
  WorkoutAchievement achievement,
) {
  switch (achievement.type) {
    case WorkoutAchievementType.firstWorkout:
      return _milestoneAward(context, achievement);
    case WorkoutAchievementType.workoutMilestone:
      return _milestoneAward(context, achievement);
    case WorkoutAchievementType.workoutStreak:
      return _streakAward(context, achievement);
    case WorkoutAchievementType.highVolume:
      return Award(
        title: achievement.title,
        reason: achievement.reason,
        metrics: achievement.metrics,
        icon: Icons.local_fire_department,
        modelAsset: 'assets/achievements/achievement_cup.glb',
        thumbnailAsset: 'assets/achievements/achievement_cup.png',
        compactThumbnailAsset:
            'assets/achievements/achievement_cup_compact.png',
        cameraTheta: 30,
        cameraPhi: 20,
        cameraRadius: 118,
        rotationSpeed: 22,
        color: context.appColors.warning,
      );
    case WorkoutAchievementType.longSession:
      return Award(
        title: achievement.title,
        reason: achievement.reason,
        metrics: achievement.metrics,
        icon: Icons.timer_outlined,
        modelAsset: 'assets/achievements/achievement_hourglass.glb',
        thumbnailAsset: 'assets/achievements/achievement_hourglass.png',
        compactThumbnailAsset:
            'assets/achievements/achievement_hourglass_compact.png',
        cameraTheta: 25,
        cameraPhi: 20,
        cameraRadius: 118,
        rotationSpeed: 16,
        color: context.appScheme.primary,
      );
    case WorkoutAchievementType.heavy:
      return Award(
        title: achievement.title,
        reason: achievement.reason,
        metrics: achievement.metrics,
        icon: Icons.fitness_center,
        modelAsset: 'assets/achievements/achievement_dumbbell.glb',
        thumbnailAsset: 'assets/achievements/achievement_dumbbell.png',
        compactThumbnailAsset:
            'assets/achievements/achievement_dumbbell_compact.png',
        cameraTheta: 35,
        cameraPhi: 20,
        cameraRadius: 118,
        rotationSpeed: 18,
        color: context.appColors.success,
      );
  }
}

Award _milestoneAward(BuildContext context, WorkoutAchievement achievement) {
  final assetName = switch (achievement.ruleId) {
    'tenth_workout' => 'achievement_workout_10',
    'fiftieth_workout' => 'achievement_workout_50',
    'hundredth_workout' => 'achievement_workout_100',
    'two_hundredth_workout' => 'achievement_workout_200',
    _ => 'achievement_workout_1',
  };
  final color = switch (achievement.ruleId) {
    'tenth_workout' => context.appColors.achievementWorkout10,
    'fiftieth_workout' => context.appColors.achievementWorkout50,
    'hundredth_workout' => context.appColors.achievementWorkout100,
    'two_hundredth_workout' => context.appColors.achievementWorkout200,
    _ => context.appScheme.primary,
  };

  return Award(
    title: achievement.title,
    reason: achievement.reason,
    metrics: achievement.metrics,
    icon: Icons.hexagon_outlined,
    modelAsset: 'assets/achievements/$assetName.glb',
    thumbnailAsset: 'assets/achievements/$assetName.png',
    compactThumbnailAsset: 'assets/achievements/${assetName}_compact.png',
    cameraTheta: 18,
    cameraPhi: 20,
    cameraRadius: 118,
    rotationSpeed: 14,
    color: color,
  );
}

Award _streakAward(BuildContext context, WorkoutAchievement achievement) {
  final isSevenDay = achievement.ruleId == 'seven_day_streak';
  final assetName = isSevenDay
      ? 'achievement_streak_7'
      : 'achievement_streak_3';

  return Award(
    title: achievement.title,
    reason: achievement.reason,
    metrics: achievement.metrics,
    icon: isSevenDay ? Icons.calendar_month : Icons.calendar_today,
    modelAsset: 'assets/achievements/$assetName.glb',
    thumbnailAsset: 'assets/achievements/$assetName.png',
    compactThumbnailAsset: 'assets/achievements/${assetName}_compact.png',
    cameraTheta: 24,
    cameraPhi: 20,
    cameraRadius: 118,
    rotationSpeed: isSevenDay ? 12 : 16,
    color: isSevenDay
        ? context.appColors.achievementStreak7
        : context.appColors.achievementStreak3,
  );
}
