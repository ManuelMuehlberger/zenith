import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../screens/exercise_browser_screen.dart';
import '../screens/insights/insights_history_mapper.dart';
import '../screens/insights/insights_view_data.dart';
import '../services/insights_service.dart';
import '../services/user_service.dart';
import '../services/workout_service.dart';
import '../utils/unit_converter.dart';
import '../widgets/main_dock_spacer.dart';
import '../widgets/insights/insights_screen_sections.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  bool _showCalendar = false;
  String _selectedTimeframe = '6M';

  // Filters
  String? _selectedWorkoutName;
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  bool? _selectedBodyWeight;
  List<String> _availableWorkoutNames = [];
  bool _hasWorkouts = true;
  bool _isCheckingWorkouts = true;

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
    _loadAvailableWorkouts();
    _checkWorkouts();
    InsightsService.instance.initialize();
    _animationController.forward();
  }

  Future<void> _loadAvailableWorkouts() async {
    final names = await InsightsService.instance.getAvailableWorkoutNames();
    if (mounted) {
      setState(() {
        _availableWorkoutNames = names;
      });
    }
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

  void _onTimeframeChanged(String label, int months) {
    setState(() {
      _selectedTimeframe = label;
    });
  }

  void _onWorkoutFilterChanged(String? workoutName) {
    setState(() {
      _selectedWorkoutName = workoutName;
    });
  }

  void _onMuscleFilterChanged(String? muscleGroup) {
    setState(() {
      _selectedMuscleGroup = muscleGroup;
    });
  }

  void _onEquipmentFilterChanged(String? equipment) {
    setState(() {
      _selectedEquipment = equipment;
    });
  }

  void _onBodyWeightFilterChanged() {
    setState(() {
      _selectedBodyWeight = _selectedBodyWeight == true ? null : true;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedWorkoutName = null;
      _selectedMuscleGroup = null;
      _selectedEquipment = null;
      _selectedBodyWeight = null;
    });
  }

  Future<void> _showExercisePicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseBrowserScreen()),
    );
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
    final filterSnapshot = InsightsFilterSnapshot(
      timeframe: _selectedTimeframe,
      workoutName: _selectedWorkoutName,
      muscleGroup: _selectedMuscleGroup,
      equipment: _selectedEquipment,
      isBodyWeight: _selectedBodyWeight,
    );

    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        return Scaffold(
          body: CustomScrollView(
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
              if (!_showCalendar)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: InsightsFilterHeaderDelegate(
                    timeframeOptions: insightsTimeframeOptions,
                    selectedTimeframe: _selectedTimeframe,
                    selectedWorkoutName: _selectedWorkoutName,
                    selectedMuscleGroup: _selectedMuscleGroup,
                    selectedEquipment: _selectedEquipment,
                    selectedBodyWeight: _selectedBodyWeight,
                    availableWorkoutNames: _availableWorkoutNames,
                    onWorkoutChanged: _onWorkoutFilterChanged,
                    onMuscleChanged: _onMuscleFilterChanged,
                    onEquipmentChanged: _onEquipmentFilterChanged,
                    onBodyWeightChanged: _onBodyWeightFilterChanged,
                    onClearAll: _clearAllFilters,
                    onTimeframeChanged: _onTimeframeChanged,
                  ),
                ),
              ..._buildMainContent(filterSnapshot),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMainContent(InsightsFilterSnapshot filterSnapshot) {
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
        : _buildInsightsSlivers(filterSnapshot);
  }

  List<Widget> _buildInsightsSlivers(InsightsFilterSnapshot filterSnapshot) {
    if (_isCheckingWorkouts) {
      return const [InsightsLoadingSliver()];
    }

    if (!_hasWorkouts) {
      return [InsightsEmptyStateSliver(fadeAnimation: _fadeAnimation)];
    }

    return [
      SliverToBoxAdapter(
        child: InsightsGraphCardsGrid(filters: filterSnapshot),
      ),
      SliverToBoxAdapter(
        child: InsightsQuickActionsCard(onBrowseExercises: _showExercisePicker),
      ),
      SliverToBoxAdapter(
        child: InsightsTrendsSection(
          filters: filterSnapshot,
          weightUnitLabel: _getWeightUnitLabel(),
        ),
      ),
      SliverToBoxAdapter(child: MainDockSpacer(extraSpace: 20)),
    ];
  }

  String _getWeightUnitLabel() {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    return UnitConverter.getWeightUnit(units.name);
  }
}
