import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:pull_down_button/pull_down_button.dart';
import '../services/database_service.dart';
import '../services/insights_service.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../screens/exercise_browser_screen.dart';
import '../widgets/shared_calendar_view.dart';
import '../widgets/dated_workout_list_view.dart';
import '../utils/unit_converter.dart';
import '../services/user_service.dart';
import '../constants/app_constants.dart';
import '../widgets/profile_icon_button.dart';
import '../widgets/insights/small_bar_card.dart';
import '../widgets/workout_stats_card.dart';
import '../widgets/insights/large_trend_card.dart';
import '../services/insights/workout_trend_provider.dart';
import '../services/insights/workout_insights_provider.dart';

// Helper class to combine Workout with its original Workout details
class WorkoutDisplayItem {
  final Workout workout;
  final Workout? workoutDetails;

  WorkoutDisplayItem({required this.workout, this.workoutDetails});
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  bool _showCalendar = false;
  int _selectedMonthsBack = 6;
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

  final List<Map<String, dynamic>> _timeframeOptions = [
    {'label': '1W', 'months': 0}, // Special case for 1 week
    {'label': '1M', 'months': 1},
    {'label': '3M', 'months': 3},
    {'label': '6M', 'months': 6},
    {'label': '1Y', 'months': 12},
    {'label': '2Y', 'months': 24},
    {'label': 'All', 'months': 999},
  ];

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

  void _fetchWorkoutDetailsForHistorySync(List<Workout> workouts) {
    List<WorkoutDisplayItem> displayItems = [];
    for (var workout in workouts) {
      Workout? details;
      try {
        if (workout.templateId != null) {
          details = WorkoutService.instance.getWorkoutById(workout.templateId!);
        }
      } catch (e) {
        // Silently handle error
      }
      displayItems.add(WorkoutDisplayItem(workout: workout, workoutDetails: details));
    }
    setState(() {
      _selectedDateWorkoutItems = displayItems;
    });
  }

