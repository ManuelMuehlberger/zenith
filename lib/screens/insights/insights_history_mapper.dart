import '../../models/workout.dart';
import '../../services/workout_service.dart';
import 'insights_view_data.dart';

// policy: no-test-needed thin adapter around WorkoutService lookups covered by screen flows.
class InsightsHistoryMapper {
  static List<WorkoutDisplayItem> buildDisplayItems(List<Workout> workouts) {
    return workouts.map((workout) {
      Workout? details;
      try {
        if (workout.templateId != null) {
          details = WorkoutService.instance.getWorkoutById(workout.templateId!);
        }
      } catch (_) {
        details = null;
      }

      return WorkoutDisplayItem(workout: workout, workoutDetails: details);
    }).toList();
  }
}
