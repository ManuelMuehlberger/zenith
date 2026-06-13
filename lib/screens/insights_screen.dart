import 'package:flutter/material.dart';
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
  bool _showCalendar = false;
  bool _hasWorkouts = true;
  bool _isCheckingWorkouts = true;
  int _feedRefreshToken = 0;

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
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _refreshPage,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
        child: AdvancedInsightsLauncher(onPressed: _showAdvancedInsights),
      ),
      const SliverToBoxAdapter(child: MainDockSpacer(extraSpace: 20)),
    ];
  }
}
