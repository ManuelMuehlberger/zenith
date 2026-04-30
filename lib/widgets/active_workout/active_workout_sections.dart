import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_constants.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../services/reorder_service.dart';
import '../../services/workout_session_service.dart';
import '../active_workout_action_buttons.dart';
import '../active_workout_app_bar.dart';
import '../reorderable_active_exercise_card.dart';

class ActiveWorkoutScaffoldBody extends StatelessWidget {
  final Workout session;
  final Set<int> expandedNotes;
  final int? draggingIndex;
  final String weightUnit;
  final void Function(int) onToggleNotes;
  final void Function(String, String, {int? reps, double? weight, bool? isCompleted}) onUpdateSet;
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
              filter: ImageFilter.blur(
                sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                sigmaY: AppConstants.GLASS_BLUR_SIGMA,
              ),
              child: Container(
                height: headerHeight,
                color: AppConstants.HEADER_BG_COLOR_MEDIUM,
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
    final totalSets = session.totalSets;
    final progress = totalSets > 0 ? session.completedSets / totalSets : 0.0;
    final isCompleted = progress >= 1.0;
    final duration = session.completedAt != null
        ? session.completedAt!.difference(session.startedAt ?? DateTime.now())
        : DateTime.now().difference(session.startedAt ?? DateTime.now());
    final workoutColor = session.color;
    final mutedWorkoutColor = workoutColor.withAlpha((255 * 0.15).round());
    final semiTransparentWorkoutColor = workoutColor.withAlpha((255 * 0.6).round());

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
                  child: Icon(
                    session.icon,
                    color: workoutColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    session.name,
                    style: AppConstants.HEADER_TITLE_TEXT_STYLE,
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
                        backgroundColor: AppConstants.WORKOUT_BUTTON_BG_COLOR,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: isReorderMode
                                ? workoutColor.withAlpha((255 * 0.3).round())
                                : AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.3).round()),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: Icon(
                        Icons.reorder,
                        color: isReorderMode ? workoutColor : AppConstants.TEXT_TERTIARY_COLOR,
                        size: 22,
                      ),
                      tooltip: isReorderMode ? 'Exit reorder mode' : 'Reorder exercises',
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onFinishWorkout,
                      style: TextButton.styleFrom(
                        backgroundColor: isCompleted
                            ? AppConstants.ACCENT_COLOR_GREEN
                            : AppConstants.FINISH_BUTTON_BG_COLOR,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: isCompleted
                              ? BorderSide.none
                              : BorderSide(
                                  color: AppConstants.ACCENT_COLOR_GREEN.withAlpha((255 * 0.3).round()),
                                  width: 1,
                                ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        'Finish',
                        style: AppConstants.HEADER_BUTTON_TEXT_STYLE.copyWith(
                          color: isCompleted ? Colors.white : AppConstants.ACCENT_COLOR_GREEN,
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
                _InlineStat(
                  value: WorkoutSessionService.instance.formatDuration(duration),
                  icon: Icons.timer_outlined,
                  color: workoutColor,
                ),
                _buildDivider(),
                _InlineStat(
                  value: '${session.completedSets}/${session.totalSets}',
                  icon: Icons.fitness_center_outlined,
                  color: workoutColor,
                ),
                _buildDivider(),
                _InlineStat(
                  value: '${WorkoutSessionService.instance.formatWeight(session.totalWeight)}$weightUnit',
                  icon: Icons.monitor_weight_outlined,
                  color: workoutColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppConstants.DIVIDER_COLOR,
                      valueColor: AlwaysStoppedAnimation<Color>(semiTransparentWorkoutColor),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: AppConstants.IOS_SUBTITLE_FONT_SIZE,
                    fontWeight: FontWeight.bold,
                    color: semiTransparentWorkoutColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: AppConstants.DIVIDER_COLOR,
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
  final void Function(String, String, {int? reps, double? weight, bool? isCompleted}) onUpdateSet;
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
            final isOtherDragging = draggingIndex != null && draggingIndex != index;

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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: ActiveWorkoutActionButtons(
              onAddExercise: onAddExercise,
              onAbortWorkout: onAbortWorkout,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: bottomPadding + 40),
        ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppConstants.IOS_SUBTITLE_TEXT_STYLE.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.TEXT_PRIMARY_COLOR,
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
      onToggleNotes: (_) {},
      onUpdateSet: (_, __, {reps, weight, isCompleted}) {},
      onToggleSetCompletion: (_, __) {},
      onAddSet: () {},
      onRemoveSet: (_) {},
      workoutColor: session.color,
      workoutStartedAt: session.startedAt,
    );

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final animValue = Curves.easeInOut.transform(animation.value);
          final scale = lerpDouble(1, 1.05, animValue)!;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: proxyCard,
      ),
    );
  }
}