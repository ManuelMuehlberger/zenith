import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/workout_history.dart';
import 'past_workout_list_item.dart';

class DatedWorkoutListView extends StatelessWidget {
  final DateTime selectedDate;
  final List<WorkoutHistory> workouts;
  final bool isLoading;

  const DatedWorkoutListView({
    super.key,
    required this.selectedDate,
    required this.workouts,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat headerFormatter = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Workouts on ${headerFormatter.format(selectedDate)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isLoading && workouts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${workouts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.blue))
              : workouts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No workouts on this date',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: workouts.length,
                      itemBuilder: (context, index) {
                        final workoutHistory = workouts[index];
                        return PastWorkoutListItem(workout: workoutHistory);
                      },
                    ),
        ),
      ],
    );
  }
}
