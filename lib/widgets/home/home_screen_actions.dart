import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../../models/workout.dart';
import '../../screens/home/home_timeline_data.dart';
import '../../screens/workout_detail_screen.dart';
import '../../services/workout_timeline_grouping_service.dart';
import '../timeline/animated_insert.dart';
import '../timeline/archive_trigger_footer.dart';
import '../timeline/timeline_list_item.dart';

class HomeScreenActions {
  const HomeScreenActions._();

  static void handleWorkoutServiceChanged({
    required bool mounted,
    required ValueChanged<List<Workout>> applyTimeline,
    required List<Workout> workouts,
  }) {
    if (!mounted) return;
    applyTimeline(workouts);
  }

  static void onScroll({
    required ScrollController scrollController,
    required bool isArchiveVisible,
    required Future<void> Function() fetchNextMonth,
  }) {
    if (!scrollController.hasClients || !isArchiveVisible) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      fetchNextMonth();
    }
  }

  static bool onScrollNotification({
    required ScrollNotification notification,
    required bool isArchiveVisible,
    required GlobalKey<ArchiveTriggerFooterState> archiveTriggerKey,
    required Future<void> Function() hideArchive,
  }) {
    if (notification is! ScrollUpdateNotification) {
      return false;
    }
    if (isArchiveVisible) {
      if (notification.metrics.pixels <= 50.0) {
        hideArchive();
      }
      return false;
    }
    if (notification.metrics.extentAfter != 0) {
      return false;
    }
    final overscroll =
        notification.metrics.pixels - notification.metrics.maxScrollExtent;
    archiveTriggerKey.currentState?.updateScroll(overscroll);
    if (overscroll > 50.0 && overscroll < 60.0) {
      HapticFeedback.selectionClick();
    } else if (overscroll > 80.0 && overscroll < 90.0) {
      HapticFeedback.mediumImpact();
    }
    if (overscroll > 100.0) {
      HapticFeedback.heavyImpact();
      archiveTriggerKey.currentState?.trigger();
    }
    return false;
  }

  static Future<void> fetchNextMonth({
    required bool isLoadingMore,
    required int nextArchiveIndex,
    required List<MonthlyWorkoutGroup> allArchiveGroups,
    required bool Function() isMounted,
    required void Function(VoidCallback fn) setStateCallback,
    required List<TimelineListItem> timelineItems,
    required GlobalKey<SliverAnimatedListState> timelineListKey,
    required ValueChanged<bool> setLoadingMore,
    required ValueChanged<int> setNextArchiveIndex,
  }) async {
    if (isLoadingMore || nextArchiveIndex >= allArchiveGroups.length) return;
    setStateCallback(() {
      setLoadingMore(true);
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!isMounted()) return;
    final updatedIndex = nextArchiveIndex + 1;
    final group = allArchiveGroups[nextArchiveIndex];
    final insertIndex = timelineItems.length - 1;
    setNextArchiveIndex(updatedIndex);
    setStateCallback(() {
      timelineItems.insert(insertIndex, TimelineMonthSummaryItem(group: group));
      setLoadingMore(false);
    });
    timelineListKey.currentState?.insertItem(insertIndex);
  }

  static void applyTimeline({
    required bool mounted,
    required Logger logger,
    required List<Workout> workouts,
    required ValueChanged<HomeTimelineData> onTimelineReady,
    required VoidCallback onFailure,
  }) {
    if (!mounted) return;
    try {
      logger.info('Loading completed workouts for Home timeline');
      logger.fine(
        'Loaded ${workouts.length} workouts from WorkoutService cache',
      );
      onTimelineReady(HomeTimelineAssembler.build(workouts));
      logger.info('Home timeline workouts loaded successfully');
    } catch (error) {
      logger.severe('Failed to load workouts for Home timeline: $error');
      onFailure();
    }
  }

  static Future<void> loadWorkouts({
    required bool mounted,
    required void Function(VoidCallback fn) setStateCallback,
    required ValueChanged<bool> setLoading,
    required Future<void> Function() loadData,
  }) async {
    if (!mounted) return;
    setStateCallback(() {
      setLoading(true);
    });
    await loadData();
  }

  static Future<void> openWorkoutDetail({
    required BuildContext context,
    required Workout workout,
    required Future<void> Function() loadWorkouts,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workout: workout),
      ),
    );
    if (result == true) {
      unawaited(loadWorkouts());
    }
  }

  static void revealArchive({
    required void Function(VoidCallback fn) setStateCallback,
    required ValueChanged<bool> setArchiveVisible,
    required List<TimelineListItem> timelineItems,
    required GlobalKey<SliverAnimatedListState> timelineListKey,
    required List<MonthlyWorkoutGroup> allArchiveGroups,
    required int nextArchiveIndex,
    required ValueChanged<int> setNextArchiveIndex,
    required ScrollController scrollController,
    required Widget Function(TimelineListItem item, int index) rowBuilder,
  }) {
    HapticFeedback.mediumImpact();
    setStateCallback(() {
      setArchiveVisible(true);
    });

    final footerIndex = timelineItems.indexWhere(
      (item) => item is TimelineFooterItem,
    );
    if (footerIndex != -1) {
      final removed = timelineItems.removeAt(footerIndex);
      timelineListKey.currentState?.removeItem(
        footerIndex,
        (context, animation) => AnimatedInsert(
          animation: animation,
          child: rowBuilder(removed, footerIndex),
        ),
      );
    }

    final metricsIndex = timelineItems.indexWhere(
      (item) => item is TimelineMetricsItem,
    );
    final insertHeaderIndex = metricsIndex != -1
        ? metricsIndex + 1
        : timelineItems.length;

    timelineItems.insert(insertHeaderIndex, const TimelineArchiveHeaderItem());
    timelineListKey.currentState?.insertItem(insertHeaderIndex);

    final triggerIndex = insertHeaderIndex + 1;
    timelineItems.insert(triggerIndex, const TimelineHideHistoryItem());
    timelineListKey.currentState?.insertItem(triggerIndex);

    final newItems = <TimelineListItem>[];
    var lastYear = DateTime.now().year;
    var currentArchiveIndex = nextArchiveIndex;

    while (currentArchiveIndex < allArchiveGroups.length) {
      final group = allArchiveGroups[currentArchiveIndex];
      if (group.key.year != lastYear) {
        newItems.add(TimelineYearItem(year: group.key.year));
        lastYear = group.key.year;
      }
      currentArchiveIndex++;
      newItems.add(TimelineMonthSummaryItem(group: group));
    }

    setNextArchiveIndex(currentArchiveIndex);
    newItems.add(const TimelineEndcapItem());

    if (newItems.isNotEmpty) {
      final insertStartIndex = timelineItems.length;
      setStateCallback(() {
        timelineItems.addAll(newItems);
      });
      for (var index = 0; index < newItems.length; index++) {
        timelineListKey.currentState?.insertItem(
          insertStartIndex + index,
          duration: const Duration(milliseconds: 500),
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController
          .animateTo(
            scrollController.position.pixels - 20.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          )
          .then((_) {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.pixels + 120.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
              );
            }
          });
    });
  }

  static Future<void> hideArchive({
    required void Function(VoidCallback fn) setStateCallback,
    required ValueChanged<bool> setArchiveVisible,
    required List<TimelineListItem> timelineItems,
    required GlobalKey<SliverAnimatedListState> timelineListKey,
    required List<MonthlyWorkoutGroup> allArchiveGroups,
    required Set<MonthKey> expandedMonths,
    required ValueChanged<int> setNextArchiveIndex,
    required Widget Function(TimelineListItem item, int index) rowBuilder,
  }) async {
    unawaited(HapticFeedback.mediumImpact());
    setStateCallback(() {
      setArchiveVisible(false);
    });

    final headerIndex = timelineItems.indexWhere(
      (item) => item is TimelineArchiveHeaderItem,
    );
    final startIndex = headerIndex != -1
        ? headerIndex
        : timelineItems.indexWhere((item) => item is TimelineHideHistoryItem);

    if (startIndex != -1) {
      for (var index = timelineItems.length - 1; index >= startIndex; index--) {
        final removed = timelineItems.removeAt(index);
        timelineListKey.currentState?.removeItem(
          index,
          (context, animation) => AnimatedInsert(
            animation: animation,
            child: rowBuilder(removed, index),
          ),
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    setNextArchiveIndex(0);
    expandedMonths.clear();

    if (allArchiveGroups.isNotEmpty) {
      final footerIndex = timelineItems.length;
      timelineItems.add(const TimelineFooterItem());
      timelineListKey.currentState?.insertItem(footerIndex);
    }
  }

  static void toggleMonth({
    required MonthKey key,
    required List<TimelineListItem> timelineItems,
    required Set<MonthKey> expandedMonths,
    required GlobalKey<SliverAnimatedListState> timelineListKey,
    required void Function(VoidCallback fn) setStateCallback,
    required Widget Function(TimelineListItem item, int index) rowBuilder,
  }) {
    final summaryIndex = timelineItems.indexWhere(
      (item) => item is TimelineMonthSummaryItem && item.group.key == key,
    );
    if (summaryIndex == -1) return;

    final group =
        (timelineItems[summaryIndex] as TimelineMonthSummaryItem).group;
    final isExpanded = expandedMonths.contains(key);
    HapticFeedback.lightImpact();

    if (!isExpanded) {
      setStateCallback(() {
        expandedMonths.add(key);
      });
      final insertAt = summaryIndex + 1;
      timelineItems.insert(insertAt, const TimelineMonthOpenItem());
      timelineListKey.currentState?.insertItem(insertAt);

      for (var index = 0; index < group.workouts.length; index++) {
        final workout = group.workouts[index];
        timelineItems.insert(
          insertAt + 1 + index,
          TimelineWorkoutItem(
            workout: workout,
            isNested: true,
            animationDelay: index * 50,
          ),
        );
        timelineListKey.currentState?.insertItem(
          insertAt + 1 + index,
          duration: const Duration(milliseconds: 220),
        );
      }

      final closeIndex = insertAt + 1 + group.workouts.length;
      timelineItems.insert(
        closeIndex,
        TimelineMonthCloseItem(animationDelay: group.workouts.length * 50),
      );
      timelineListKey.currentState?.insertItem(closeIndex);
      return;
    }

    setStateCallback(() {
      expandedMonths.remove(key);
    });
    final removeAt = summaryIndex + 1;
    final countToRemove = group.workouts.length + 2;

    for (var offset = countToRemove - 1; offset >= 0; offset--) {
      final index = removeAt + offset;
      if (index >= timelineItems.length) continue;
      final removed = timelineItems.removeAt(index);
      timelineListKey.currentState?.removeItem(
        index,
        (context, animation) => AnimatedInsert(
          animation: animation,
          child: rowBuilder(removed, index),
        ),
        duration: const Duration(milliseconds: 200),
      );
    }
  }
}
