import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../models/workout.dart';
import '../../services/user_service.dart';
import '../../services/workout_achievement_service.dart';
import '../../theme/app_theme.dart';
import '../timeline/timeline_header_row.dart';
import '../timeline/timeline_list_item.dart';
import '../timeline/timeline_row.dart';
import '../timeline/workout_achievement_awards.dart';
import '../timeline/workout_timeline_card.dart';

// policy: no-test-needed item rendering is covered by Home screen widget tests.
class HomeTimelineItemBuilder {
  final List<TimelineListItem> items;
  final Future<void> Function(Workout workout) onOpenWorkout;
  final VoidCallback onOpenHistory;
  final double lineHighlightProgress;
  final double historyPullProgress;
  final bool historyDetentArmed;

  const HomeTimelineItemBuilder({
    required this.items,
    required this.onOpenWorkout,
    required this.onOpenHistory,
    required this.lineHighlightProgress,
    required this.historyPullProgress,
    required this.historyDetentArmed,
  });

  Widget build(BuildContext context, TimelineListItem item, int index) {
    if (item is! TimelineDayGroupItem) {
      if (item is TimelineHistoryEndcapItem) {
        return _buildHistoryEndcap(context, item, index);
      }
      return const SizedBox.shrink();
    }

    final workouts = item.workouts;
    final firstWorkout = workouts.first;
    final timestamp = item.date;
    const style = TimelineLineStyle.straight;

    return TimelineRow(
      timestamp: timestamp,
      index: index,
      isNested: false,
      style: style,
      nodeRadius: 9,
      isTopDotted: index == 0,
      lineHighlightProgress: lineHighlightProgress,
      node: _buildWorkoutNode(context, firstWorkout),
      child: TimelineHeaderRow(
        dateText: _relativeDayLabel(timestamp),
        awards: const [],
        child: Column(
          children: workouts.map((workout) {
            final isLast = workout == workouts.last;
            final achievements = buildWorkoutAchievementAwards(
              context,
              WorkoutAchievementService.resolveForWorkout(workout),
            );
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
              child: GestureDetector(
                onTap: () => onOpenWorkout(workout),
                child: WorkoutTimelineCard(
                  workout: workout,
                  achievements: achievements,
                  primaryMetricsLabel: _primaryMetrics(workout),
                  compact: false,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHistoryEndcap(
    BuildContext context,
    TimelineHistoryEndcapItem item,
    int index,
  ) {
    final colors = context.appColors;
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final endcapHighlightProgress = ((lineHighlightProgress - 0.35) / 0.65)
        .clamp(0.0, 1.0);
    final pullProgress = historyPullProgress.clamp(0.0, 1.0);
    final totalEndcapProgress = (endcapHighlightProgress + pullProgress * 0.75)
        .clamp(0.0, 1.0);
    final endcapFill = Color.lerp(
      colors.field,
      scheme.primary.withValues(alpha: historyDetentArmed ? 0.24 : 0.18),
      totalEndcapProgress,
    )!;
    final endcapNodeColor = Color.lerp(
      colors.textTertiary,
      historyDetentArmed ? scheme.primary : scheme.onSurface,
      totalEndcapProgress,
    )!;
    final scale = 1.0 + pullProgress * 0.025;
    final verticalOffset = -6.0 * pullProgress;

    return TimelineRow(
      timestamp: DateTime.now(),
      index: index,
      style: TimelineLineStyle.straight,
      isLast: true,
      nodeRadius: 7,
      lineHighlightProgress: lineHighlightProgress,
      node: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: endcapNodeColor,
          shape: BoxShape.circle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 8),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          offset: Offset(0, verticalOffset / 48),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            scale: scale,
            child: Material(
              color: colors.transparent,
              child: InkWell(
                onTap: onOpenHistory,
                borderRadius: AppTheme.workoutCardBorderRadius,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 + pullProgress * 4,
                    vertical: 10 + pullProgress * 2,
                  ),
                  decoration: BoxDecoration(
                    color: endcapFill,
                    borderRadius: AppTheme.workoutCardBorderRadius,
                    border: Border.all(
                      color: scheme.primary.withValues(
                        alpha: historyDetentArmed ? 0.35 : 0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 120),
                          style: textTheme.titleSmall!.copyWith(
                            color: Color.lerp(
                              colors.textPrimary,
                              scheme.primary,
                              totalEndcapProgress,
                            ),
                          ),
                          child: const Text('View full history'),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        color: Color.lerp(
                          colors.textSecondary,
                          scheme.primary,
                          totalEndcapProgress,
                        ),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _relativeDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (normalizedDate == today) {
      return 'Today';
    }
    if (normalizedDate == yesterday) {
      return 'Yesterday';
    }

    final diffDays = today.difference(normalizedDate).inDays;
    if (diffDays > 1 && diffDays < 7) {
      return '$diffDays days ago';
    }

    if (date.year != now.year) {
      return DateFormat('E, MMM d, y').format(date);
    }

    return DateFormat('E, MMM d').format(date);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  String _formatWeight(double weight) {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    final unitLabel = units == Units.imperial ? 'lbs' : 'kg';

    if (weight.abs() >= 1000) {
      return '${(weight / 1000).toStringAsFixed(1)}k $unitLabel';
    }

    return '${weight.toStringAsFixed(0)} $unitLabel';
  }

  String _primaryMetrics(Workout workout) {
    final started = workout.startedAt;
    final completed = workout.completedAt;
    final duration = (started != null && completed != null)
        ? completed.difference(started)
        : Duration.zero;

    final durationText = _formatDuration(duration);
    final setsText = '${workout.totalSets} sets';

    if (workout.totalWeight > 0) {
      final volumeText = _formatWeight(workout.totalWeight);
      return '$durationText • $setsText • $volumeText';
    }

    return '$durationText • $setsText';
  }

  Widget _buildWorkoutNode(BuildContext context, Workout workout) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: workout.color, shape: BoxShape.circle),
      child: Center(
        child: Icon(
          workout.icon,
          size: 12,
          color: context.appColors.overlayMedium,
        ),
      ),
    );
  }
}
