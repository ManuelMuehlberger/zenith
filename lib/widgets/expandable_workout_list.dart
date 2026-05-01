import 'package:flutter/material.dart';
import '../screens/insights/insights_view_data.dart';
import '../theme/app_theme.dart';

class ExpandableWorkoutList extends StatefulWidget {
  final DateTime selectedDate;
  final List<WorkoutDisplayItem> workoutDisplayItems;
  final bool isExpanded;
  final VoidCallback onToggleExpansion;

  const ExpandableWorkoutList({
    super.key,
    required this.selectedDate,
    required this.workoutDisplayItems,
    required this.isExpanded,
    required this.onToggleExpansion,
  });

  @override
  State<ExpandableWorkoutList> createState() => _ExpandableWorkoutListState();
}

class _ExpandableWorkoutListState extends State<ExpandableWorkoutList> {
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Workouts on ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                    style: textTheme.titleMedium,
                  ),
                ),
                if (widget.workoutDisplayItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${widget.workoutDisplayItems.length}',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content section
          Expanded(
            child: widget.workoutDisplayItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No workouts on this date',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.workoutDisplayItems.length,
                    itemBuilder: (context, index) {
                      final displayItem = widget.workoutDisplayItems[index];
                      final workout = displayItem.workout;
                      final workoutDetails = displayItem.workoutDetails;

                      final IconData iconData =
                          workoutDetails?.icon ?? Icons.fitness_center;
                      final Color iconColor =
                          workoutDetails?.color ?? colorScheme.primary;

                      return Card(
                        color: colorScheme.surface,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row with icon and workout name
                              Row(
                                children: [
                                  // Squircle background for icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: iconColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      workout.name,
                                      style: textTheme.titleSmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Bottom row with stats
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: colors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(
                                      workout.completedAt != null &&
                                              workout.startedAt != null
                                          ? workout.completedAt!.difference(
                                              workout.startedAt!,
                                            )
                                          : Duration.zero,
                                    ),
                                    style: textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.fitness_center,
                                    size: 16,
                                    color: colors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${workout.exercises.length} exercise${workout.exercises.length != 1 ? 's' : ''}',
                                    style: textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.repeat,
                                    size: 16,
                                    color: colors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${workout.totalSets} sets',
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
