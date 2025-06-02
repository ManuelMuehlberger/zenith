import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/workout_history.dart';
import '../widgets/shared_calendar_view.dart';
import '../widgets/dated_workout_list_view.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<DateTime> _workoutDates = [];
  List<WorkoutHistory> _selectedDateWorkouts = [];
  bool _isLoading = true;
  bool _isLoadingWorkouts = false; // For loading workouts specifically

  @override
  void initState() {
    super.initState();
    _loadInitialCalendarData();
  }

  Future<void> _loadInitialCalendarData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Overall loading for initial setup
    });
    try {
      await DatabaseService.instance.migrateWorkoutHistoryIcons(); 
      final dates = await DatabaseService.instance.getDatesWithWorkouts();
      if (mounted) {
        setState(() {
          _workoutDates = dates;
        });
      }
      // Load workouts for the initially selected date
      await _loadWorkoutsForDate(_selectedDate); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading calendar data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWorkoutsForDate(DateTime date) async {
    if (!mounted) return;
    setState(() {
      _isLoadingWorkouts = true; // Specific loading for workouts
    });
    try {
      final workouts = await DatabaseService.instance.getWorkoutHistoryForDate(date);
      if (mounted) {
        setState(() {
          _selectedDateWorkouts = workouts;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedDateWorkouts = []; // Clear workouts on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workouts: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWorkouts = false;
        });
      }
    }
  }

  void _onDateSelected(DateTime date) {
    if (!mounted) return;
    setState(() {
      _selectedDate = date;
    });
    _loadWorkoutsForDate(date);
  }

  void _onMonthChanged(DateTime newFocusedDate) {
    if (!mounted) return;
    setState(() {
      _focusedDate = newFocusedDate;
      // If selectedDate is not in the new focused month, update selectedDate to the 1st of new month
      if (_selectedDate.month != _focusedDate.month || _selectedDate.year != _focusedDate.year) {
        _selectedDate = DateTime(_focusedDate.year, _focusedDate.month, 1);
         _loadWorkoutsForDate(_selectedDate); // Reload workouts for the new default selected date
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(
      //   backgroundColor: Colors.black,
      //   elevation: 0,
      // ), // AppBar removed
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            )
          : Column(
              children: [
                // Shared Calendar View
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900], // Background for the calendar section
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SharedCalendarView(
                      selectedDate: _selectedDate,
                      focusedDate: _focusedDate,
                    workoutDates: _workoutDates,
                      onDateSelected: _onDateSelected,
                      onMonthChanged: _onMonthChanged,
                    ),
                  ),
                ),
                // Dated Workout List View
                Expanded(
                  child: DatedWorkoutListView(
                    selectedDate: _selectedDate,
                    workouts: _selectedDateWorkouts,
                    isLoading: _isLoadingWorkouts,
                  ),
                ),
              ],
            ),
    );
  }
}
