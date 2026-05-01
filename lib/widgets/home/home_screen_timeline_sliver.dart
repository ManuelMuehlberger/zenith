import 'package:flutter/material.dart';

import '../timeline/animated_insert.dart';
import '../timeline/timeline_list_item.dart';

class HomeScreenTimelineSliver extends StatelessWidget {
  final GlobalKey<SliverAnimatedListState> timelineListKey;
  final List<TimelineListItem> timelineItems;
  final Widget Function(TimelineListItem item, int index) rowBuilder;

  const HomeScreenTimelineSliver({
    super.key,
    required this.timelineListKey,
    required this.timelineItems,
    required this.rowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverAnimatedList(
        key: timelineListKey,
        initialItemCount: timelineItems.length,
        itemBuilder: (context, index, animation) {
          final item = timelineItems[index];

          if (item is TimelineArchiveHeaderItem) {
            return AnimatedInsert(
              animation: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: rowBuilder(item, index),
              ),
            );
          }

          return AnimatedInsert(
            animation: animation,
            slideInFromBottom: item is TimelineMonthSummaryItem,
            child: rowBuilder(item, index),
          );
        },
      ),
    );
  }
}
