import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../models/workout.dart';
import '../services/workout_service.dart';
import '../widgets/home/home_screen_actions.dart';
import '../widgets/home/home_screen_body_slivers.dart';
import '../widgets/home/home_screen_overview_sliver.dart';
import '../widgets/home/home_screen_sliver_app_bar.dart';
import '../widgets/home/home_screen_timeline_row.dart';
import '../widgets/home/home_screen_timeline_sliver.dart';
import '../widgets/timeline/timeline_list_item.dart';
import 'home/home_timeline_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const double _historyDetentThreshold = 30.0;

  final Logger _logger = Logger('HomeScreen');
  HomeOverviewData _overview = HomeOverviewAssembler.build(const []);
  List<TimelineListItem> _timelineItems = const [];
  GlobalKey<SliverAnimatedListState> _timelineListKey =
      GlobalKey<SliverAnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _showGreetingTitle = true;
  double _scrollOffset = 0;
  double _historyPullDistance = 0;
  bool _historyDetentArmed = false;
  bool _historyDetentPrimed = false;
  bool _historyDetentOpening = false;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScroll);
    WorkoutService.instance.addListener(_handleWorkoutServiceChanged);
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
    _scrollController.removeListener(_handleScroll);
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

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
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
          _overview = timelineData.overview;
          _timelineItems = timelineData.items;
          _timelineListKey = GlobalKey<SliverAnimatedListState>();
          _isLoading = false;
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

  Future<void> _openWorkoutHistory() {
    return HomeScreenActions.openWorkoutHistory(
      context: context,
      loadWorkouts: loadWorkouts,
    );
  }

  Future<void> _openWorkoutHistoryFromDetent() async {
    if (_historyDetentOpening) {
      return;
    }

    setState(() {
      _historyDetentOpening = true;
      _historyDetentArmed = true;
      _historyPullDistance = _historyDetentThreshold;
    });
    unawaited(HapticFeedback.heavyImpact());
    await Future<void>.delayed(const Duration(milliseconds: 150));

    if (!mounted) {
      return;
    }

    try {
      await _openWorkoutHistory();
    } finally {
      if (mounted) {
        setState(() {
          _historyDetentOpening = false;
          _historyDetentArmed = false;
          _historyDetentPrimed = false;
          _historyPullDistance = 0;
        });
      }
    }
  }

  Future<void> _startWorkout(Workout workout) {
    return HomeScreenActions.startWorkout(
      context: context,
      workout: workout,
      loadWorkouts: loadWorkouts,
    );
  }

  void _openWorkoutBuilder() {
    HomeScreenActions.openWorkoutBuilder();
  }

  Widget _timelineRowForItem(TimelineListItem item, int index) {
    return HomeScreenTimelineRow(
      item: item,
      index: index,
      timelineItems: _timelineItems,
      onOpenWorkout: _openWorkoutDetail,
      onOpenHistory: _openWorkoutHistory,
      lineHighlightProgress: _timelineGlowForIndex(index),
      historyPullProgress: _historyPullProgress,
      historyDetentArmed: _historyDetentArmed,
    );
  }

  double _timelineGlowForIndex(int index) {
    return _timelineGlowForIndexAtOffset(index, _scrollOffset);
  }

  double get _historyPullProgress {
    return (_historyPullDistance / _historyDetentThreshold).clamp(0.0, 1.0);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_timelineItems.isEmpty || _historyDetentOpening) {
      return false;
    }

    final metrics = notification.metrics;
    final hasLongScroll = metrics.maxScrollExtent > 320;
    final isHistoryDetentReady =
        hasLongScroll &&
        _timelineGlowForIndex(_timelineItems.length - 1) > 0.64;
    final isAtBottom = metrics.extentAfter <= 2.0;
    final bottomOverscroll = (metrics.pixels - metrics.maxScrollExtent).clamp(
      0.0,
      double.infinity,
    );
    final pullDelta = notification is ScrollUpdateNotification
        ? (-(notification.dragDetails?.delta.dy ?? 0)).clamp(
            0.0,
            double.infinity,
          )
        : 0.0;
    final overscrollDelta = notification is OverscrollNotification
        ? notification.overscroll.clamp(0.0, double.infinity)
        : 0.0;
    final effectivePull = isAtBottom && isHistoryDetentReady
        ? (_historyPullDistance + pullDelta + overscrollDelta).clamp(
            0.0,
            _historyDetentThreshold,
          )
        : bottomOverscroll;

    if ((effectivePull > 0 || bottomOverscroll > 0) && isHistoryDetentReady) {
      final wasArmed = _historyDetentArmed;
      final isArmed = effectivePull >= _historyDetentThreshold;
      setState(() {
        _historyPullDistance = effectivePull;
        _historyDetentArmed = isArmed;
      });

      if (!wasArmed && isArmed) {
        unawaited(HapticFeedback.mediumImpact());
        unawaited(_openWorkoutHistoryFromDetent());
      } else if (!isArmed &&
          !_historyDetentPrimed &&
          _historyPullProgress > 0.55) {
        _historyDetentPrimed = true;
        unawaited(HapticFeedback.selectionClick());
      }

      return false;
    }

    if (bottomOverscroll > 0 && !isHistoryDetentReady) {
      return false;
    }

    if (notification is ScrollEndNotification ||
        notification is UserScrollNotification) {
      if (_historyPullDistance > 0 || _historyDetentArmed) {
        setState(() {
          _historyPullDistance = 0;
          _historyDetentArmed = false;
          _historyDetentPrimed = false;
        });
      }
    }

    return false;
  }

  double _timelineGlowForIndexAtOffset(int index, double offset) {
    final progress = ((offset - 250) / 220) - (index * 0.1);
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const _HomeHistoryDetentPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            HomeScreenSliverAppBar(showGreetingTitle: _showGreetingTitle),
            if (_isLoading)
              const HomeScreenLoadingSliver()
            else ...[
              HomeScreenOverviewSliver(
                overview: _overview,
                onStartWorkout: _startWorkout,
                onOpenWorkoutBuilder: _openWorkoutBuilder,
              ),
              if (_timelineItems.isEmpty)
                const HomeScreenEmptyStateSliver()
              else ...[
                const HomeScreenRecentActivityHeaderSliver(),
                HomeScreenTimelineSliver(
                  timelineListKey: _timelineListKey,
                  timelineItems: _timelineItems,
                  rowBuilder: _timelineRowForItem,
                ),
              ],
            ],
            const HomeScreenBottomSpacerSliver(),
          ],
        ),
      ),
    );
  }
}

class _HomeHistoryDetentPhysics extends BouncingScrollPhysics {
  const _HomeHistoryDetentPhysics({super.parent});

  @override
  _HomeHistoryDetentPhysics applyTo(ScrollPhysics? ancestor) {
    return _HomeHistoryDetentPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (position.pixels > position.maxScrollExtent && offset < 0) {
      final overscroll = position.pixels - position.maxScrollExtent;
      if (overscroll > HomeScreenState._historyDetentThreshold) {
        return offset * 0.16;
      }
      if (overscroll > HomeScreenState._historyDetentThreshold * 0.62) {
        return offset * 0.5;
      }
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }
}
