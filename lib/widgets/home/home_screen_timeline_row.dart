import 'package:flutter/material.dart';

import '../../models/workout.dart';
import '../timeline/timeline_list_item.dart';
import 'home_timeline_item_builder.dart';

// policy: no-test-needed timeline rows are covered through Home screen widget tests.
class HomeScreenTimelineRow extends StatelessWidget {
  final TimelineListItem item;
  final int index;
  final List<TimelineListItem> timelineItems;
  final Future<void> Function(Workout workout) onOpenWorkout;
  final VoidCallback onOpenHistory;
  final double lineHighlightProgress;
  final double historyPullProgress;
  final bool historyDetentArmed;

  const HomeScreenTimelineRow({
    super.key,
    required this.item,
    required this.index,
    required this.timelineItems,
    required this.onOpenWorkout,
    required this.onOpenHistory,
    required this.lineHighlightProgress,
    required this.historyPullProgress,
    required this.historyDetentArmed,
  });

  @override
  Widget build(BuildContext context) {
    return HomeTimelineItemBuilder(
      items: timelineItems,
      onOpenWorkout: onOpenWorkout,
      onOpenHistory: onOpenHistory,
      lineHighlightProgress: lineHighlightProgress,
      historyPullProgress: historyPullProgress,
      historyDetentArmed: historyDetentArmed,
    ).build(context, item, index);
  }
}
