enum WorkoutAchievementType { highVolume, longSession, heavy, completed }

class WorkoutAchievement {
  final WorkoutAchievementType type;
  final String title;

  const WorkoutAchievement({required this.type, required this.title});
}
