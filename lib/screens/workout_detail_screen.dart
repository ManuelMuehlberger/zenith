import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../services/exercise_service.dart';
import '../services/user_service.dart';
import '../services/workout_service.dart';
import '../theme/app_theme.dart';
import '../utils/unit_converter.dart';
import 'exercise_info_screen.dart';

class _SetMetric {
  const _SetMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({super.key, required this.workout});

  final Workout workout;

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  static const int _neutralMood = 3;
  static const double _heroExpandedHeight = 330;

  late final ScrollController _scrollController;
  bool _showCollapsedTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final shouldShowTitle = _scrollController.offset > 120;
    if (shouldShowTitle != _showCollapsedTitle) {
      setState(() {
        _showCollapsedTitle = shouldShowTitle;
      });
    }
  }

  String _formatDuration(Duration duration) {
    var totalMinutes = duration.inMinutes;
    if (duration.inSeconds % 60 != 0 || totalMinutes == 0) {
      totalMinutes += 1;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}m';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final workoutDate = DateTime(date.year, date.month, date.day);

    if (workoutDate == today) {
      return 'Today at ${_formatTime(date)}';
    }
    if (workoutDate == yesterday) {
      return 'Yesterday at ${_formatTime(date)}';
    }
    return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatWeight(double weight) {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    final unitLabel = UnitConverter.getWeightUnit(units.name);
    final kUnitLabel = units == Units.imperial ? 'k lbs' : 'k kg';

    if (weight > 999) {
      return '${(weight / 1000).toStringAsFixed(1)} $kUnitLabel';
    }
    return '${weight.toStringAsFixed(1)} $unitLabel';
  }

  int get _moodValue {
    final mood = widget.workout.mood;
    if (mood != null && mood >= 1 && mood <= 5) {
      return mood;
    }
    return _neutralMood;
  }

  Duration get _sessionDuration {
    final startedAt = widget.workout.startedAt;
    final completedAt = widget.workout.completedAt;
    if (startedAt == null || completedAt == null) {
      return Duration.zero;
    }
    return completedAt.difference(startedAt);
  }

  double get _sessionVolume {
    return widget.workout.exercises.fold(0.0, (exerciseSum, exercise) {
      return exerciseSum +
          exercise.sets.fold(0.0, (setSum, set) {
            return setSum + ((set.actualWeight ?? 0.0) * (set.actualReps ?? 0));
          });
    });
  }

  String _resolveExerciseName(WorkoutExercise exercise) {
    final detailName = exercise.exerciseDetail?.name.trim();
    if (detailName != null && detailName.isNotEmpty) {
      return detailName;
    }

    try {
      final match = ExerciseService.instance.exercises.firstWhere(
        (candidate) => candidate.slug == exercise.exerciseSlug,
      );
      return match.name;
    } catch (_) {
      return exercise.exerciseSlug;
    }
  }

  Future<void> _openExerciseDetails(WorkoutExercise exercise) async {
    Exercise? fullExercise = exercise.exerciseDetail;

    if (fullExercise == null) {
      try {
        fullExercise = ExerciseService.instance.exercises.firstWhere(
          (candidate) => candidate.slug == exercise.exerciseSlug,
        );
      } catch (_) {
        fullExercise = null;
      }
    }

    if (fullExercise != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ExerciseInfoScreen(exercise: fullExercise!),
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: Could not find details for ${exercise.exerciseSlug}.',
          ),
          backgroundColor: context.appScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteWorkout() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Workout?'),
        content: Text(
          'Are you sure you want to delete "${widget.workout.name}"? This action cannot be undone.',
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await WorkoutService.instance.deleteWorkout(widget.workout.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.workout.name}" deleted.'),
          backgroundColor: context.appColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete workout: $error'),
          backgroundColor: context.appScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final accent = widget.workout.colorValue == null
        ? scheme.primary
        : widget.workout.color;
    final startedAt = widget.workout.startedAt ?? DateTime.now();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _heroExpandedHeight,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: scheme.surface.withValues(alpha: 0),
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(CupertinoIcons.back, color: scheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _showCollapsedTitle ? 1 : 0,
              child: Text(
                widget.workout.name,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge,
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final topInset = MediaQuery.of(context).padding.top;
                final minHeight = kToolbarHeight + topInset;
                final expandedRatio =
                    ((constraints.maxHeight - minHeight) /
                            (_heroExpandedHeight - minHeight))
                        .clamp(0.0, 1.0);

                return SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: OverflowBox(
                          maxHeight: double.infinity,
                          alignment: Alignment.bottomCenter,
                          child: Opacity(
                            opacity: Curves.easeOut.transform(expandedRatio),
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - expandedRatio)),
                              child: _DetailHeroCard(
                                workout: widget.workout,
                                accent: accent,
                                dateLabel: _formatDate(startedAt),
                                durationText: _formatDuration(_sessionDuration),
                                totalSets: widget.workout.totalSets,
                                volumeText: _formatWeight(_sessionVolume),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Additional metrics', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _DetailSurface(child: _MoodBanner(moodValue: _moodValue)),
                  if ((widget.workout.notes ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notes', style: textTheme.titleMedium),
                          const SizedBox(height: 10),
                          Text(
                            widget.workout.notes!.trim(),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Exercises', style: textTheme.headlineSmall),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.field,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${widget.workout.exercises.length}',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...widget.workout.exercises.map(
                    (exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExerciseSessionCard(
                        exercise: exercise,
                        exerciseName: _resolveExerciseName(exercise),
                        onTap: () => _openExerciseDetails(exercise),
                        formatWeight: _formatWeight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _deleteWorkout,
                    icon: Icon(CupertinoIcons.delete, color: scheme.error),
                    label: Text(
                      'Delete Workout',
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error.withValues(alpha: 0.12),
                      foregroundColor: scheme.error,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.workoutCardBorderRadius,
                        side: BorderSide(
                          color: scheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSurface extends StatelessWidget {
  const _DetailSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appScheme.surface,
        borderRadius: AppTheme.workoutCardBorderRadius,
      ),
      child: child,
    );
  }
}

class _DetailHeroCard extends StatelessWidget {
  const _DetailHeroCard({
    required this.workout,
    required this.accent,
    required this.dateLabel,
    required this.durationText,
    required this.totalSets,
    required this.volumeText,
  });

  final Workout workout;
  final Color accent;
  final String dateLabel;
  final String durationText;
  final int totalSets;
  final String volumeText;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: AppTheme.workoutCardBorderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  workout.icon,
                  color: context.appScheme.surface,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name, style: textTheme.displaySmall),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: context.appScheme.surface.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroMetric(value: durationText, label: 'Duration'),
                ),
                _HeroMetricDivider(),
                Expanded(
                  child: _HeroMetric(value: '$totalSets', label: 'Sets'),
                ),
                _HeroMetricDivider(),
                Expanded(
                  child: _HeroMetric(value: volumeText, label: 'Volume'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodBanner extends StatelessWidget {
  const _MoodBanner({required this.moodValue});

  final int moodValue;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;
    final colors = context.appColors;
    final textTheme = context.appText;

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
    final moodIndex = moodValue - 1;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: moodColors[moodIndex].withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            moodIcons[moodIndex],
            color: moodColors[moodIndex],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mood: ${moodLabels[moodIndex]}', style: textTheme.bodyMedium),
            Text(
              'Captured with the workout session',
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _HeroMetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: context.appColors.textTertiary.withValues(alpha: 0.22),
    );
  }
}

class _ExerciseImagePlaceholder extends StatelessWidget {
  const _ExerciseImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: colors.field.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: colors.textTertiary, size: 24),
          const SizedBox(height: 4),
          Text(
            'Image',
            style: textTheme.bodySmall?.copyWith(
              color: colors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSessionCard extends StatelessWidget {
  const _ExerciseSessionCard({
    required this.exercise,
    required this.exerciseName,
    required this.onTap,
    required this.formatWeight,
  });

  final WorkoutExercise exercise;
  final String exerciseName;
  final VoidCallback onTap;
  final String Function(double) formatWeight;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Material(
      color: context.appScheme.surface,
      borderRadius: AppTheme.workoutCardBorderRadius,
      child: InkWell(
        borderRadius: AppTheme.workoutCardBorderRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: AppTheme.workoutCardBorderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _ExerciseImagePlaceholder(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exerciseName, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${exercise.sets.length} sets',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: colors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
              if ((exercise.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  exercise.notes!.trim(),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ...exercise.sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                final metrics = _buildSetMetrics(set);
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == exercise.sets.length - 1 ? 0 : 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: set.isCompleted
                          ? colors.success.withValues(alpha: 0.12)
                          : colors.field.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: set.isCompleted
                                ? colors.success
                                : colors.field,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: textTheme.bodySmall?.copyWith(
                                color: set.isCompleted
                                    ? context.appScheme.surface
                                    : colors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: metrics
                                .map(
                                  (metric) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: identical(metric, metrics.last)
                                          ? 0
                                          : 4,
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: textTheme.bodyMedium,
                                        children: [
                                          TextSpan(
                                            text: '${metric.label}: ',
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: colors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: metric.value),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        if (set.isCompleted)
                          Icon(
                            Icons.check_circle,
                            color: colors.success,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<_SetMetric> _buildSetMetrics(WorkoutSet set) {
    final metrics = <_SetMetric>[];

    final goalValue = _formatSetMetric(set.targetReps, set.targetWeight);
    if (goalValue != null) {
      metrics.add(_SetMetric(label: 'Goal', value: goalValue));
    }

    final actualValue = _formatSetMetric(set.actualReps, set.actualWeight);
    if (actualValue != null) {
      metrics.add(
        _SetMetric(
          label: set.isCompleted ? 'Actual' : 'Logged',
          value: actualValue,
        ),
      );
    }

    if (metrics.isEmpty) {
      metrics.add(const _SetMetric(label: 'Set', value: 'No data'));
    }

    return metrics;
  }

  String? _formatSetMetric(int? reps, double? weight) {
    final parts = <String>[];
    if (reps != null) {
      parts.add('$reps reps');
    }
    if (weight != null) {
      parts.add(formatWeight(weight));
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' @ ');
  }
}
