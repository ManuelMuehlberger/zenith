import 'dart:async';

import 'package:flutter/material.dart';
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
  final Logger _logger = Logger('HomeScreen');
  HomeOverviewData _overview = HomeOverviewAssembler.build(const []);
  List<TimelineListItem> _timelineItems = const [];
  GlobalKey<SliverAnimatedListState> _timelineListKey =
      GlobalKey<SliverAnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _showGreetingTitle = true;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
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
    );
  }
}
