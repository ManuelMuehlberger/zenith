import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/workout.dart';
import '../theme/app_theme.dart';
import 'past_workout_list_item.dart';

class DatedWorkoutListView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Workout> workouts;
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
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

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
                  style: textTheme.titleMedium,
                ),
              ),
              if (!isLoading && workouts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${workouts.length}',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                )
              : workouts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 48,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No workouts on this date',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return PastWorkoutListItem(workout: workout);
                  },
                ),
        ),
      ],
    );
  }
}
