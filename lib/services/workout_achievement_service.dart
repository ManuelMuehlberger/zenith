import '../models/workout.dart';
import '../models/workout_achievement.dart';

class WorkoutAchievementService {
  const WorkoutAchievementService._();

  static List<WorkoutAchievement> resolveForWorkout(Workout workout) {
    final duration = _durationOf(workout);
    final achievements = <WorkoutAchievement>[];

    if (workout.totalSets >= 20) {
      achievements.add(
        const WorkoutAchievement(
          type: WorkoutAchievementType.highVolume,
          title: 'High Volume',
        ),
      );
    }

    if (duration.inMinutes >= 60) {
      achievements.add(
        const WorkoutAchievement(
          type: WorkoutAchievementType.longSession,
          title: 'Long Session',
        ),
      );
    }

    if (workout.totalWeight >= 10000) {
      achievements.add(
        const WorkoutAchievement(
          type: WorkoutAchievementType.heavy,
          title: 'Heavy',
        ),
      );
    }

    if (achievements.isEmpty) {
      achievements.add(
        const WorkoutAchievement(
          type: WorkoutAchievementType.completed,
          title: 'Completed',
        ),
      );
    }

    return List<WorkoutAchievement>.unmodifiable(achievements);
  }

  static Duration _durationOf(Workout workout) {
    final started = workout.startedAt;
    final completed = workout.completedAt;
    if (started == null || completed == null) {
      return Duration.zero;
    }
    final duration = completed.difference(started);
    if (duration.isNegative) {
      return Duration.zero;
    }
    return duration;
  }
}
