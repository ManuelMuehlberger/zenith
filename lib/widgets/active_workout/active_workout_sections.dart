import 'dart:async';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../services/reorder_service.dart';
import '../../services/workout_session_service.dart';
import '../../theme/app_theme.dart';
import '../active_workout_action_buttons.dart';
import '../active_workout_app_bar.dart';
import '../reorderable_active_exercise_card.dart';

class ActiveWorkoutScaffoldBody extends StatelessWidget {
  final Workout session;
  final Set<int> expandedNotes;
  final int? draggingIndex;
  final String weightUnit;
  final void Function(int) onToggleNotes;
  final void Function(
    String,
    String, {
    int? reps,
    double? weight,
    bool? isCompleted,
  })
  onUpdateSet;
  final void Function(String, String) onToggleSetCompletion;
  final void Function(String) onAddSet;
  final void Function(String, String) onRemoveSet;
  final void Function(int, int) onReorder;
  final void Function(int) onReorderStart;
  final void Function(int) onReorderEnd;
  final VoidCallback onToggleReorderMode;
  final VoidCallback onFinishWorkout;
  final VoidCallback onAddExercise;
  final VoidCallback onAbortWorkout;

  const ActiveWorkoutScaffoldBody({
    super.key,
    required this.session,
    required this.expandedNotes,
    required this.draggingIndex,
    required this.weightUnit,
    required this.onToggleNotes,
    required this.onUpdateSet,
    required this.onToggleSetCompletion,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onReorder,
    required this.onReorderStart,
    required this.onReorderEnd,
    required this.onToggleReorderMode,
    required this.onFinishWorkout,
    required this.onAddExercise,
    required this.onAbortWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + ActiveWorkoutAppBar.getContentHeight();
    final appColors = context.appColors;

    return Stack(
      children: [
        Positioned.fill(
          child: ActiveWorkoutExerciseList(
            session: session,
            headerHeight: headerHeight,
            expandedNotes: expandedNotes,
            draggingIndex: draggingIndex,
            weightUnit: weightUnit,
            onToggleNotes: onToggleNotes,
            onUpdateSet: onUpdateSet,
            onToggleSetCompletion: onToggleSetCompletion,
            onAddSet: onAddSet,
            onRemoveSet: onRemoveSet,
            onReorder: onReorder,
            onReorderStart: onReorderStart,
            onReorderEnd: onReorderEnd,
            onAddExercise: onAddExercise,
            onAbortWorkout: onAbortWorkout,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: headerHeight,
                color: appColors.overlayMedium,
                child: SafeArea(
                  bottom: false,
                  child: ActiveWorkoutHeader(
                    session: session,
                    weightUnit: weightUnit,
                    isReorderMode: ReorderService.instance.isReorderMode,
                    onToggleReorderMode: onToggleReorderMode,
                    onFinishWorkout: onFinishWorkout,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ActiveWorkoutHeader extends StatelessWidget {
  final Workout session;
  final String weightUnit;
  final bool isReorderMode;
  final VoidCallback onToggleReorderMode;
  final VoidCallback onFinishWorkout;

  const ActiveWorkoutHeader({
    super.key,
    required this.session,
    required this.weightUnit,
    required this.isReorderMode,
    required this.onToggleReorderMode,
    required this.onFinishWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final appScheme = context.appScheme;
    final appText = context.appText;
    final dividerColor = Theme.of(context).dividerColor;
    final totalSets = session.totalSets;
    final progress = totalSets > 0 ? session.completedSets / totalSets : 0.0;
    final isCompleted = progress >= 1.0;
    final workoutColor = session.color;
    final mutedWorkoutColor = workoutColor.withAlpha((255 * 0.15).round());
    final semiTransparentWorkoutColor = workoutColor.withAlpha(
      (255 * 0.6).round(),
    );

    return Column(
      children: [
        SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: mutedWorkoutColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: workoutColor.withAlpha((255 * 0.3).round()),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(session.icon, color: workoutColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    session.name,
                    style: appText.headlineSmall,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        onToggleReorderMode();
                        HapticFeedback.lightImpact();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: appScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: isReorderMode
                                ? workoutColor.withAlpha((255 * 0.3).round())
                                : appColors.textTertiary.withAlpha(
                                    (255 * 0.3).round(),
                                  ),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: Icon(
                        Icons.reorder,
                        color: isReorderMode
                            ? workoutColor
                            : appColors.textTertiary,
                        size: 22,
                      ),
                      tooltip: isReorderMode
                          ? 'Exit reorder mode'
                          : 'Reorder exercises',
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onFinishWorkout,
                      style: TextButton.styleFrom(
                        backgroundColor: isCompleted
                            ? appColors.success
                            : appColors.surfaceAlt,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: isCompleted
                              ? BorderSide.none
                              : BorderSide(
                                  color: appColors.success.withAlpha(
                                    (255 * 0.3).round(),
                                  ),
                                  width: 1,
                                ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        'Finish',
                        style: appText.labelLarge?.copyWith(
                          color: isCompleted
                              ? appScheme.onPrimary
                              : appColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 36.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _WorkoutDurationStat(session: session, color: workoutColor),
                _buildDivider(dividerColor),
                _InlineStat(
                  value: '${session.completedSets}/${session.totalSets}',
                  icon: Icons.fitness_center_outlined,
                  color: workoutColor,
                ),
                _buildDivider(dividerColor),
                _InlineStat(
                  value:
                      '${WorkoutSessionService.instance.formatWeight(session.totalWeight)}$weightUnit',
                  icon: Icons.monitor_weight_outlined,
                  color: workoutColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        semiTransparentWorkoutColor,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: appText.bodyMedium?.copyWith(
                    color: semiTransparentWorkoutColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Container(
      width: 1,
      height: 20,
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _WorkoutDurationStat extends StatelessWidget {
  final Workout session;
  final Color color;

  const _WorkoutDurationStat({required this.session, required this.color});

  @override
  Widget build(BuildContext context) {
    if (session.completedAt != null) {
      return _InlineStat(
        value: WorkoutSessionService.instance.formatDuration(
          session.completedAt!.difference(
            session.startedAt ?? session.completedAt!,
          ),
        ),
        icon: Icons.timer_outlined,
        color: color,
      );
    }

    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (tick) => tick),
      initialData: 0,
      builder: (context, snapshot) {
        final duration = DateTime.now().difference(
          session.startedAt ?? DateTime.now(),
        );
        return _InlineStat(
          value: WorkoutSessionService.instance.formatDuration(duration),
          icon: Icons.timer_outlined,
          color: color,
        );
      },
    );
  }
}

class ActiveWorkoutExerciseList extends StatelessWidget {
  final Workout session;
  final double headerHeight;
  final Set<int> expandedNotes;
  final int? draggingIndex;
  final String weightUnit;
  final void Function(int) onToggleNotes;
  final void Function(
    String,
    String, {
    int? reps,
    double? weight,
    bool? isCompleted,
  })
  onUpdateSet;
  final void Function(String, String) onToggleSetCompletion;
  final void Function(String) onAddSet;
  final void Function(String, String) onRemoveSet;
  final void Function(int, int) onReorder;
  final void Function(int) onReorderStart;
  final void Function(int) onReorderEnd;
  final VoidCallback onAddExercise;
  final VoidCallback onAbortWorkout;

  const ActiveWorkoutExerciseList({
    super.key,
    required this.session,
    required this.headerHeight,
    required this.expandedNotes,
    required this.draggingIndex,
    required this.weightUnit,
    required this.onToggleNotes,
    required this.onUpdateSet,
    required this.onToggleSetCompletion,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onReorder,
    required this.onReorderStart,
    required this.onReorderEnd,
    required this.onAddExercise,
    required this.onAbortWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final isReorderMode = ReorderService.instance.isReorderMode;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
        SliverReorderableList(
          itemBuilder: (context, index) {
            final exercise = session.exercises[index];
            final isDragging = draggingIndex == index;
            final isOtherDragging =
                draggingIndex != null && draggingIndex != index;

            return ReorderableDelayedDragStartListener(
              key: ValueKey(exercise.id),
              index: index,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                child: ReorderableActiveExerciseCard(
                  exercise: exercise,
                  weightUnit: weightUnit,
                  expandedNotes: expandedNotes,
                  exerciseIndex: index,
                  isReorderMode: isReorderMode,
                  isDragging: isDragging,
                  isOtherDragging: isOtherDragging,
                  onToggleNotes: onToggleNotes,
                  onUpdateSet: onUpdateSet,
                  onToggleSetCompletion: onToggleSetCompletion,
                  onAddSet: () => onAddSet(exercise.id),
                  onRemoveSet: (setId) => onRemoveSet(exercise.id, setId),
                  workoutColor: session.color,
                  workoutStartedAt: session.startedAt,
                ),
              ),
            );
          },
          itemCount: session.exercises.length,
          onReorder: onReorder,
          onReorderStart: onReorderStart,
          onReorderEnd: onReorderEnd,
          proxyDecorator: (child, index, animation) {
            return _ActiveWorkoutProxyCard(
              session: session,
              exercise: session.exercises[index],
              weightUnit: weightUnit,
              expandedNotes: expandedNotes,
              index: index,
              animation: animation,
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: ActiveWorkoutActionButtons(
              onAddExercise: onAddExercise,
              onAbortWorkout: onAbortWorkout,
            ),
          ),
        ),
        SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding + 40)),
      ],
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String value;
  final IconData icon;
  final Color color;

  const _InlineStat({
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final appText = context.appText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: appText.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: appColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActiveWorkoutProxyCard extends StatelessWidget {
  final Workout session;
  final WorkoutExercise exercise;
  final String weightUnit;
  final Set<int> expandedNotes;
  final int index;
  final Animation<double> animation;

  const _ActiveWorkoutProxyCard({
    required this.session,
    required this.exercise,
    required this.weightUnit,
    required this.expandedNotes,
    required this.index,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final proxyCard = ReorderableActiveExerciseCard(
      key: ValueKey('proxy_${exercise.id}'),
      exercise: exercise,
      weightUnit: weightUnit,
      expandedNotes: expandedNotes,
      exerciseIndex: index,
      isReorderMode: true,
      isDragging: true,
      isOtherDragging: false,
      onToggleNotes: (exerciseId) {},
      onUpdateSet: (workoutId, setId, {reps, weight, isCompleted}) {},
      onToggleSetCompletion: (workoutId, setId) {},
      onAddSet: () {},
      onRemoveSet: (setId) {},
      workoutColor: session.color,
      workoutStartedAt: session.startedAt,
    );

    return Material(
      color: context.appColors.overlayStrong.withValues(alpha: 0),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final animValue = Curves.easeInOut.transform(animation.value);
          final scale = lerpDouble(1, 1.05, animValue)!;
          return Transform.scale(scale: scale, child: child);
        },
        child: proxyCard,
      ),
    );
  }
}
