import '../models/workout_exercise.dart';
import '../constants/app_constants.dart';

/// Utility class for calculating workout metrics
class WorkoutMetrics {
  /// Calculate the total number of exercises in a workout
  static int calculateExerciseCount(List<WorkoutExercise> exercises) {
    return exercises.length;
  }

  /// Calculate the total number of sets across all exercises
  static int calculateTotalSets(List<WorkoutExercise> exercises) {
    return exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
  }

  /// Get equipment setup time in minutes based on equipment type
  static int _getEquipmentSetupTime(String equipment) {
    final equipmentType = EquipmentType.fromString(equipment);
    switch (equipmentType) {
      case EquipmentType.barbell:
        return 3; // Barbell needs 3 minutes setup
      case EquipmentType.dumbbell:
        return 2; // Dumbbell needs 2 minutes setup
      case EquipmentType.cable:
        return 2; // Cable needs 2 minutes setup
      case EquipmentType.machine:
        return 1; // Machine needs 1 minute setup
      case EquipmentType.none:
        return 1; // Bodyweight/None needs 1 minute setup
    }
  }

  /// Estimate workout duration in minutes with precise equipment-based calculations
  /// Formula: 
  /// - Base time per set: 3 minutes
  /// - Equipment setup time: varies by type (Barbell: 3min, Dumbbell/Cable: 2min, Machine/None: 1min)
  /// - High rep bonus: +1 minute if reps > 10
  /// - Heavy weight bonus: +1 minute if weight > 80kg
  /// - Transition time: +1 minute between exercises for walking/moving
  static int estimateWorkoutDuration(List<WorkoutExercise> exercises) {
    if (exercises.isEmpty) return 0;
    
    int totalDuration = 0;

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      
      // Equipment setup time per exercise
      final setupTime = _getEquipmentSetupTime(exercise.exerciseDetail?.equipment ?? '');
      totalDuration += setupTime;

      // Calculate time for each set
      for (final set in exercise.sets) {
        int setTime = 3; // Base time per set

        // High rep bonus: +1 minute if reps > 10
        if ((set.targetReps ?? 0) >= 10) {
          setTime += 1;
        }

        // Heavy weight bonus: +1 minute if weight > 60kg
        if ((set.targetWeight ?? 0) > 60) {
          setTime += 1;
        }

        totalDuration += setTime;
      }

      // Add transition time between exercises (except for the last exercise)
      if (i < exercises.length - 1) {
        totalDuration += 1; // 1 minute to walk/move between exercises
      }
    }

    return totalDuration;
  }

  /// Get a formatted duration string (e.g., "~15m")
  static String getFormattedDuration(List<WorkoutExercise> exercises) {
    final duration = estimateWorkoutDuration(exercises);
    return '~${duration}m';
  }
}
