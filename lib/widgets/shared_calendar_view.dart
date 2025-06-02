import 'package:flutter/material.dart';

class SharedCalendarView extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final List<DateTime> workoutDates;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;

  const SharedCalendarView({
    super.key,
    required this.selectedDate,
    required this.focusedDate,
    required this.workoutDates,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  bool _hasWorkoutOnDate(DateTime date) {
    return workoutDates.any((workoutDate) =>
        workoutDate.year == date.year &&
        workoutDate.month == date.month &&
        workoutDate.day == date.day);
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    final lastDayOfMonth = DateTime(focusedDate.year, focusedDate.month + 1, 0);
    
    // Calculate first day offset (Sunday = 0)
    int firstDayOfWeekOffset = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;
    
    // Calculate number of weeks needed
    final int numberOfWeeks = ((daysInMonth + firstDayOfWeekOffset - 1) / 7).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month Header with Navigation (within the grey box)
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous Month Button
                GestureDetector(
                  onTap: () {
                    final previousMonth = DateTime(focusedDate.year, focusedDate.month - 1, 1);
                    onMonthChanged(previousMonth);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
                
                // Month and Year
                Text(
                  '${_getMonthName(focusedDate.month)} ${focusedDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                
                // Next Month Button
                GestureDetector(
                  onTap: () {
                    final nextMonth = DateTime(focusedDate.year, focusedDate.month + 1, 1);
                    onMonthChanged(nextMonth);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Day Headers
          Container(
            height: 24,
            margin: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Calendar Grid
          SizedBox(
            height: numberOfWeeks * 48.0,
            child: Column(
              children: List.generate(numberOfWeeks, (weekIndex) {
                return Expanded(
                  child: Row(
                    children: List.generate(7, (dayIndex) {
                      final dayNumberInGrid = (weekIndex * 7) + dayIndex - firstDayOfWeekOffset + 1;
                      
                      if (dayNumberInGrid < 1 || dayNumberInGrid > daysInMonth) {
                        return const Expanded(child: SizedBox());
                      }

                      final date = DateTime(focusedDate.year, focusedDate.month, dayNumberInGrid);
                      final isSelected = date.year == selectedDate.year &&
                          date.month == selectedDate.month &&
                          date.day == selectedDate.day;
                      final isToday = date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day;
                      final hasWorkout = _hasWorkoutOnDate(date);

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: GestureDetector(
                            onTap: () => onDateSelected(date),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue // Selected day
                                    : hasWorkout
                                        ? Colors.blueAccent // Workout day, not selected
                                        : Colors.transparent, // Default
                                borderRadius: BorderRadius.circular(10),
                                border: isToday && !isSelected && !hasWorkout // Only show border if not a workout day
                                    ? Border.all(
                                        color: Colors.blue.withOpacity(0.7),
                                        width: 1.2,
                                      )
                                    : null,
                              ),
                              child: Center( // Center the text
                                child: Text(
                                  dayNumberInGrid.toString(),
                                  style: TextStyle(
                                    color: isSelected || (hasWorkout && !isSelected)
                                        ? Colors.white // White text for selected or workout days
                                        : isToday
                                            ? Colors.blue // Blue text for today (not selected, no workout)
                                            : Colors.white70, // Default text color
                                    fontWeight: isSelected || isToday 
                                        ? FontWeight.w600 
                                        : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
