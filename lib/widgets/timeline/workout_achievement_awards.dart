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
    case WorkoutAchievementType.highVolume:
      return Award(
        title: achievement.title,
        icon: Icons.local_fire_department,
        modelAsset: 'assets/achievements/achievement_cup.glb',
        thumbnailAsset: 'assets/achievements/achievement_cup.png',
        cameraTheta: 30,
        cameraPhi: 20,
        cameraRadius: 118,
        rotationSpeed: 22,
        color: context.appColors.warning,
      );
    case WorkoutAchievementType.longSession:
      return Award(
        title: achievement.title,
        icon: Icons.timer_outlined,
        modelAsset: 'assets/achievements/achievement_hourglass.glb',
        thumbnailAsset: 'assets/achievements/achievement_hourglass.png',
        cameraTheta: 25,
        cameraPhi: 20,
        cameraRadius: 118,
        rotationSpeed: 16,
        color: context.appScheme.primary,
      );
    case WorkoutAchievementType.heavy:
      return Award(
        title: achievement.title,
        icon: Icons.fitness_center,
        modelAsset: 'assets/achievements/achievement_dumbbell.glb',
        thumbnailAsset: 'assets/achievements/achievement_dumbbell.png',
        cameraTheta: 35,
        cameraPhi: 20,
        cameraRadius: 118,
        rotationSpeed: 18,
        color: context.appColors.success,
      );
    case WorkoutAchievementType.completed:
      return Award(
        title: achievement.title,
        icon: Icons.check_circle,
        modelAsset: 'assets/achievements/achievement_medal.glb',
        thumbnailAsset: 'assets/achievements/achievement_medal.png',
        cameraTheta: 20,
        cameraPhi: 20,
        cameraRadius: 118,
        rotationSpeed: 14,
        color: context.appScheme.primary,
      );
  }
}
