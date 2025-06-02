import 'package:flutter/material.dart';

class InsightsCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedDate; 
  final List<DateTime> workoutDates;
  final Function(DateTime) onDateSelected;

  const InsightsCalendar({
    super.key,
    required this.selectedDate,
    required this.focusedDate,
    required this.workoutDates,
    required this.onDateSelected,
  });

  bool _hasWorkoutOnDate(DateTime date) {
    return workoutDates.any((workoutDate) =>
        workoutDate.year == date.year &&
        workoutDate.month == date.month &&
        workoutDate.day == date.day);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    final lastDayOfMonth = DateTime(focusedDate.year, focusedDate.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7; 
    
    final daysInMonth = lastDayOfMonth.day;
    final int totalCells = ((daysInMonth + firstDayOfWeek) / 7).ceil() * 7;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0), 
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey[600], 
                            fontWeight: FontWeight.w500,
                            fontSize: 10, 
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          
          const SizedBox(height: 2), 
          
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.6,
                crossAxisSpacing: 1, 
                mainAxisSpacing: 1,  
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                final dayOffset = index - firstDayOfWeek; 
                
                if (dayOffset < 0 || dayOffset >= daysInMonth) { 
                  return const SizedBox.shrink(); 
                }
                
                final date = DateTime(focusedDate.year, focusedDate.month, dayOffset + 1);
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
                final hasWorkout = _hasWorkoutOnDate(date);
                
                return GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade700 
                          : hasWorkout
                              ? Colors.green.withAlpha(70) 
                              : Colors.transparent,
                      border: isToday && !isSelected 
                          ? Border.all(color: Colors.blue.shade300, width: 1) 
                          : null, 
                      borderRadius: BorderRadius.circular(2), 
                    ),
                    child: Center( 
                      child: Text(
                        (dayOffset + 1).toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday 
                                  ? Colors.blue.shade200 
                                  : hasWorkout
                                      ? Colors.green.shade200 
                                      : Colors.grey[500], 
                          fontWeight: isSelected || isToday || hasWorkout ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
