import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../services/exercise_service.dart';
import '../services/user_service.dart';
import '../services/workout_service.dart';
import '../theme/app_theme.dart';
import '../utils/unit_converter.dart';
import 'exercise_info_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  static const int _neutralMood = 3;

  /*String _getUnitPreference() {
    return UserService.instance.currentProfile?.units ?? 'metric';
  }*/

  String _formatDuration(Duration duration) {
    int totalMinutes = duration.inMinutes;
    if (duration.inSeconds % 60 != 0 || totalMinutes == 0) {
      totalMinutes +=
          1; // Always round up if there are leftover seconds or if less than 1 min
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
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final moodValue = widget.workout.mood;
    final moodIcons = [
      Icons.sentiment_very_dissatisfied,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_satisfied,
      Icons.sentiment_very_satisfied,
    ];

    final moodColors = [
      scheme.error,
      colors.warning,
      colors.textSecondary,
      scheme.primary,
      colors.success,
    ];

    final moodLabels = ['Very Bad', 'Bad', 'Neutral', 'Good', 'Excellent'];
    final normalizedMood =
        moodValue != null && moodValue >= 1 && moodValue <= 5
        ? moodValue
        : _neutralMood;
    final moodIndex = normalizedMood - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(moodIcons[moodIndex], color: moodColors[moodIndex], size: 24),
          const SizedBox(width: 12),
          Text('Mood: ${moodLabels[moodIndex]}', style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  String _formatWeight(double weight) {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    final unitLabel = UnitConverter.getWeightUnit(
      units.name,
    ); // Convert enum to string for UnitConverter
    final kUnitLabel = units == Units.imperial ? 'k lbs' : 'k kg';

    if (weight > 999) {
      return '${(weight / 1000).toStringAsFixed(1)} $kUnitLabel';
    }
    return '${weight.toStringAsFixed(1)} $unitLabel';
  }

  Widget _buildExerciseCard(WorkoutExercise exercise) {
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
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
          final exerciseToPass =
              fullExercise; // Assign to a non-nullable local variable
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseInfoScreen(
                exercise: exerciseToPass, // Use the non-nullable variable
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: Could not find details for ${exercise.exerciseSlug}.',
              ),
              backgroundColor: scheme.error,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.exerciseSlug, style: textTheme.titleMedium),
            const SizedBox(height: 12),
            ...exercise.sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: set.isCompleted
                      ? colors.success.withValues(alpha: 0.2)
                      : colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: set.isCompleted
                      ? Border.all(
                          color: colors.success.withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: set.isCompleted ? colors.success : colors.field,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textPrimary,
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
                            style: textTheme.bodyMedium?.copyWith(
                              color: set.isCompleted
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatWeight(
                              set.actualWeight ?? set.targetWeight ?? 0.0,
                            ),
                            style: textTheme.bodyMedium?.copyWith(
                              color: set.isCompleted
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (set.isCompleted)
                      Icon(Icons.check_circle, color: colors.success, size: 16),
                  ],
                ),
              );
            }),
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
          'Are you sure you want to delete "${widget.workout.name}"? This action cannot be undone.',
        ),
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
        await WorkoutService.instance.deleteWorkout(widget.workout.id);
        if (mounted) {
          Navigator.of(context).pop(true); // Go back to the previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${widget.workout.name}" deleted.'),
              backgroundColor: context.appColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete workout: $e'),
              backgroundColor: context.appScheme.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    final scheme = context.appScheme;
    final textTheme = context.appText;
    return Column(
      children: [
        Icon(icon, color: scheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final displayColor = widget.workout.colorValue == null
        ? scheme.primary
        : widget.workout.color;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: displayColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: displayColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: displayColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  widget.workout.icon,
                                  color: colors.textPrimary,
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
                                      style: textTheme.displaySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(
                                        widget.workout.startedAt ??
                                            DateTime.now(),
                                      ),
                                      style: textTheme.bodyMedium,
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
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.surfaceAlt,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSummaryItem(
                                _formatDuration(
                                  widget.workout.completedAt != null
                                      ? widget.workout.completedAt!.difference(
                                          widget.workout.startedAt ??
                                              DateTime.now(),
                                        )
                                      : Duration.zero,
                                ),
                                'Duration',
                                Icons.timer_outlined,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: colors.surfaceAlt,
                              ),
                              _buildSummaryItem(
                                '${widget.workout.totalSets}',
                                'Sets',
                                Icons.fitness_center_outlined,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: colors.surfaceAlt,
                              ),
                              _buildSummaryItem(
                                _formatWeight(
                                  widget.workout.exercises.fold(
                                    0.0,
                                    (sum, exercise) =>
                                        sum +
                                        exercise.sets.fold(
                                          0.0,
                                          (setSum, set) =>
                                              setSum +
                                              (set.actualWeight ?? 0.0) *
                                                  (set.actualReps ?? 0),
                                        ),
                                  ),
                                ),
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
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Notes', style: textTheme.titleMedium),
                                const SizedBox(height: 8),
                                Text(
                                  widget.workout.notes ?? '',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Exercises section
                        Text('Exercises', style: textTheme.headlineSmall),
                        const SizedBox(height: 12),

                        ...widget.workout.exercises.map(
                          (exercise) => _buildExerciseCard(exercise),
                        ),

                        const SizedBox(height: 30),

                        // Delete Workout Button
                        Center(
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              icon: Icon(
                                CupertinoIcons.delete,
                                color: scheme.error,
                              ),
                              label: Text(
                                'Delete Workout',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: scheme.error.withValues(
                                  alpha: 0.1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: scheme.error,
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
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
                filter: ImageFilter.blur(
                  sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                  sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                ),
                child: Container(
                  height: headerHeight,
                  color: colors.overlayStrong,
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: colors.textPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.workout.name,
                            style: textTheme.titleLarge,
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
