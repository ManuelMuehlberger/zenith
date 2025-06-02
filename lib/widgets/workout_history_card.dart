import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_history.dart';
import '../screens/workout_detail_screen.dart';
import '../services/user_service.dart';
import '../utils/unit_converter.dart';

class WorkoutHistoryCard extends StatelessWidget {
  final WorkoutHistory workout;

  const WorkoutHistoryCard({
    super.key,
    required this.workout,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final workoutDate = DateTime(date.year, date.month, date.day);

    if (workoutDate == today) {
      return 'Today';
    } else if (workoutDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatWeight(double weightInKg) {
    final userService = UserService.instance;
    final units = userService.currentProfile?.units ?? 'metric';
    final unitSuffix = UnitConverter.getWeightUnit(units);

    if (weightInKg >= 1000) {
      final formatter = NumberFormat("0.0", "en_US");
      return '${formatter.format(weightInKg / 1000)} k $unitSuffix';
    } else {
      final formatter = NumberFormat("0.0", "en_US");
      return '${formatter.format(weightInKg)} $unitSuffix';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to UserService changes to rebuild when unit preference changes
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, child) {
        // The actual card content, which will be rebuilt by AnimatedBuilder
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailScreen(workout: workout),
              ),
            );
          },
          child: Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Workout icon with colored squircle
                  Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: workout.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  workout.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Workout details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            workout.workoutName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(workout.startTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(workout.duration),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.fitness_center,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${workout.totalSets} sets',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.monitor_weight,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatWeight(workout.totalWeight),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    if (workout.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        workout.notes,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
                  // Chevron icon to indicate it's tappable
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
