import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/database_service.dart';
import '../services/insights_service.dart';
import '../models/workout_history.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../screens/exercise_browser_screen.dart';
import '../widgets/workout_chart.dart';
import '../widgets/shared_calendar_view.dart';
import '../widgets/dated_workout_list_view.dart';
import '../widgets/insights_stat_card.dart';
import '../utils/unit_converter.dart';
import '../services/user_service.dart';
import 'package:intl/intl.dart';

// Helper class to combine WorkoutHistory with its original Workout details
class WorkoutHistoryDisplayItem {
  final WorkoutHistory history;
  final Workout? workoutDetails; // Nullable if workout is somehow not found

  WorkoutHistoryDisplayItem({required this.history, this.workoutDetails});
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> { 
  WorkoutInsights? _insights;
  bool _isLoading = true;
  bool _showCalendar = false;
  int _selectedMonthsBack = 6;
  String _selectedTimeframe = '6 months';
  
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<DateTime> _workoutDates = [];
  List<WorkoutHistoryDisplayItem> _selectedDateWorkoutItems = []; 
  bool _isLoadingCalendar = false;
  

  final List<String> _timeframeOptions = [
    '3 months',
    '6 months',
    '12 months',
    '24 months',
  ];

  @override
  void initState() {
    super.initState();
    _loadInsights();
    InsightsService.instance.initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }


  Future<void> _loadInsights({bool forceRefresh = false}) async {
    setState(() { _isLoading = true; });
    try {
      final insights = await InsightsService.instance.getWorkoutInsights(
        monthsBack: _selectedMonthsBack,
        forceRefresh: forceRefresh,
      );
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading insights: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _fetchWorkoutDetailsForHistorySync(List<WorkoutHistory> histories) {
    List<WorkoutHistoryDisplayItem> displayItems = [];
    for (var history in histories) {
      Workout? details;
      try {
        if (history.workoutId != null) {
          details = WorkoutService.instance.getWorkoutById(history.workoutId!);
        } else {
          details = null;
        }
      } catch (e) {
      }
      displayItems.add(WorkoutHistoryDisplayItem(history: history, workoutDetails: details));
    }
    setState(() {
      _selectedDateWorkoutItems = displayItems;
    });
  }

  Future<void> _loadCalendarData() async {
    setState(() { _isLoadingCalendar = true; });
    try {
      final dates = await DatabaseService.instance.getDatesWithWorkouts();
      final histories = await DatabaseService.instance.getWorkoutHistoryForDate(_selectedDate);
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


  void _showTimeframePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600], borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Select Time Period', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._timeframeOptions.map((option) => ListTile(
                title: Text(option, style: Theme.of(context).textTheme.titleMedium),
                trailing: _selectedTimeframe == option ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  Navigator.pop(context);
                  _onTimeframeChanged(option);
                },
              )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _onTimeframeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedTimeframe = newValue;
        _selectedMonthsBack = _getMonthsFromTimeframe(newValue);
      });
      _loadInsights(forceRefresh: true);
    }
  }

  int _getMonthsFromTimeframe(String timeframe) {
    switch (timeframe) {
      case '3 months': return 3;
      case '6 months': return 6;
      case '12 months': return 12;
      case '24 months': return 24;
      default: return 6;
    }
  }

  String _formatWeight(double weight) {
    final units = UserService.instance.currentProfile?.units ?? 'metric';
    final unitLabel = UnitConverter.getWeightUnit(units);
    final kUnitLabel = units == 'imperial' ? 'k lbs' : 'k kg';

    if (weight > 999) {
      return '${(weight / 1000).toStringAsFixed(1)}$kUnitLabel';
    }
    return '${weight.toStringAsFixed(1)} $unitLabel';
  }

  String _getWeightUnitLabel() {
    final units = UserService.instance.currentProfile?.units ?? 'metric';
    return UnitConverter.getWeightUnit(units);
  }

  Future<void> _showExercisePicker() async {
    Navigator.push(
      context, MaterialPageRoute(builder: (context) => const ExerciseBrowserScreen()),
    );
  }

  Future<void> _loadWorkoutsForSelectedDate() async { 
    setState(() { _isLoadingCalendar = true; }); 
    try {
      final histories = await DatabaseService.instance.getWorkoutHistoryForDate(_selectedDate);
      _fetchWorkoutDetailsForHistorySync(histories); // Use sync version
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
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight;

    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: _buildMainContent(headerHeight),
              ),
              // Glass header overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      height: headerHeight,
                      color: Colors.black54,
                      child: SafeArea(
                        bottom: false,
                        child: _buildHeaderContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderContent() {
    return _showCalendar 
        ? SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showCalendar = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        : SizedBox(
            height: kToolbarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Insights',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: _showTimeframePicker,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedTimeframe, style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildMainContent(double headerHeight) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showCalendar ? _buildCalendarView(headerHeight) : _buildInsightsView(headerHeight),
    );
  }

  Widget _buildInsightsView(double headerHeight) {
    if (_isLoading) {
      return Column(
        children: [
          SizedBox(height: headerHeight),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),
        ],
      );
    }

    if (_insights == null) {
      return Column(
        children: [
          SizedBox(height: headerHeight),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text('No workout data available', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Complete some workouts to see your insights', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadInsights(forceRefresh: true),
      color: Colors.blue,
      backgroundColor: Colors.grey[900],
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Space for header
          SliverToBoxAdapter(
            child: SizedBox(height: headerHeight),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() { _showCalendar = true; });
                            _loadCalendarData(); 
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Calendar', style: Theme.of(context).textTheme.labelLarge),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showExercisePicker,
                          icon: const Icon(Icons.fitness_center),
                          label: Text('Exercises', style: Theme.of(context).textTheme.labelLarge),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: InsightsStatCard(title: 'Total Workouts', value: _insights!.totalWorkouts.toString(), icon: Icons.fitness_center, color: Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: InsightsStatCard(title: 'Total Hours', value: _insights!.totalHours.toStringAsFixed(1), icon: Icons.timer, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InsightsStatCard(title: 'Total Weight Lifted', value: _formatWeight(_insights!.totalWeight), icon: Icons.monitor_weight, color: Colors.orange),
                  const SizedBox(height: 24),
                  Text('Trends over $_selectedTimeframe', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  WorkoutChart(title: 'Workouts per Month', data: _insights!.monthlyWorkouts, color: Colors.blue, unit: 'workouts'),
                  const SizedBox(height: 16),
                  WorkoutChart(title: 'Hours per Month', data: _insights!.monthlyHours, color: Colors.green, unit: 'hours'),
                  const SizedBox(height: 16),
                  WorkoutChart(title: 'Weight Lifted per Month (${_getWeightUnitLabel()})', data: _insights!.monthlyWeight, color: Colors.orange, unit: _getWeightUnitLabel()),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Averages', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Workout Duration', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                                const SizedBox(height: 4),
                                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('${_insights!.averageWorkoutDuration.toStringAsFixed(1)}h', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                              ]),
                            ),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Weight per Workout', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                                const SizedBox(height: 4),
                                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(_formatWeight(_insights!.averageWeightPerWorkout), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text('Last updated: ${DateFormat('dd/MM/yyyy HH:mm').format(_insights!.lastUpdated)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(double headerHeight) {
    if (_isLoadingCalendar) {
      return Column(
        children: [
          SizedBox(height: headerHeight),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Space for header
        SizedBox(height: headerHeight),
        Container(
          margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
          ),
          child: SharedCalendarView(
            selectedDate: _selectedDate,
            focusedDate: _focusedDate,
            workoutDates: _workoutDates,
            onDateSelected: _onDateSelected,
            onMonthChanged: _onMonthChanged,
          ),
        ),
        // Workout list section
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: DatedWorkoutListView(
              selectedDate: _selectedDate,
              workouts: _selectedDateWorkoutItems.map((item) => item.history).toList(), 
              isLoading: _isLoadingCalendar,
            ),
          ),
        ),
      ],
    );
  }
}
