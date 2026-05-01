import 'package:flutter/material.dart';

import '../../models/workout.dart';
import '../../services/workout_timeline_grouping_service.dart';
import '../timeline/archive_trigger_footer.dart';
import '../timeline/timeline_list_item.dart';
import 'home_timeline_item_builder.dart';

class HomeScreenTimelineRow extends StatelessWidget {
  final TimelineListItem item;
  final int index;
  final GlobalKey<ArchiveTriggerFooterState> archiveTriggerKey;
  final List<TimelineListItem> timelineItems;
  final Set<MonthKey> expandedMonths;
  final VoidCallback onRevealArchive;
  final Future<void> Function(Workout workout) onOpenWorkout;
  final ValueChanged<MonthKey> onToggleMonth;
  final Future<void> Function() onHideArchive;

  const HomeScreenTimelineRow({
    super.key,
    required this.item,
    required this.index,
    required this.archiveTriggerKey,
    required this.timelineItems,
    required this.expandedMonths,
    required this.onRevealArchive,
    required this.onOpenWorkout,
    required this.onToggleMonth,
    required this.onHideArchive,
  });

  @override
  Widget build(BuildContext context) {
    if (item is TimelineFooterItem) {
      return ArchiveTriggerFooter(
        key: archiveTriggerKey,
        onTrigger: onRevealArchive,
        isVisible: true,
      );
    }

    return HomeTimelineItemBuilder(
      items: timelineItems,
      expandedMonths: expandedMonths,
      onOpenWorkout: onOpenWorkout,
      onToggleMonth: onToggleMonth,
      onHideArchive: onHideArchive,
    ).build(context, item, index);
  }
}
