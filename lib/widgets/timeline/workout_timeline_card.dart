import 'package:flutter/material.dart';

import '../../models/workout.dart';
import '../../theme/app_theme.dart';

class WorkoutTimelineCard extends StatelessWidget {
  final Workout workout;
  final String primaryMetricsLabel;

  /// Used for workouts shown inside an expanded month. Makes the card a bit
  /// more compact to communicate hierarchy.
  final bool compact;

  const WorkoutTimelineCard({
    super.key,
    required this.workout,
    required this.primaryMetricsLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    final colors = context.appColors;
    final padding = compact
        ? const EdgeInsets.fromLTRB(18, 10, 10, 10)
        : const EdgeInsets.fromLTRB(20, 12, 12, 12);
    final titleStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: compact ? 16 : 18,
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppTheme.workoutCardBorderRadius,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    workout.name,
                    style: titleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 4 : 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    primaryMetricsLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.1,
                      fontSize: compact ? 13 : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
