import 'package:flutter/foundation.dart';

// policy: allow-public-api core model for achievement system.
enum WorkoutAchievementType { highVolume, longSession, heavy, completed }

@immutable
// policy: allow-public-api data model for tracking workout milestones.
class WorkoutAchievement {
  final WorkoutAchievementType type;
  final String title;

  const WorkoutAchievement({required this.type, required this.title});
}