  Future<void> _loadCalendarData() async {
    setState(() { _isLoadingCalendar = true; });
    try {
      final dates = await DatabaseService.instance.getDatesWithWorkouts();
      final histories = await DatabaseService.instance.getWorkoutsForDate(_selectedDate);
      _fetchWorkoutDetailsForHistorySync(histories);
      
      if (mounted) {
        setState(() {
          _workoutDates = dates;
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
      _selectedMonthsBack = months;
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseBrowserScreen()),
    );
  }

  Future<void> _loadWorkoutsForSelectedDate() async {
    setState(() { _isLoadingCalendar = true; });
    try {
      final histories = await DatabaseService.instance.getWorkoutsForDate(_selectedDate);
      _fetchWorkoutDetailsForHistorySync(histories);
      if (mounted) {
        setState(() { _isLoadingCalendar = false; });
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
    setState(() { _selectedDate = date; });
    _loadWorkoutsForSelectedDate();
  }

  void _onMonthChanged(DateTime newFocusedDate) {
    setState(() {
      _focusedDate = newFocusedDate;
      if (_selectedDate.month != _focusedDate.month || _selectedDate.year != _focusedDate.year) {
        _selectedDate = DateTime(_focusedDate.year, _focusedDate.month, 1);
      }
    });
    _loadWorkoutsForSelectedDate();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle smallTitleStyle = AppConstants.HEADER_SMALL_TITLE_TEXT_STYLE.copyWith(fontSize: 20.0);

    // The small title widget, used in the collapsed app bar
    final Widget smallTitle = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showCalendar
          ? Text(
              'Calendar',
              key: const ValueKey('calendar_title'),
              textAlign: TextAlign.center,
              style: smallTitleStyle,
            )
          : Text(
              'Insights',
              key: const ValueKey('insights_title'),
              textAlign: TextAlign.center,
              style: smallTitleStyle,
            ),
    );

    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                centerTitle: true,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: AppConstants.HEADER_EXTRA_HEIGHT + kToolbarHeight,
                leading: _showCalendar
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 24),
                        onPressed: () {
                          setState(() {
                            _showCalendar = false;
                          });
                        },
                      )
                    : GestureDetector(
                        onTap: () {
                          setState(() { _showCalendar = true; });
                          _loadCalendarData();
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(left: 16),
                          decoration: BoxDecoration(
                            color: AppConstants.ACCENT_COLOR.withAlpha((255 * 0.2).round()),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.calendar,
                            color: AppConstants.ACCENT_COLOR,
                            size: 20,
                          ),
                        ),
                      ),
                actions: [
                  if (!_showCalendar)
                    const ProfileIconButton()
                  else
                    const SizedBox(width: 48), // Match the leading width when showing back button
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Persistent glass effect layer
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
                          title: smallTitle,
                          background: Container(), // We are not using a background title
                          collapseMode: CollapseMode.parallax,
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Timeframe selector and filters (only show when not in calendar view)
              if (!_showCalendar)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TimeframeSelectorDelegate(
                    timeframeOptions: _timeframeOptions,
                    selectedTimeframe: _selectedTimeframe,
                    onTimeframeChanged: _onTimeframeChanged,
                    filters: _buildFilterWidgets(),
                  ),
                ),

              // Main content
              ..._buildMainContent(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFilterWidgets() {
    final muscleGroups = AppMuscleGroup.values
        .where((group) => group != AppMuscleGroup.na)
        .map((group) => group.displayName)
        .toList();
    
    final equipmentList = EquipmentType.values
        .map((equipment) => equipment.displayName)
        .toList();

    final bool hasAnyFilter = _selectedWorkoutName != null ||
        _selectedMuscleGroup != null ||
        _selectedEquipment != null ||
        _selectedBodyWeight != null;

    final filters = [
      // Workout Filter
      _buildFilterTag(
        context: context,
        title: 'Workout',
        isSelected: _selectedWorkoutName != null,
        items: _availableWorkoutNames,
        onItemSelected: (val) => _onWorkoutFilterChanged(val == _selectedWorkoutName ? null : val),
        selectedItem: _selectedWorkoutName,
      ),
      const SizedBox(width: 8),
      // Muscle Filter
      _buildFilterTag(
        context: context,
        title: 'Muscle',
        isSelected: _selectedMuscleGroup != null,
        items: muscleGroups,
        onItemSelected: (val) => _onMuscleFilterChanged(val == _selectedMuscleGroup ? null : val),
        selectedItem: _selectedMuscleGroup,
      ),
      const SizedBox(width: 8),
      // Equipment Filter
      _buildFilterTag(
        context: context,
        title: 'Equipment',
        isSelected: _selectedEquipment != null,
        items: equipmentList,
        onItemSelected: (val) => _onEquipmentFilterChanged(val == _selectedEquipment ? null : val),
        selectedItem: _selectedEquipment,
      ),
      const SizedBox(width: 8),
      // Bodyweight Filter
      _buildBodyweightTag(
        context: context,
        isSelected: _selectedBodyWeight == true,
      ),
    ];

    if (hasAnyFilter) {
      return [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _clearAllFilters,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppConstants.WORKOUT_BUTTON_BG_COLOR,
              shape: BoxShape.circle,
              border: Border.all(color: AppConstants.DIVIDER_COLOR, width: 0.5),
            ),
            child: const Icon(
              CupertinoIcons.xmark,
              size: 16,
              color: AppConstants.TEXT_SECONDARY_COLOR,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ...filters,
      ];
    }

    return filters;
  }

  Widget _buildFilterTag({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required List<String> items,
    required Function(String) onItemSelected,
    required String? selectedItem,
  }) {
    return PullDownButton(
      itemBuilder: (context) => items
          .map((item) => PullDownMenuItem.selectable(
                title: item,
                selected: selectedItem == item,
                onTap: () => onItemSelected(item),
              ))
          .toList(),
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: showMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.ACCENT_COLOR : AppConstants.WORKOUT_BUTTON_BG_COLOR,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isSelected ? AppConstants.ACCENT_COLOR : AppConstants.DIVIDER_COLOR,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSelected ? selectedItem! : title,
                style: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(
                  color: isSelected ? Colors.white : AppConstants.TEXT_SECONDARY_COLOR,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_down,
                size: 12,
                color: isSelected ? Colors.white : AppConstants.TEXT_SECONDARY_COLOR,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyweightTag({
    required BuildContext context,
    required bool isSelected,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _onBodyWeightFilterChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.ACCENT_COLOR : AppConstants.WORKOUT_BUTTON_BG_COLOR,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? AppConstants.ACCENT_COLOR : AppConstants.DIVIDER_COLOR,
            width: 0.5,
          ),
        ),
        child: Text(
          'Bodyweight',
          style: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(
            color: isSelected ? Colors.white : AppConstants.TEXT_SECONDARY_COLOR,
            fontWeight: isSelected ? FontWeight.w600 : null,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMainContent() {
    return _showCalendar ? _buildCalendarSlivers() : _buildInsightsSlivers();
  }

  List<Widget> _buildInsightsSlivers() {
    if (_isCheckingWorkouts) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: CupertinoActivityIndicator(radius: 14),
            ),
          ),
        ),
      ];
    }

    if (!_hasWorkouts) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppConstants.WORKOUT_BUTTON_BG_COLOR,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        CupertinoIcons.chart_bar_fill,
                        size: 40,
                        color: AppConstants.TEXT_TERTIARY_COLOR,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Activity Data',
                      style: AppConstants.IOS_TITLE_TEXT_STYLE,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete workouts to see your insights',
                      style: AppConstants.IOS_SUBTITLE_TEXT_STYLE,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      // Graph Cards Grid
      SliverToBoxAdapter(
        child: _buildGraphCardsGrid(),
      ),
      
      // Quick Actions
      SliverToBoxAdapter(
        child: _buildQuickActions(),
      ),

      // Trends Section
      SliverToBoxAdapter(
        child: _buildTrendsSection(),
      ),

      // Bottom spacer
      SliverToBoxAdapter(
        child: SizedBox(
          height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 20,
        ),
      ),
    ];
  }

  Widget _buildGraphCardsGrid() {
    final filters = {
      'workoutName': _selectedWorkoutName,
      'muscleGroup': _selectedMuscleGroup,
      'equipment': _selectedEquipment,
      'isBodyWeight': _selectedBodyWeight,
      'timeframe': _selectedTimeframe,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12.0,
        crossAxisSpacing: 12.0,
        childAspectRatio: 1.0,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          WeeklyTrendCard(
            title: 'Workouts',
            icon: CupertinoIcons.flame_fill,
            color: AppConstants.ACCENT_COLOR_ORANGE,
            unit: 'workouts',
            provider: WorkoutTrendProvider(WorkoutTrendType.count),
            filters: filters,
            mainValueBuilder: (data) {
               if (data.isEmpty) return "0.0";
               final total = data.fold(0.0, (sum, e) => sum + e.value);
               return (total / data.length).toStringAsFixed(1);
            },
            subLabelBuilder: (data) => 'Avg / Week',
          ),
          WeeklyTrendCard(
            title: 'Duration',
            icon: CupertinoIcons.clock_fill,
            color: AppConstants.ACCENT_COLOR,
            unit: 'min',
            provider: WorkoutTrendProvider(WorkoutTrendType.duration),
            filters: filters,
            mainValueBuilder: (data) {
               if (data.isEmpty) return "0m";
               double totalDurationMins = 0;
               int totalWorkouts = 0;
               for (var d in data) {
                 totalDurationMins += d.value * 60;
                 totalWorkouts += d.count ?? 0;
               }
               if (totalWorkouts == 0) return "0m";
               return '${(totalDurationMins / totalWorkouts).toStringAsFixed(0)}m';
            },
            subLabelBuilder: (data) => 'Avg / Workout',
          ),
          WeeklyTrendCard(
            title: 'Volume',
            icon: CupertinoIcons.layers_fill,
            color: AppConstants.ACCENT_COLOR_GREEN,
            unit: 'sets',
            provider: WorkoutTrendProvider(WorkoutTrendType.sets),
            filters: filters,
            mainValueBuilder: (data) {
               if (data.isEmpty) return "0";
               double totalSets = 0;
               int totalWorkouts = 0;
               for (var d in data) {
                 totalSets += d.value;
                 totalWorkouts += d.count ?? 0;
               }
               if (totalWorkouts == 0) return "0";
               return (totalSets / totalWorkouts).toStringAsFixed(0);
            },
            subLabelBuilder: (data) => 'Avg Sets / Workout',
          ),
          WorkoutStatsCard(
            provider: WorkoutInsightsProvider(),
            filters: filters,
          ),
        ],
      ),
    );
  }


  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      child: GestureDetector(
        onTap: _showExercisePicker,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.ACCENT_COLOR_GREEN.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.search,
                  color: AppConstants.ACCENT_COLOR_GREEN,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Browse Exercises',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(
                CupertinoIcons.chevron_right,
                color: AppConstants.TEXT_TERTIARY_COLOR,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendsSection() {
    final filters = {
      'workoutName': _selectedWorkoutName,
      'muscleGroup': _selectedMuscleGroup,
      'equipment': _selectedEquipment,
      'isBodyWeight': _selectedBodyWeight,
      'timeframe': _selectedTimeframe,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trends',
            style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
              color: AppConstants.TEXT_TERTIARY_COLOR,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          TrendInsightCard(
            title: 'Workouts',
            color: AppConstants.ACCENT_COLOR_ORANGE,
            unit: 'workouts',
            icon: CupertinoIcons.flame_fill,
            filters: filters,
            provider: WorkoutTrendProvider(WorkoutTrendType.count),
          ),
          const SizedBox(height: 12),
          TrendInsightCard(
            title: 'Hours',
            color: AppConstants.ACCENT_COLOR,
            unit: 'hours',
            icon: CupertinoIcons.clock_fill,
            filters: filters,
            provider: WorkoutTrendProvider(WorkoutTrendType.duration),
          ),
          const SizedBox(height: 12),
          TrendInsightCard(
            title: 'Weight Lifted',
            color: AppConstants.ACCENT_COLOR_GREEN,
            unit: _getWeightUnitLabel(),
            icon: CupertinoIcons.chart_bar_square_fill,
            filters: filters,
            provider: WorkoutTrendProvider(WorkoutTrendType.volume),
          ),
        ],
      ),
    );
  }

  String _getWeightUnitLabel() {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    return UnitConverter.getWeightUnit(units.name);
  }

  List<Widget> _buildCalendarSlivers() {
    if (_isLoadingCalendar) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: CupertinoActivityIndicator(radius: 14),
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          decoration: BoxDecoration(
            color: AppConstants.CARD_BG_COLOR,
            borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
            border: Border.all(
              color: AppConstants.DIVIDER_COLOR,
              width: 0.5,
            ),
          ),
          child: SharedCalendarView(
            selectedDate: _selectedDate,
            focusedDate: _focusedDate,
            workoutDates: _workoutDates,
            onDateSelected: _onDateSelected,
            onMonthChanged: _onMonthChanged,
          ),
        ),
      ),
      SliverFillRemaining(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: DatedWorkoutListView(
            selectedDate: _selectedDate,
            workouts: _selectedDateWorkoutItems.map((item) => item.workout).toList(),
            isLoading: _isLoadingCalendar,
          ),
        ),
      ),
    ];
  }
}

