import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../services/database_service.dart';
import '../services/exercise_service.dart';
import '../services/user_service.dart';
import '../utils/unit_converter.dart';
import 'exercise_info_screen.dart';
import '../constants/app_constants.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  /*String _getUnitPreference() {
    return UserService.instance.currentProfile?.units ?? 'metric';
  }*/

  String _formatDuration(Duration duration) {
    int totalMinutes = duration.inMinutes;
    if (duration.inSeconds % 60 != 0 || totalMinutes == 0) {
      totalMinutes += 1; // Always round up if there are leftover seconds or if less than 1 min
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${hours}h';
      }
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
      return 'Today at ${_formatTime(date)}';
    } else if (workoutDate == yesterday) {
      return 'Yesterday at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildMoodIndicator() {
    final moodIcons = [
      Icons.sentiment_very_satisfied,
      Icons.sentiment_satisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_very_dissatisfied,
    ];

    final moodColors = [
      Colors.green,
      Colors.lightGreen,
      Colors.grey,
      Colors.orange,
      Colors.red,
    ];

    final moodLabels = [
      'Excellent',
      'Good',
      'Neutral',
      'Bad',
      'Very Bad',
    ];

    // Ensure mood index is within valid range (0-4), default to 2 (neutral) if invalid
    // For now, we'll use a default mood since the unified model doesn't have a mood field yet
    final moodValue = 2; // Default to neutral
    final moodIndex = (moodValue >= 0 && moodValue <= 4) ? moodValue : 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            moodIcons[moodIndex],
            color: moodColors[moodIndex],
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Mood: ${moodLabels[moodIndex]}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeight(double weight) {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    final unitLabel = UnitConverter.getWeightUnit(units.name); // Convert enum to string for UnitConverter
    final kUnitLabel = units == Units.imperial ? 'k lbs' : 'k kg';

    if (weight > 999) {
      return '${(weight / 1000).toStringAsFixed(1)} $kUnitLabel';
    }
    return '${weight.toStringAsFixed(1)} $unitLabel';
  }
  
  Widget _buildExerciseCard(WorkoutExercise exercise) {
    return GestureDetector(
      onTap: () async {
        Exercise? fullExercise;
        try {
          fullExercise = ExerciseService.instance.exercises.firstWhere(
            (ex) => ex.slug == exercise.exerciseSlug,
          );
        } catch (e) {
          // Element not found in list
          fullExercise = null;
        }

        if (fullExercise != null && mounted) {
          final exerciseToPass = fullExercise; // Assign to a non-nullable local variable
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseInfoScreen(
                exercise: exerciseToPass, // Use the non-nullable variable
                initialTabIndex: 1, // Open Stats tab
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: Could not find details for ${exercise.exerciseSlug}.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.exerciseSlug,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...exercise.sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: set.isCompleted ? Colors.green.withAlpha(51) : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: set.isCompleted 
                      ? Border.all(color: Colors.green.withAlpha(102), width: 1)
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: set.isCompleted ? Colors.green : Colors.grey[600],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '${set.actualReps ?? set.targetReps ?? 0} reps',
                            style: TextStyle(
                              color: set.isCompleted ? Colors.white : Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatWeight(set.actualWeight ?? set.targetWeight ?? 0.0),
                            style: TextStyle(
                              color: set.isCompleted ? Colors.white : Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (set.isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ), // Closes Column
      ), // Closes Container
    ); // Closes GestureDetector
  }

  Future<void> _deleteWorkout() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Delete Workout?'),
        content: Text(
            'Are you sure you want to delete "${widget.workout.name}"? This action cannot be undone.'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.instance.deleteWorkout(widget.workout.id);
        if (mounted) {
          Navigator.of(context).pop(); // Go back to the previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${widget.workout.name}" deleted.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete workout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: headerHeight),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.workout.color.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.workout.color.withAlpha(102),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.workout.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.workout.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workout.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(widget.workout.startedAt ?? DateTime.now()),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats row
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem(
                    _formatDuration(widget.workout.completedAt != null 
                        ? widget.workout.completedAt!.difference(widget.workout.startedAt ?? DateTime.now()) 
                        : Duration.zero),
                    'Duration',
                    Icons.timer_outlined,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[800],
                  ),
                  _buildSummaryItem(
                    '${widget.workout.totalSets}',
                    'Sets',
                    Icons.fitness_center_outlined,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[800],
                  ),
                  _buildSummaryItem(
                    _formatWeight(widget.workout.exercises.fold(0.0, (sum, exercise) => 
                        sum + exercise.sets.fold(0.0, (setSum, set) => 
                            setSum + (set.actualWeight ?? 0.0) * (set.actualReps ?? 0)))),
                    'Weight',
                    Icons.monitor_weight_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildMoodIndicator(),

            const SizedBox(height: 20),

            // Notes section
            if ((widget.workout.notes ?? '').isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.workout.notes ?? '',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Exercises section
            const Text(
              'Exercises',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...widget.workout.exercises.map((exercise) => _buildExerciseCard(exercise)),

            const SizedBox(height: 30),

            // Delete Workout Button
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(CupertinoIcons.delete, color: Colors.red),
                  label: const Text(
                    'Delete Workout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withAlpha((255 * 0.1).round()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.red, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _deleteWorkout,
                ),
              ),
            ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                  color: Colors.black54.withOpacity(0.8),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.workout.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
