import 'package:flutter/material.dart';
import '../models/workout_exercise.dart';
import '../theme/app_theme.dart';
import '../utils/workout_metrics.dart';

class WorkoutMetricsWidget extends StatelessWidget {
  final List<WorkoutExercise> exercises;

  const WorkoutMetricsWidget({super.key, required this.exercises});

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    final appColors = context.appColors;
    final appScheme = context.appScheme;
    final metricValueStyle = context.appText.labelMedium!.copyWith(
      fontWeight: FontWeight.w600,
      color: appColors.textPrimary,
    );

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
              color: appColors.textTertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center_outlined,
                  size: 14,
                  color: appColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text('$exerciseCount', style: metricValueStyle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Sets count with icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: appColors.textTertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 14,
                  color: appColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text('$totalSets', style: metricValueStyle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Duration estimate
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: appScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: appScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  duration,
                  style: metricValueStyle.copyWith(color: appScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
