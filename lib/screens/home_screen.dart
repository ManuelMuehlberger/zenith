import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:logging/logging.dart';

import '../constants/app_constants.dart';
import '../models/workout.dart';
import '../screens/workout_detail_screen.dart';
import '../services/user_service.dart';
import '../services/workout_service.dart';
import '../services/workout_timeline_grouping_service.dart';
import '../widgets/profile_icon_button.dart';
import '../widgets/timeline/animated_insert.dart';
import '../widgets/timeline/award_stack.dart';
import '../widgets/timeline/month_summary_card.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../widgets/timeline/skeleton_timeline_row.dart';
import '../widgets/timeline/timeline_list_item.dart';
import '../widgets/timeline/timeline_row.dart';
import '../widgets/timeline/timeline_header_row.dart';
import '../widgets/timeline/workout_timeline_card.dart';
import '../widgets/timeline/archive_workout_row.dart';
import '../widgets/timeline/archive_trigger_footer.dart';
import '../widgets/timeline/performance_metrics_card.dart';
import '../widgets/timeline/hide_history_trigger.dart';

class DetentScrollPhysics extends BouncingScrollPhysics {
  const DetentScrollPhysics({super.parent});

  @override
  DetentScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return DetentScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // If overscrolling at the bottom
    if (position.pixels >= position.maxScrollExtent && offset < 0) {
      final overscroll = position.pixels - position.maxScrollExtent;
      // If we are past the trigger point (e.g. 120), apply massive friction
      // This creates the "detent" or "wall" effect requested.
      if (overscroll > 120) {
        return offset * 0.05; 
      }
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Logger _logger = Logger('HomeScreen');

  List<TimelineListItem> _timelineItems = const [];
  final Set<MonthKey> _expandedMonths = <MonthKey>{};

  // We re-create this key on each full reload to avoid complex diffing.
  GlobalKey<SliverAnimatedListState> _timelineListKey =
      GlobalKey<SliverAnimatedListState>();

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ArchiveTriggerFooterState> _archiveTriggerKey = GlobalKey();
  
  List<MonthlyWorkoutGroup> _allArchiveGroups = [];
  int _nextArchiveIndex = 0;
  bool _isLoadingMore = false;

  bool _isLoading = true;
  bool _showGreetingTitle = true;
  bool _isArchiveVisible = false;
  bool _isScrollable = true;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadWorkouts();
      }
    });
    // Show greeting in the header for 2 seconds on startup, then switch to "Recent Workouts"
    _greetingTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showGreetingTitle = false;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    // Only fetch more if archive is visible
    if (!_isArchiveVisible) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (currentScroll >= maxScroll * 0.8) {
      _fetchNextMonth();
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      // If archive is visible and user scrolls back to the top, hide it
      if (_isArchiveVisible) {
        final currentScroll = notification.metrics.pixels;
        // If scrolled all the way to the top (within a small threshold)
        if (currentScroll <= 50.0) {
          _hideArchive();
        }
        return false;
      }

      // Only listen to overscroll at the bottom when archive is not visible
      if (notification.metrics.extentAfter == 0) {
        final overscroll = notification.metrics.pixels - notification.metrics.maxScrollExtent;
        _archiveTriggerKey.currentState?.updateScroll(overscroll);
        
        // Progressive haptic feedback as user approaches threshold
        if (overscroll > 50.0 && overscroll < 60.0) {
          HapticFeedback.selectionClick();
        } else if (overscroll > 80.0 && overscroll < 90.0) {
          HapticFeedback.mediumImpact();
        }
        
        // Trigger immediately when threshold is reached
        if (overscroll > 100.0) {
          HapticFeedback.heavyImpact();
          _archiveTriggerKey.currentState?.trigger();
        }
      }
    }
    
    return false;
  }

  Future<void> _fetchNextMonth() async {
    if (_isLoadingMore || _nextArchiveIndex >= _allArchiveGroups.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate a small delay for the "lazy load" effect
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final group = _allArchiveGroups[_nextArchiveIndex];
    _nextArchiveIndex++;

    // Insert before the footer (last item)
    final insertIndex = _timelineItems.length - 1;
    final newItem = TimelineMonthSummaryItem(group: group);

    setState(() {
      _timelineItems.insert(insertIndex, newItem);
      _isLoadingMore = false;
    });
    
    _timelineListKey.currentState?.insertItem(insertIndex);
  }

  void _revealArchive() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isArchiveVisible = true;
    });

    // Remove the footer
    final footerIndex = _timelineItems.indexWhere((item) => item is TimelineFooterItem);
    if (footerIndex != -1) {
      final removed = _timelineItems.removeAt(footerIndex);
      _timelineListKey.currentState?.removeItem(
        footerIndex,
        (context, animation) => AnimatedInsert(
          animation: animation,
          child: _buildRowForItem(removed, footerIndex),
        ),
      );
    }

    // Insert Archive Header
    final metricsIndex = _timelineItems.indexWhere((item) => item is TimelineMetricsItem);
    final insertHeaderIndex = (metricsIndex != -1) ? metricsIndex + 1 : _timelineItems.length;
    
    _timelineItems.insert(insertHeaderIndex, const TimelineArchiveHeaderItem());
    _timelineListKey.currentState?.insertItem(insertHeaderIndex);

    // Add Hide History Trigger
    final triggerIndex = insertHeaderIndex + 1;
    _timelineItems.insert(triggerIndex, const TimelineHideHistoryItem());
    _timelineListKey.currentState?.insertItem(triggerIndex);

    // Load ALL remaining months
    final newItems = <TimelineListItem>[];
    int lastYear = DateTime.now().year;

    while (_nextArchiveIndex < _allArchiveGroups.length) {
      final group = _allArchiveGroups[_nextArchiveIndex];
      
      if (group.key.year != lastYear) {
        newItems.add(TimelineYearItem(year: group.key.year));
        lastYear = group.key.year;
      }

      _nextArchiveIndex++;
      newItems.add(TimelineMonthSummaryItem(group: group));
    }
    
    // Add Endcap at the very end
    newItems.add(const TimelineEndcapItem());

    if (newItems.isNotEmpty) {
      final insertStartIndex = _timelineItems.length;
      setState(() {
        _timelineItems.addAll(newItems);
      });
      
      for (int i = 0; i < newItems.length; i++) {
        // Use slideInFromBottom for the "fly in" effect
        _timelineListKey.currentState?.insertItem(
          insertStartIndex + i,
          duration: const Duration(milliseconds: 500),
        );
      }
    }

    // Scroll Detent Animation
    // When the archive is revealed, we animate the scroll position forward (down the list)
    // to simulate a "click" or "detent" feeling, snapping the new content into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // First, a quick snap back to create tension
        _scrollController.animateTo(
          _scrollController.position.pixels - 20.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        ).then((_) {
          // Then spring forward with more dramatic movement
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.pixels + 120.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
            );
          }
        });
      }
    });
  }

  Future<void> _hideArchive() async {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isArchiveVisible = false;
    });

    // Find Archive Header to remove everything from there downwards
    final headerIndex = _timelineItems.indexWhere((item) => item is TimelineArchiveHeaderItem);
    // Fallback to hide trigger if header not found
    final startIndex = headerIndex != -1 
        ? headerIndex 
        : _timelineItems.indexWhere((item) => item is TimelineHideHistoryItem);

    if (startIndex != -1) {
      // Remove items from bottom to top
      for (int i = _timelineItems.length - 1; i >= startIndex; i--) {
        final removed = _timelineItems.removeAt(i);
        _timelineListKey.currentState?.removeItem(
          i,
          (context, animation) => AnimatedInsert(
            animation: animation,
            child: _buildRowForItem(removed, i),
          ),
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    // Reset archive index
    _nextArchiveIndex = 0;
    _expandedMonths.clear();

    // Add Footer back
    if (_allArchiveGroups.isNotEmpty) {
      final footerIndex = _timelineItems.length;
      _timelineItems.add(const TimelineFooterItem());
      _timelineListKey.currentState?.insertItem(footerIndex);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadWorkouts();
    }
  }

  Future<void> loadWorkouts() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      _logger.info('Loading completed workouts for Home timeline');

      // Load all data from DB into WorkoutService cache
      await WorkoutService.instance.loadData();
      _logger.fine(
        'Loaded ${WorkoutService.instance.workouts.length} workouts from DB',
      );

      final buckets = WorkoutTimelineGroupingService.splitWorkouts(
        WorkoutService.instance.workouts,
      );

      // Keep list size consistent with previous Home behavior (tests expect 10)
      final recentLimited = buckets.recent.take(10).toList();

      final items = <TimelineListItem>[];
      
      // Group workouts by day
      if (recentLimited.isNotEmpty) {
        DateTime? currentDay;
        List<Workout> currentGroup = [];

        for (final w in recentLimited) {
          final date = w.completedAt ?? w.startedAt ?? DateTime.now();
          final day = DateTime(date.year, date.month, date.day);

          if (currentDay == null) {
            currentDay = day;
            currentGroup.add(w);
          } else if (currentDay == day) {
            currentGroup.add(w);
          } else {
            // New day, push previous group
            items.add(TimelineDayGroupItem(
              date: currentDay,
              workouts: List.from(currentGroup),
            ));
            currentDay = day;
            currentGroup = [w];
          }
        }
        // Push last group
        if (currentGroup.isNotEmpty && currentDay != null) {
          items.add(TimelineDayGroupItem(
            date: currentDay,
            workouts: List.from(currentGroup),
          ));
        }
      }

      // Calculate metrics
      final now = DateTime.now();
      final currentMonthKey = MonthKey(year: now.year, month: now.month);
      final lastMonthDate = DateTime(now.year, now.month - 1, 1);
      final lastMonthKey = MonthKey(year: lastMonthDate.year, month: lastMonthDate.month);

      // Helper to get metrics from buckets
      // Note: buckets.archive only contains "older" workouts (older than 7 days).
      // But for metrics we want ALL workouts in that month.
      // So we should recalculate metrics from all workouts.
      
      final allWorkouts = WorkoutService.instance.workouts.where((w) => w.status == WorkoutStatus.completed).toList();
      
      int currentMonthCount = 0;
      double currentMonthVolume = 0;
      int lastMonthCount = 0;
      double lastMonthVolume = 0;

      for (final w in allWorkouts) {
        final date = w.completedAt ?? w.startedAt;
        if (date == null) continue;
        
        if (date.year == currentMonthKey.year && date.month == currentMonthKey.month) {
          currentMonthCount++;
          currentMonthVolume += w.totalWeight;
        } else if (date.year == lastMonthKey.year && date.month == lastMonthKey.month) {
          lastMonthCount++;
          lastMonthVolume += w.totalWeight;
        }
      }

      // Only add metrics if there are any workouts in the system
      if (recentLimited.isNotEmpty || buckets.archive.isNotEmpty) {
        items.add(TimelineMetricsItem(
          currentMonthWorkouts: currentMonthCount,
          currentMonthVolume: currentMonthVolume,
          lastMonthWorkouts: lastMonthCount,
          lastMonthVolume: lastMonthVolume,
        ));
      }

      // Only add footer if there is actually history to show
      if (buckets.archive.isNotEmpty) {
        items.add(const TimelineFooterItem());
      }

      // Initialize archive pagination
      _allArchiveGroups = buckets.archive;
      _nextArchiveIndex = 0;
      _isArchiveVisible = false;

      if (mounted) {
        setState(() {
          _expandedMonths.clear();
          _timelineItems = items;
          _timelineListKey = GlobalKey<SliverAnimatedListState>();
          _isLoading = false;
        });

        // Check scrollability after layout to determine if we should allow overscroll
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
             setState(() {
               _isScrollable = _scrollController.position.maxScrollExtent > 0;
             });
          }
        });
      }

      _logger.info('Home timeline workouts loaded successfully');
    } catch (e) {
      _logger.severe('Failed to load workouts for Home timeline: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _relativeDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';

    final diffDays = today.difference(d).inDays;
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
    final isImperial = units == Units.imperial;
    final unitLabel = isImperial ? 'lbs' : 'kg';

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
      final volText = _formatWeight(workout.totalWeight);
      return '$durationText • $setsText • $volText';
    }

    return '$durationText • $setsText';
  }

  List<Award> _awardsForWorkout(Workout workout) {
    final started = workout.startedAt;
    final completed = workout.completedAt;
    final duration = (started != null && completed != null)
        ? completed.difference(started)
        : Duration.zero;

    final awards = <Award>[];

    if (workout.totalSets >= 20) {
      awards.add(
        const Award(
          title: 'High Volume',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
      );
    }

    if (duration.inMinutes >= 60) {
      awards.add(
        const Award(
          title: 'Long Session',
          icon: Icons.timer_outlined,
          color: Colors.lightBlue,
        ),
      );
    }

    if (workout.totalWeight >= 10000) {
      awards.add(
        const Award(
          title: 'Heavy',
          icon: Icons.fitness_center,
          color: Colors.green,
        ),
      );
    }

    if (awards.isEmpty) {
      awards.add(
        const Award(
          title: 'Completed',
          icon: Icons.check_circle,
          color: AppConstants.ACCENT_COLOR,
        ),
      );
    }

    return awards;
  }

  Future<void> _openWorkoutDetail(Workout workout) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workout: workout),
      ),
    );

    if (result == true) {
      loadWorkouts();
    }
  }

  void _toggleMonth(MonthKey key) {
    final summaryIndex = _timelineItems.indexWhere(
      (it) =>
          it is TimelineMonthSummaryItem &&
          (it as TimelineMonthSummaryItem).group.key == key,
    );

    if (summaryIndex == -1) return;

    final group = (_timelineItems[summaryIndex] as TimelineMonthSummaryItem).group;

    final isExpanded = _expandedMonths.contains(key);

    HapticFeedback.lightImpact();

    if (!isExpanded) {
      // Expand => insert workouts immediately below the month summary
      setState(() {
        _expandedMonths.add(key);
      });

      final insertAt = summaryIndex + 1;
      
      // Insert Open Connector
      _timelineItems.insert(insertAt, const TimelineMonthOpenItem());
      _timelineListKey.currentState?.insertItem(insertAt);
      
      // Insert Workouts
      for (int i = 0; i < group.workouts.length; i++) {
        final workout = group.workouts[i];
        final item = TimelineWorkoutItem(
          workout: workout, 
          isNested: true,
          animationDelay: i * 50,
        );

        final index = insertAt + 1 + i; // +1 for Open Connector
        _timelineItems.insert(index, item);
        _timelineListKey.currentState?.insertItem(
          index,
          duration: const Duration(milliseconds: 220),
        );
      }
      
      // Insert Close Connector
      final closeIndex = insertAt + 1 + group.workouts.length;
      _timelineItems.insert(closeIndex, TimelineMonthCloseItem(
        animationDelay: group.workouts.length * 50,
      ));
      _timelineListKey.currentState?.insertItem(closeIndex);
      
    } else {
      // Collapse => remove the previously inserted workout rows
      setState(() {
        _expandedMonths.remove(key);
      });

      final removeAt = summaryIndex + 1;

      // Remove items: Open Connector + Workouts + Close Connector
      // Total items to remove = 1 + workouts.length + 1
      final countToRemove = 1 + group.workouts.length + 1;
      
      // Remove from bottom to top
      for (int i = countToRemove - 1; i >= 0; i--) {
        final idx = removeAt + i;
        if (idx >= _timelineItems.length) continue;
        
        final removed = _timelineItems.removeAt(idx);
        _timelineListKey.currentState?.removeItem(
          idx,
          (context, animation) => AnimatedInsert(
            animation: animation,
            child: _buildRowForItem(removed, idx),
          ),
          duration: const Duration(milliseconds: 200),
        );
      }
    }
  }

  Widget _buildRowForItem(TimelineListItem item, int index) {
    if (item is TimelineDayGroupItem) {
      final workouts = item.workouts;
      final firstWorkout = workouts.first;
      final timestamp = item.date;

      // Check if the next item is a MonthSummary or if this is the last item in the list (which might be followed by archive footer/header).
      bool isLastInBlock = false;
      if (index < _timelineItems.length - 1) {
        final nextItem = _timelineItems[index + 1];
        if (nextItem is TimelineMonthSummaryItem ||
            nextItem is TimelineArchiveHeaderItem) {
          isLastInBlock = true;
        }
      }

      final style =
          isLastInBlock ? TimelineLineStyle.curved : TimelineLineStyle.straight;

      // Aggregate awards
      final uniqueAwards = <String, Award>{};
      for (final w in workouts) {
        for (final a in _awardsForWorkout(w)) {
          if (!uniqueAwards.containsKey(a.title)) {
            uniqueAwards[a.title] = a;
          }
        }
      }
      final displayAwards = uniqueAwards.values.toList();

      return TimelineRow(
        timestamp: timestamp,
        index: index,
        isNested: false,
        style: style,
        nodeRadius: 9,
        node: _buildWorkoutNode(firstWorkout),
        child: TimelineHeaderRow(
          dateText: _relativeDayLabel(timestamp),
          awards: displayAwards,
          child: Column(
            children: workouts.map((w) {
              final isLast = w == workouts.last;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
                child: GestureDetector(
                  onTap: () => _openWorkoutDetail(w),
                  child: WorkoutTimelineCard(
                    workout: w,
                    primaryMetricsLabel: _primaryMetrics(w),
                    compact: false,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    if (item is TimelineWorkoutItem) {
      final workout = item.workout;
      final timestamp =
          workout.completedAt ?? workout.startedAt ?? DateTime.now();

      if (item.isNested) {
        return GestureDetector(
          onTap: () => _openWorkoutDetail(workout),
          child: TimelineRow(
            timestamp: timestamp,
            index: index,
            isNested: true,
            style: TimelineLineStyle.straight, // Strictly Straight for data
            trackWidth: 86, // Indented track for nested items (46 + 40)
            nodeRadius: 9,
            animateLineColor: true,
            animationDelay: item.animationDelay,
            node: _buildWorkoutNode(workout),
            child: ArchiveWorkoutRow(
              workout: workout,
            ),
          ),
        );
      }
      
      // Fallback for non-nested TimelineWorkoutItem if any (shouldn't happen with new grouping)
      return const SizedBox.shrink();
    }

    if (item is TimelineMonthSummaryItem) {
      final group = item.group;
      // Use startOfMonth as a stable timestamp for the row.
      final timestamp = group.key.startOfMonth;
      final isExpanded = _expandedMonths.contains(group.key);

      return TimelineRow(
        timestamp: timestamp,
        index: index,
        style: TimelineLineStyle.straight, // Straight to connect to first card
        nodeRadius: 11,
        node: TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            begin: Colors.grey[600]!,
            end: isExpanded ? Colors.white : Colors.grey[600]!,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          builder: (context, color, child) {
            return Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        isExpandable: true,
        isExpanded: isExpanded,
        child: MonthSummaryCard(
          group: group,
          isExpanded: isExpanded,
          onTap: () => _toggleMonth(group.key),
        ),
      );
    }

    if (item is TimelineMetricsItem) {
      return TimelineRow(
        timestamp: DateTime.now(),
        index: index,
        style: TimelineLineStyle.straight,
        node: const SizedBox.shrink(),
        nodeRadius: 0, // Fix for "dot" bug (removes gap)
        child: PerformanceMetricsCard(
          currentMonthWorkouts: item.currentMonthWorkouts,
          currentMonthVolume: item.currentMonthVolume,
          lastMonthWorkouts: item.lastMonthWorkouts,
          lastMonthVolume: item.lastMonthVolume,
        ),
      );
    }

    if (item is TimelineFooterItem) {
      return ArchiveTriggerFooter(
        key: _archiveTriggerKey,
        onTrigger: _revealArchive,
        isVisible: true,
      );
    }

    if (item is TimelineHideHistoryItem) {
      return HideHistoryTrigger(
        onTrigger: _hideArchive,
      );
    }

    if (item is TimelineArchiveHeaderItem) {
      return TimelineRow(
        timestamp: DateTime.now(),
        index: index,
        style: TimelineLineStyle.curved,
        node: const SizedBox.shrink(),
        child: const SizedBox(height: 32),
      );
    }

    if (item is TimelineMonthOpenItem) {
      return _DelayedAnimator(
        delay: item.animationDelay,
        builder: (context, value) {
          final color = Color.lerp(
            const Color(0xFFE5E5EA).withOpacity(0.3),
            Colors.white,
            value,
          )!;
          return SizedBox(
            height: 16,
            child: CustomPaint(
              painter: _ConnectorPainter(
                isOpen: true,
                startX: 23, // Center of 46
                endX: 43,   // Center of 86
                color: color,
              ),
            ),
          );
        },
      );
    }

    if (item is TimelineMonthCloseItem) {
      return _DelayedAnimator(
        delay: item.animationDelay,
        builder: (context, value) {
          return SizedBox(
            height: 16,
            child: CustomPaint(
              painter: _ConnectorPainter(
                isOpen: false,
                startX: 23,
                endX: 43,
                isGradient: true,
                animationValue: value,
              ),
            ),
          );
        },
      );
    }

    if (item is TimelineEndcapItem) {
      return TimelineRow(
        timestamp: DateTime.now(),
        index: index,
        style: TimelineLineStyle.straight,
        isLast: true, // Don't draw line below
        isDotted: true,
        node: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
          ),
        ),
        nodeRadius: 6,
        child: const SizedBox(height: 32),
      );
    }

    if (item is TimelineYearItem) {
      return TimelineRow(
        timestamp: DateTime.now(),
        index: index,
        style: TimelineLineStyle.straight,
        isDotted: true,
        node: const SizedBox.shrink(),
        nodeRadius: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          alignment: Alignment.centerLeft,
          child: Text(
            item.year.toString(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildWorkoutNode(Workout workout) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: workout.color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          workout.icon,
          size: 12,
          color: Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If archive is visible, we always allow scrolling/overscrolling because content is added.
    // If not visible, we respect the _isScrollable flag.
    final effectivePhysics = (_isArchiveVisible || _isScrollable)
        ? const DetentScrollPhysics(parent: AlwaysScrollableScrollPhysics())
        : const ClampingScrollPhysics();

    final TextStyle smallTitleStyle = AppConstants.HEADER_SMALL_TITLE_TEXT_STYLE.copyWith(fontSize: 20.0);
    final TextStyle largeTitleStyle = AppConstants.HEADER_EXTRA_LARGE_TITLE_TEXT_STYLE;

    // The small title widget, used in the collapsed app bar
    final Widget smallTitle = AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, axisAlignment: -1.0, child: child),
      ),
      child: _showGreetingTitle
          ? AnimatedBuilder(
              key: const ValueKey('greeting_title'),
              animation: UserService.instance,
              builder: (context, _) {
                final name = UserService.instance.currentProfile?.name.trim();
                final greeting = (name != null && name.isNotEmpty) ? 'Hey, $name!' : 'Hey!';
                return Text(greeting, textAlign: TextAlign.center, style: smallTitleStyle);
              },
            )
          : Text(
              'Recent Workouts',
              key: const ValueKey('recent_title'),
              textAlign: TextAlign.center,
              style: smallTitleStyle,
            ),
    );

    // The large title widget, used in the expanded app bar background
    final Widget largeTitle = AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation),
      child: _showGreetingTitle
          ? AnimatedBuilder(
              key: const ValueKey('large_greeting_title'),
              animation: UserService.instance,
              builder: (context, _) {
                final name = UserService.instance.currentProfile?.name.trim();
                final greeting = (name != null && name.isNotEmpty) ? 'Hey, $name!' : 'Hey!';
                return Text(greeting, textAlign: TextAlign.center, style: largeTitleStyle);
              },
            )
          : Text(
              'Recent Workouts',
              key: const ValueKey('large_recent_title'),
              textAlign: TextAlign.center,
              style: AppConstants.HEADER_EXTRA_LARGE_TITLE_TEXT_STYLE.copyWith(
                color: Colors.white,
              ),
            ),
    );

    final hasAnyItems = _timelineItems.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: CustomScrollView(
          controller: _scrollController,
          physics: effectivePhysics,
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              centerTitle: true,
              automaticallyImplyLeading: false,
              leading: const SizedBox(width: kToolbarHeight),
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: AppConstants.HEADER_EXTRA_HEIGHT + kToolbarHeight,
              actions: [
                const ProfileIconButton(),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Persistent glass effect layer (covers expanded and collapsed states)
                      ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                            sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                          ),
                          child: Container(color: AppConstants.HEADER_BG_COLOR_STRONG),
                        ),
                      ),
                      // FlexibleSpaceBar handles title positioning and parallax of the large title
                      FlexibleSpaceBar(
                        centerTitle: true,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [smallTitle],
                        ),
                        background: Align(
                          alignment: Alignment.center,
                          child: largeTitle,
                        ),
                        collapseMode: CollapseMode.parallax,
                      ),
                    ],
                  );
                },
              ),
            ),
            // Content
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                ),
              )
            else if (!hasAnyItems)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No workouts yet',
                          style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(
                            color: AppConstants.TEXT_SECONDARY_COLOR,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start by creating a workout in the Builder tab',
                          style: AppConstants.IOS_SUBTITLE_TEXT_STYLE.copyWith(
                            color: AppConstants.TEXT_SECONDARY_COLOR,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverAnimatedList(
                  key: _timelineListKey,
                  initialItemCount: _timelineItems.length,
                  itemBuilder: (context, index, animation) {
                    final item = _timelineItems[index];
                    
                    if (item is TimelineArchiveHeaderItem) {
                      return AnimatedInsert(
                        animation: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: _buildRowForItem(item, index),
                        ),
                      );
                    }

                    // Check if this item is one of the "old months" being inserted during archive reveal.
                    // We can identify them by type TimelineMonthSummaryItem and if archive is visible.
                    // But simpler: just enable slideInFromBottom for MonthSummary items when archive is visible?
                    // Or just enable it for all items? 
                    // The user specifically said "old months should fly in".
                    // TimelineMonthSummaryItem is the main one.
                    
                    final isMonthSummary = item is TimelineMonthSummaryItem;
                    // We only want the "fly in" effect during the archive reveal animation.
                    // But AnimatedInsert is used for all insertions.
                    // If we enable it globally for MonthSummary, it might affect other insertions (like lazy load).
                    // But lazy load inserts at the bottom, so slide in from bottom is actually appropriate there too!
                    
                    return AnimatedInsert(
                      animation: animation,
                      slideInFromBottom: isMonthSummary,
                      child: _buildRowForItem(item, index),
                    );
                  },
                ),
              ),

            if (_isLoadingMore)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return SkeletonTimelineRow(index: index);
                    },
                    childCount: 3,
                  ),
                ),
              ),

            // Bottom spacer to avoid overlapping bottom navigation bar area
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom +
                    kBottomNavigationBarHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DelayedAnimator extends StatefulWidget {
  final int delay;
  final Widget Function(BuildContext, double) builder;

  const _DelayedAnimator({
    required this.delay,
    required this.builder,
  });

  @override
  State<_DelayedAnimator> createState() => _DelayedAnimatorState();
}

