import 'package:flutter/material.dart';
import '../models/workout_exercise.dart';
import '../utils/workout_metrics.dart';
import '../constants/app_constants.dart';

class WorkoutMetricsWidget extends StatelessWidget {
  final List<WorkoutExercise> exercises;

  const WorkoutMetricsWidget({
    super.key,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    final exerciseCount = WorkoutMetrics.calculateExerciseCount(exercises);
    final totalSets = WorkoutMetrics.calculateTotalSets(exercises);
    final duration = WorkoutMetrics.getFormattedDuration(exercises);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 5),
      child: Row(
        children: [
          // Exercise count with icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center_outlined,
                  size: 14,
                  color: AppConstants.TEXT_SECONDARY_COLOR,
                ),
                const SizedBox(width: 6),
                Text(
                  '$exerciseCount',
                  style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.TEXT_PRIMARY_COLOR,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Sets count with icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 14,
                  color: AppConstants.TEXT_SECONDARY_COLOR,
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalSets',
                  style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.TEXT_PRIMARY_COLOR,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Duration estimate
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.ACCENT_COLOR.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: AppConstants.ACCENT_COLOR,
                ),
                const SizedBox(width: 6),
                Text(
                  duration,
                  style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.ACCENT_COLOR,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
