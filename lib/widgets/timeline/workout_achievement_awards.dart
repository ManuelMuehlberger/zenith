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
  final visual = _visualForAchievement(context, achievement);
  return Award(
    title: achievement.title,
    reason: achievement.reason,
    metrics: achievement.metrics,
    icon: visual.icon,
    modelAsset: visual.modelAsset,
    thumbnailAsset: visual.thumbnailAsset,
    compactThumbnailAsset: visual.compactThumbnailAsset,
    cameraTheta: visual.cameraTheta,
    cameraPhi: visual.cameraPhi,
    cameraRadius: visual.cameraRadius,
    rotationSpeed: visual.rotationSpeed,
    previewRenderScale: visual.previewRenderScale,
    color: visual.color,
  );
}

_AwardVisualSpec _visualForAchievement(
  BuildContext context,
  WorkoutAchievement achievement,
) {
  final ruleSpec = _ruleVisuals(context)[achievement.ruleId];
  if (ruleSpec != null) return ruleSpec;

  return switch (achievement.type) {
    WorkoutAchievementType.firstWorkout ||
    WorkoutAchievementType.workoutMilestone => _workoutMilestoneVisual(
      context,
      assetName: 'achievement_workout_1',
      color: context.appScheme.primary,
    ),
    WorkoutAchievementType.workoutStreak => _streakVisual(
      context,
      assetName: 'achievement_streak_3',
      icon: Icons.calendar_today,
      color: context.appColors.achievementStreak3,
      rotationSpeed: 16,
    ),
    WorkoutAchievementType.highVolume => _typedVisual(
      context,
      assetName: 'achievement_cup',
      icon: Icons.local_fire_department,
      color: context.appColors.warning,
      cameraTheta: 30,
      rotationSpeed: 22,
    ),
    WorkoutAchievementType.longSession => _typedVisual(
      context,
      assetName: 'achievement_hourglass',
      icon: Icons.timer_outlined,
      color: context.appScheme.primary,
      cameraTheta: 25,
      rotationSpeed: 16,
    ),
    WorkoutAchievementType.heavy => _typedVisual(
      context,
      assetName: 'achievement_dumbbell',
      icon: Icons.fitness_center,
      color: context.appColors.success,
      cameraTheta: 35,
      rotationSpeed: 18,
    ),
  };
}

Map<String, _AwardVisualSpec> _ruleVisuals(BuildContext context) {
  return {
    'first_workout': _workoutMilestoneVisual(
      context,
      assetName: 'achievement_workout_1',
      color: context.appScheme.primary,
    ),
    'tenth_workout': _workoutMilestoneVisual(
      context,
      assetName: 'achievement_workout_10',
      color: context.appColors.achievementWorkout10,
    ),
    'fiftieth_workout': _workoutMilestoneVisual(
      context,
      assetName: 'achievement_workout_50',
      color: context.appColors.achievementWorkout50,
    ),
    'hundredth_workout': _workoutMilestoneVisual(
      context,
      assetName: 'achievement_workout_100',
      color: context.appColors.achievementWorkout100,
    ),
    'two_hundredth_workout': _workoutMilestoneVisual(
      context,
      assetName: 'achievement_workout_200',
      color: context.appColors.achievementWorkout200,
    ),
    'three_day_streak': _streakVisual(
      context,
      assetName: 'achievement_streak_3',
      icon: Icons.calendar_today,
      color: context.appColors.achievementStreak3,
      rotationSpeed: 16,
    ),
    'seven_day_streak': _streakVisual(
      context,
      assetName: 'achievement_streak_7',
      icon: Icons.calendar_month,
      color: context.appColors.achievementStreak7,
      rotationSpeed: 12,
    ),
    'high_volume': _typedVisual(
      context,
      assetName: 'achievement_cup',
      icon: Icons.local_fire_department,
      color: context.appColors.warning,
      cameraTheta: 30,
      rotationSpeed: 22,
    ),
    'long_session': _typedVisual(
      context,
      assetName: 'achievement_hourglass',
      icon: Icons.timer_outlined,
      color: context.appScheme.primary,
      cameraTheta: 25,
      rotationSpeed: 16,
    ),
    'heavy': _typedVisual(
      context,
      assetName: 'achievement_dumbbell',
      icon: Icons.fitness_center,
      color: context.appColors.success,
      cameraTheta: 35,
      rotationSpeed: 18,
    ),
  };
}

_AwardVisualSpec _workoutMilestoneVisual(
  BuildContext context, {
  required String assetName,
  required Color color,
}) {
  return _typedVisual(
    context,
    assetName: assetName,
    icon: Icons.hexagon_outlined,
    color: color,
    cameraTheta: 18,
    rotationSpeed: 14,
  );
}

_AwardVisualSpec _streakVisual(
  BuildContext context, {
  required String assetName,
  required IconData icon,
  required Color color,
  required int rotationSpeed,
}) {
  return _typedVisual(
    context,
    assetName: assetName,
    icon: icon,
    color: color,
    cameraTheta: 24,
    rotationSpeed: rotationSpeed,
  );
}

_AwardVisualSpec _typedVisual(
  BuildContext context, {
  required String assetName,
  required IconData icon,
  required Color color,
  required double cameraTheta,
  required int rotationSpeed,
}) {
  return _AwardVisualSpec(
    icon: icon,
    modelAsset: 'assets/achievements/$assetName.glb',
    thumbnailAsset: 'assets/achievements/$assetName.png',
    compactThumbnailAsset: 'assets/achievements/${assetName}_compact.png',
    cameraTheta: cameraTheta,
    cameraPhi: 20,
    cameraRadius: 118,
    rotationSpeed: rotationSpeed,
    previewRenderScale: 0.66,
    color: color,
  );
}

class _AwardVisualSpec {
  final IconData icon;
  final String modelAsset;
  final String thumbnailAsset;
  final String compactThumbnailAsset;
  final double cameraTheta;
  final double cameraPhi;
  final double cameraRadius;
  final int rotationSpeed;
  final double previewRenderScale;
  final Color color;

  const _AwardVisualSpec({
    required this.icon,
    required this.modelAsset,
    required this.thumbnailAsset,
    required this.compactThumbnailAsset,
    required this.cameraTheta,
    required this.cameraPhi,
    required this.cameraRadius,
    required this.rotationSpeed,
    required this.previewRenderScale,
    required this.color,
  });
}
