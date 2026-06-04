import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../models/workout.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../timeline/award_stack.dart';
import '../timeline/timeline_header_row.dart';
import '../timeline/timeline_list_item.dart';
import '../timeline/timeline_row.dart';
import '../timeline/workout_timeline_card.dart';

// policy: no-test-needed item rendering is covered by Home screen widget tests.
class HomeTimelineItemBuilder {
  final List<TimelineListItem> items;
  final Future<void> Function(Workout workout) onOpenWorkout;

  const HomeTimelineItemBuilder({
    required this.items,
    required this.onOpenWorkout,
  });

  Widget build(BuildContext context, TimelineListItem item, int index) {
    if (item is! TimelineDayGroupItem) {
      return const SizedBox.shrink();
    }

    final workouts = item.workouts;
    final firstWorkout = workouts.first;
    final timestamp = item.date;
    final style = index == items.length - 1
        ? TimelineLineStyle.curved
        : TimelineLineStyle.straight;

    final uniqueAwards = <String, Award>{};
    for (final workout in workouts) {
      for (final award in _awardsForWorkout(context, workout)) {
        uniqueAwards.putIfAbsent(award.title, () => award);
      }
    }

    return TimelineRow(
      timestamp: timestamp,
      index: index,
      isNested: false,
      style: style,
      nodeRadius: 9,
      node: _buildWorkoutNode(context, firstWorkout),
      child: TimelineHeaderRow(
        dateText: _relativeDayLabel(timestamp),
        awards: uniqueAwards.values.toList(),
        child: Column(
          children: workouts.map((workout) {
            final isLast = workout == workouts.last;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
              child: GestureDetector(
                onTap: () => onOpenWorkout(workout),
                child: WorkoutTimelineCard(
                  workout: workout,
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

  List<Award> _awardsForWorkout(BuildContext context, Workout workout) {
    final started = workout.startedAt;
    final completed = workout.completedAt;
    final duration = (started != null && completed != null)
        ? completed.difference(started)
        : Duration.zero;

    final awards = <Award>[];

    if (workout.totalSets >= 20) {
      awards.add(
        Award(
          title: 'High Volume',
          icon: Icons.local_fire_department,
          color: context.appColors.warning,
        ),
      );
    }

    if (duration.inMinutes >= 60) {
      awards.add(
        Award(
          title: 'Long Session',
          icon: Icons.timer_outlined,
          color: context.appScheme.primary,
        ),
      );
    }

    if (workout.totalWeight >= 10000) {
      awards.add(
        Award(
          title: 'Heavy',
          icon: Icons.fitness_center,
          color: context.appColors.success,
        ),
      );
    }

    if (awards.isEmpty) {
      awards.add(
        Award(
          title: 'Completed',
          icon: Icons.check_circle,
          color: context.appScheme.primary,
        ),
      );
    }

    return awards;
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