class _DelayedAnimatorState extends State<_DelayedAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return widget.builder(context, _animation.value);
      },
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final bool isOpen;
  final double startX;
  final double endX;
  final Color color;
  final bool isGradient;
  final double animationValue;

  _ConnectorPainter({
    required this.isOpen,
    required this.startX,
    required this.endX,
    this.color = Colors.white,
    this.isGradient = false,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isGradient) {
      final dimColor = const Color(0xFFE5E5EA).withOpacity(0.3);
      final topColor = Color.lerp(dimColor, Colors.white, animationValue)!;
      
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, dimColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }

    final path = Path();
    final midY = size.height / 2;
    final radius = 10.0;

    if (isOpen) {
      // Start Top (startX), go Down, Curve Right, go Right, Curve Down, go Down
      path.moveTo(startX, 0);
      path.lineTo(startX, midY - radius);
      path.quadraticBezierTo(startX, midY, startX + radius, midY);
      path.lineTo(endX - radius, midY);
      path.quadraticBezierTo(endX, midY, endX, midY + radius);
      path.lineTo(endX, size.height);
    } else {
      // Start Top (endX), go Down, Curve Left, go Left, Curve Down, go Down
      path.moveTo(endX, 0);
      path.lineTo(endX, midY - radius);
      path.quadraticBezierTo(endX, midY, endX - radius, midY);
      path.lineTo(startX + radius, midY);
      path.quadraticBezierTo(startX, midY, startX, midY + radius);
      path.lineTo(startX, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return oldDelegate.isOpen != isOpen ||
        oldDelegate.startX != startX ||
        oldDelegate.endX != endX ||
        oldDelegate.color != color ||
        oldDelegate.isGradient != isGradient ||
        oldDelegate.animationValue != animationValue;
  }
}
