import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:logging/logging.dart';

import '../constants/app_constants.dart';
import '../models/workout.dart';
import '../screens/home/home_timeline_data.dart';
import '../screens/workout_detail_screen.dart';
import '../services/user_service.dart';
import '../services/workout_service.dart';
import '../services/workout_timeline_grouping_service.dart';
import '../widgets/home/home_timeline_item_builder.dart';
import '../widgets/profile_icon_button.dart';
import '../widgets/timeline/animated_insert.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../widgets/timeline/skeleton_timeline_row.dart';
import '../widgets/timeline/timeline_list_item.dart';
import '../widgets/timeline/archive_trigger_footer.dart';

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
    WorkoutService.instance.addListener(_handleWorkoutServiceChanged);
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
    WorkoutService.instance.removeListener(_handleWorkoutServiceChanged);
    _scrollController.dispose();
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _handleWorkoutServiceChanged() {
    if (!mounted) {
      return;
    }

    _applyTimeline(WorkoutService.instance.workouts);
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

    await WorkoutService.instance.loadData();
  }

  void _applyTimeline(List<Workout> workouts) {
    if (!mounted) {
      return;
    }

    try {
      _logger.info('Loading completed workouts for Home timeline');
      _logger.fine('Loaded ${workouts.length} workouts from WorkoutService cache');
      final timelineData = HomeTimelineAssembler.build(workouts);

      // Initialize archive pagination
      _allArchiveGroups = timelineData.archiveGroups;
      _nextArchiveIndex = 0;
      _isArchiveVisible = false;

      if (mounted) {
        setState(() {
          _expandedMonths.clear();
          _timelineItems = timelineData.items;
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
          it.group.key == key,
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
    if (item is TimelineFooterItem) {
      return ArchiveTriggerFooter(
        key: _archiveTriggerKey,
        onTrigger: _revealArchive,
        isVisible: true,
      );
    }

    return HomeTimelineItemBuilder(
      items: _timelineItems,
      expandedMonths: _expandedMonths,
      onOpenWorkout: _openWorkoutDetail,
      onToggleMonth: _toggleMonth,
      onHideArchive: _hideArchive,
    ).build(context, item, index);
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
