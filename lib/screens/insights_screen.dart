import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/advanced_insights_screen.dart';
import '../screens/insights/insights_history_mapper.dart';
import '../screens/insights/insights_view_data.dart';
import '../services/insights/insight_feed_service.dart';
import '../services/insights_service.dart';
import '../services/user_service.dart';
import '../services/workout_service.dart';
import '../widgets/insights/insight_feed_section.dart';
import '../widgets/insights/insights_screen_sections.dart';
import '../widgets/main_dock_spacer.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  static const double _advancedInsightsDetentThreshold = 30.0;

  final ScrollController _scrollController = ScrollController();
  bool _showCalendar = false;
  bool _hasWorkouts = true;
  bool _isCheckingWorkouts = true;
  int _feedRefreshToken = 0;
  double _scrollOffset = 0;
  double _advancedInsightsPullDistance = 0;
  bool _advancedInsightsDetentArmed = false;
  bool _advancedInsightsDetentPrimed = false;
  bool _advancedInsightsDetentOpening = false;

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<DateTime> _workoutDates = [];
  List<WorkoutDisplayItem> _selectedDateWorkoutItems = [];
  bool _isLoadingCalendar = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollChanged);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _checkWorkouts();
    InsightsService.instance.initialize();
    _animationController.forward();
  }

  Future<void> _checkWorkouts() async {
    final workouts = await InsightsService.instance.getWorkouts();
    if (mounted) {
      setState(() {
        _hasWorkouts = workouts.isNotEmpty;
        _isCheckingWorkouts = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollChanged);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleScrollChanged() {
    if (!mounted) {
      return;
    }
    final position = _scrollController.position;
    final shouldResetDetent =
        position.extentAfter > 2 &&
        (_advancedInsightsPullDistance > 0 || _advancedInsightsDetentArmed);
    setState(() {
      _scrollOffset = _scrollController.offset;
      if (shouldResetDetent) {
        _advancedInsightsPullDistance = 0;
        _advancedInsightsDetentArmed = false;
        _advancedInsightsDetentPrimed = false;
      }
    });
  }

  double get _advancedInsightsPullProgress {
    return (_advancedInsightsPullDistance / _advancedInsightsDetentThreshold)
        .clamp(0.0, 1.0);
  }

  double get _advancedInsightsGlowProgress {
    return _advancedInsightsGlowProgressAtOffset(_scrollOffset);
  }

  double _advancedInsightsGlowProgressAtOffset(double offset) {
    final progress = (offset - 250) / 220;
    return progress.clamp(0.0, 1.0);
  }

  void _resetAdvancedInsightsDetent() {
    if (_advancedInsightsPullDistance > 0 || _advancedInsightsDetentArmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _advancedInsightsPullDistance = 0;
          _advancedInsightsDetentArmed = false;
          _advancedInsightsDetentPrimed = false;
        });
      });
    }
  }

  void _scheduleAdvancedInsightsDetentUpdate({
    required double pullDistance,
    required bool isArmed,
    required bool shouldOpen,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _advancedInsightsDetentOpening) {
        return;
      }

      setState(() {
        _advancedInsightsPullDistance = pullDistance;
        _advancedInsightsDetentArmed = isArmed;
      });

      if (shouldOpen) {
        unawaited(HapticFeedback.mediumImpact());
        unawaited(_showAdvancedInsightsFromDetent());
      }
    });
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoadingCalendar = true;
    });
    try {
      final dates = await WorkoutService.instance.getDatesWithWorkouts();
      final histories = await WorkoutService.instance.getWorkoutsForDate(
        _selectedDate,
      );
      final displayItems = InsightsHistoryMapper.buildDisplayItems(histories);

      if (mounted) {
        setState(() {
          _workoutDates = dates;
          _selectedDateWorkoutItems = displayItems;
          _isLoadingCalendar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCalendar = false;
          _workoutDates = [];
          _selectedDateWorkoutItems = [];
        });
      }
    }
  }

  Future<void> _showAdvancedInsights() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdvancedInsightsScreen()),
    );
  }

  Future<void> _showAdvancedInsightsFromDetent() async {
    if (_advancedInsightsDetentOpening) {
      return;
    }

    setState(() {
      _advancedInsightsDetentOpening = true;
      _advancedInsightsDetentArmed = true;
      _advancedInsightsPullDistance = _advancedInsightsDetentThreshold;
    });
    unawaited(HapticFeedback.heavyImpact());
    await Future<void>.delayed(const Duration(milliseconds: 150));

    if (!mounted) {
      return;
    }

    try {
      await _showAdvancedInsights();
    } finally {
      if (mounted) {
        setState(() {
          _advancedInsightsDetentOpening = false;
          _advancedInsightsDetentArmed = false;
          _advancedInsightsDetentPrimed = false;
          _advancedInsightsPullDistance = 0;
        });
      }
    }
  }

  Future<void> _refreshPage() async {
    await Future.wait([
      InsightsService.instance.clearCache(),
      InsightFeedService.instance.invalidateCache(),
    ]);

    await _checkWorkouts();

    if (_showCalendar) {
      await _loadCalendarData();
    }

    if (mounted) {
      setState(() {
        _feedRefreshToken++;
      });
    }
  }

  Future<void> _loadWorkoutsForSelectedDate() async {
    setState(() {
      _isLoadingCalendar = true;
    });
    try {
      final histories = await WorkoutService.instance.getWorkoutsForDate(
        _selectedDate,
      );
      final displayItems = InsightsHistoryMapper.buildDisplayItems(histories);
      if (mounted) {
        setState(() {
          _selectedDateWorkoutItems = displayItems;
          _isLoadingCalendar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedDateWorkoutItems = [];
          _isLoadingCalendar = false;
        });
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadWorkoutsForSelectedDate();
  }

  void _onMonthChanged(DateTime newFocusedDate) {
    setState(() {
      _focusedDate = newFocusedDate;
      if (_selectedDate.month != _focusedDate.month ||
          _selectedDate.year != _focusedDate.year) {
        _selectedDate = DateTime(_focusedDate.year, _focusedDate.month, 1);
      }
    });
    _loadWorkoutsForSelectedDate();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_showCalendar || !_hasWorkouts || _advancedInsightsDetentOpening) {
      return false;
    }

    final metrics = notification.metrics;
    final hasLongScroll = metrics.maxScrollExtent > 320;
    final isAdvancedInsightsDetentReady =
        hasLongScroll && _advancedInsightsGlowProgress > 0.64;
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
    final effectivePull = isAtBottom && isAdvancedInsightsDetentReady
        ? (_advancedInsightsPullDistance + pullDelta + overscrollDelta).clamp(
            0.0,
            _advancedInsightsDetentThreshold,
          )
        : bottomOverscroll;

    if ((effectivePull > 0 || bottomOverscroll > 0) &&
        isAdvancedInsightsDetentReady) {
      final wasArmed = _advancedInsightsDetentArmed;
      final isArmed = effectivePull >= _advancedInsightsDetentThreshold;
      final shouldOpen = !wasArmed && isArmed;

      _scheduleAdvancedInsightsDetentUpdate(
        pullDistance: effectivePull,
        isArmed: isArmed,
        shouldOpen: shouldOpen,
      );

      if (!shouldOpen &&
          !isArmed &&
          !_advancedInsightsDetentPrimed &&
          _advancedInsightsPullProgress > 0.55) {
        _advancedInsightsDetentPrimed = true;
        unawaited(HapticFeedback.selectionClick());
      }

      return false;
    }

    if (bottomOverscroll > 0 && !isAdvancedInsightsDetentReady) {
      return false;
    }

    if (notification is ScrollEndNotification ||
        notification is UserScrollNotification) {
      _resetAdvancedInsightsDetent();
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        return Scaffold(
          body: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: RefreshIndicator(
              onRefresh: _refreshPage,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const _InsightsAdvancedDetentPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  InsightsAppBar(
                    showCalendar: _showCalendar,
                    onShowCalendar: () {
                      setState(() {
                        _showCalendar = true;
                      });
                      _loadCalendarData();
                    },
                    onHideCalendar: () {
                      setState(() {
                        _showCalendar = false;
                      });
                    },
                  ),
                  ..._buildMainContent(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildMainContent() {
    return _showCalendar
        ? InsightsCalendarSlivers.build(
            isLoading: _isLoadingCalendar,
            selectedDate: _selectedDate,
            focusedDate: _focusedDate,
            workoutDates: _workoutDates,
            selectedDateWorkoutItems: _selectedDateWorkoutItems,
            onDateSelected: _onDateSelected,
            onMonthChanged: _onMonthChanged,
          )
        : _buildInsightsSlivers();
  }

  List<Widget> _buildInsightsSlivers() {
    if (_isCheckingWorkouts) {
      return const [InsightsLoadingSliver()];
    }

    if (!_hasWorkouts) {
      return [InsightsEmptyStateSliver(fadeAnimation: _fadeAnimation)];
    }

    return [
      SliverToBoxAdapter(
        child: InsightsFeedSection(refreshToken: _feedRefreshToken),
      ),
      SliverToBoxAdapter(
        child: AdvancedInsightsLauncher(
          onPressed: _showAdvancedInsights,
          pullProgress: _advancedInsightsPullProgress,
          detentArmed: _advancedInsightsDetentArmed,
          glowProgress: _advancedInsightsGlowProgress,
        ),
      ),
      const SliverToBoxAdapter(child: MainDockSpacer(extraSpace: 20)),
    ];
  }
}

class _InsightsAdvancedDetentPhysics extends BouncingScrollPhysics {
  const _InsightsAdvancedDetentPhysics({super.parent});

  @override
  _InsightsAdvancedDetentPhysics applyTo(ScrollPhysics? ancestor) {
    return _InsightsAdvancedDetentPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (position.pixels > position.maxScrollExtent && offset < 0) {
      final overscroll = position.pixels - position.maxScrollExtent;
      if (overscroll > _InsightsScreenState._advancedInsightsDetentThreshold) {
        return offset * 0.16;
      }
      if (overscroll >
          _InsightsScreenState._advancedInsightsDetentThreshold * 0.62) {
        return offset * 0.5;
      }
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }
}
