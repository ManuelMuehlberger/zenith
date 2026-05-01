import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/workout.dart';
import '../services/workout_service.dart';
import '../services/workout_timeline_grouping_service.dart';
import '../widgets/home/home_screen_actions.dart';
import '../widgets/home/home_screen_body_slivers.dart';
import '../widgets/home/home_screen_sliver_app_bar.dart';
import '../widgets/home/home_screen_timeline_row.dart';
import '../widgets/home/home_screen_timeline_sliver.dart';
import '../widgets/timeline/archive_trigger_footer.dart';
import '../widgets/timeline/timeline_list_item.dart';

class DetentScrollPhysics extends BouncingScrollPhysics {
  const DetentScrollPhysics({super.parent});

  @override
  DetentScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return DetentScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (position.pixels >= position.maxScrollExtent && offset < 0) {
      final overscroll = position.pixels - position.maxScrollExtent;
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
    HomeScreenActions.handleWorkoutServiceChanged(
      mounted: mounted,
      applyTimeline: _applyTimeline,
      workouts: WorkoutService.instance.workouts,
    );
  }

  void _onScroll() {
    HomeScreenActions.onScroll(
      scrollController: _scrollController,
      isArchiveVisible: _isArchiveVisible,
      fetchNextMonth: _fetchNextMonth,
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    return HomeScreenActions.onScrollNotification(
      notification: notification,
      isArchiveVisible: _isArchiveVisible,
      archiveTriggerKey: _archiveTriggerKey,
      hideArchive: _hideArchive,
    );
  }

  Future<void> _fetchNextMonth() {
    return HomeScreenActions.fetchNextMonth(
      isLoadingMore: _isLoadingMore,
      nextArchiveIndex: _nextArchiveIndex,
      allArchiveGroups: _allArchiveGroups,
      isMounted: () => mounted,
      setStateCallback: setState,
      timelineItems: _timelineItems,
      timelineListKey: _timelineListKey,
      setLoadingMore: (value) => _isLoadingMore = value,
      setNextArchiveIndex: (value) => _nextArchiveIndex = value,
    );
  }

  void _revealArchive() {
    HomeScreenActions.revealArchive(
      setStateCallback: setState,
      setArchiveVisible: (value) => _isArchiveVisible = value,
      timelineItems: _timelineItems,
      timelineListKey: _timelineListKey,
      allArchiveGroups: _allArchiveGroups,
      nextArchiveIndex: _nextArchiveIndex,
      setNextArchiveIndex: (value) => _nextArchiveIndex = value,
      scrollController: _scrollController,
      rowBuilder: _timelineRowForItem,
    );
  }

  Future<void> _hideArchive() {
    return HomeScreenActions.hideArchive(
      setStateCallback: setState,
      setArchiveVisible: (value) => _isArchiveVisible = value,
      timelineItems: _timelineItems,
      timelineListKey: _timelineListKey,
      allArchiveGroups: _allArchiveGroups,
      expandedMonths: _expandedMonths,
      setNextArchiveIndex: (value) => _nextArchiveIndex = value,
      rowBuilder: _timelineRowForItem,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadWorkouts();
    }
  }

  Future<void> loadWorkouts() {
    return HomeScreenActions.loadWorkouts(
      mounted: mounted,
      setStateCallback: setState,
      setLoading: (value) => _isLoading = value,
      loadData: WorkoutService.instance.loadData,
    );
  }

  void _applyTimeline(List<Workout> workouts) {
    HomeScreenActions.applyTimeline(
      mounted: mounted,
      logger: _logger,
      workouts: workouts,
      onTimelineReady: (timelineData) {
        if (!mounted) return;
        setState(() {
          _expandedMonths.clear();
          _allArchiveGroups = timelineData.archiveGroups;
          _nextArchiveIndex = 0;
          _isArchiveVisible = false;
          _timelineItems = timelineData.items;
          _timelineListKey = GlobalKey<SliverAnimatedListState>();
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            setState(() {
              _isScrollable = _scrollController.position.maxScrollExtent > 0;
            });
          }
        });
      },
      onFailure: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _openWorkoutDetail(Workout workout) {
    return HomeScreenActions.openWorkoutDetail(
      context: context,
      workout: workout,
      loadWorkouts: loadWorkouts,
    );
  }

  void _toggleMonth(MonthKey key) {
    HomeScreenActions.toggleMonth(
      key: key,
      timelineItems: _timelineItems,
      expandedMonths: _expandedMonths,
      timelineListKey: _timelineListKey,
      setStateCallback: setState,
      rowBuilder: _timelineRowForItem,
    );
  }

  Widget _timelineRowForItem(TimelineListItem item, int index) {
    return HomeScreenTimelineRow(
      item: item,
      index: index,
      archiveTriggerKey: _archiveTriggerKey,
      timelineItems: _timelineItems,
      expandedMonths: _expandedMonths,
      onRevealArchive: _revealArchive,
      onOpenWorkout: _openWorkoutDetail,
      onToggleMonth: _toggleMonth,
      onHideArchive: _hideArchive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePhysics = (_isArchiveVisible || _isScrollable)
        ? const DetentScrollPhysics(parent: AlwaysScrollableScrollPhysics())
        : const ClampingScrollPhysics();

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: CustomScrollView(
          controller: _scrollController,
          physics: effectivePhysics,
          slivers: [
            HomeScreenSliverAppBar(showGreetingTitle: _showGreetingTitle),
            if (_isLoading)
              const HomeScreenLoadingSliver()
            else if (_timelineItems.isEmpty)
              const HomeScreenEmptyStateSliver()
            else
              HomeScreenTimelineSliver(
                timelineListKey: _timelineListKey,
                timelineItems: _timelineItems,
                rowBuilder: _timelineRowForItem,
              ),
            if (_isLoadingMore) const HomeScreenLoadingMoreSliver(),
            const HomeScreenBottomSpacerSliver(),
          ],
        ),
      ),
    );
  }
}