// Custom delegate for the timeframe selector header
class _TimeframeSelectorDelegate extends SliverPersistentHeaderDelegate {
  final List<Map<String, dynamic>> timeframeOptions;
  final String selectedTimeframe;
  final Function(String, int) onTimeframeChanged;
  final List<Widget> filters;

  _TimeframeSelectorDelegate({
    required this.timeframeOptions,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
    required this.filters,
  });

  @override
  double get minExtent => 52.0; // 36 (selector) + 16 (padding)

  @override
  double get maxExtent => 52.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppConstants.GLASS_BLUR_SIGMA,
          sigmaY: AppConstants.GLASS_BLUR_SIGMA,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppConstants.HEADER_BG_COLOR_STRONG,
            border: Border(
              bottom: BorderSide(
                color: AppConstants.DIVIDER_COLOR,
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: filters,
                ),
              ),
              const SizedBox(width: 8),
              _buildTimeframeDropdown(context),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true; // Important for state changes to reflect in the UI
  }

  Widget _buildTimeframeDropdown(BuildContext context) {
    return PullDownButton(
      itemBuilder: (context) => timeframeOptions
          .map((option) => PullDownMenuItem.selectable(
                title: option['label'],
                selected: selectedTimeframe == option['label'],
                onTap: () => onTimeframeChanged(option['label'], option['months']),
              ))
          .toList(),
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: showMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: AppConstants.WORKOUT_BUTTON_BG_COLOR,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppConstants.DIVIDER_COLOR, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedTimeframe,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: AppConstants.TEXT_SECONDARY_COLOR,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
