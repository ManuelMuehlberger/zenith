import 'package:flutter/material.dart';

import '../../models/workout_exercise.dart';
import '../../theme/app_theme.dart';
import '../edit_exercise_card.dart';
import '../edit_workout_action_buttons.dart';
import '../edit_workout_name_section.dart';
import '../workout_metrics_widget.dart';

class CreateWorkoutHeader extends StatelessWidget {
  final bool isEditing;
  final int exerciseCount;
  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onSave;

  const CreateWorkoutHeader({
    super.key,
    required this.isEditing,
    required this.exerciseCount,
    required this.isLoading,
    required this.onClose,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: colors.textPrimary, size: 28),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEditing ? 'Edit Workout' : 'Create Workout',
                    style: textTheme.titleLarge,
                  ),
                  if (exerciseCount > 0)
                    Text(
                      '$exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}',
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: isLoading ? null : onSave,
              style: TextButton.styleFrom(
                backgroundColor: colors.surfaceAlt,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: colors.success.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.success,
                      ),
                    )
                  : Text(
                      'Save',
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.success,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateWorkoutContent extends StatelessWidget {
  final double headerHeight;
  final TextEditingController nameController;
  final Color selectedColor;
  final IconData selectedIcon;
  final VoidCallback onIconTap;
  final List<WorkoutExercise> exercises;
  final Set<int> expandedNotes;
  final String weightUnit;
  final void Function(int) onToggleNotes;
  final void Function(int) onRemoveExercise;
  final void Function(int) onAddSet;
  final void Function(int, int) onRemoveSet;
  final void Function(
    int,
    int, {
    int? targetReps,
    double? targetWeight,
    String? type,
    int? targetRestSeconds,
  })
  onUpdateSet;
  final void Function(int, String) onUpdateNotes;
  final void Function(int, int) onToggleRepRange;
  final void Function(int, int) onReorderExercises;

  const CreateWorkoutContent({
    super.key,
    required this.headerHeight,
    required this.nameController,
    required this.selectedColor,
    required this.selectedIcon,
    required this.onIconTap,
    required this.exercises,
    required this.expandedNotes,
    required this.weightUnit,
    required this.onToggleNotes,
    required this.onRemoveExercise,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    required this.onUpdateNotes,
    required this.onToggleRepRange,
    required this.onReorderExercises,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
        SliverToBoxAdapter(
          child: EditWorkoutNameSection(
            nameController: nameController,
            selectedColor: selectedColor,
            selectedIcon: selectedIcon,
            onIconTap: onIconTap,
          ),
        ),
        SliverToBoxAdapter(child: WorkoutMetricsWidget(exercises: exercises)),
        SliverToBoxAdapter(
          child: CreateWorkoutExercisesSection(
            exercises: exercises,
            expandedNotes: expandedNotes,
            weightUnit: weightUnit,
            onToggleNotes: onToggleNotes,
            onRemoveExercise: onRemoveExercise,
            onAddSet: onAddSet,
            onRemoveSet: onRemoveSet,
            onUpdateSet: onUpdateSet,
            onUpdateNotes: onUpdateNotes,
            onToggleRepRange: onToggleRepRange,
            onReorderExercises: onReorderExercises,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 150.0)),
      ],
    );
  }
}

class CreateWorkoutExercisesSection extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final Set<int> expandedNotes;
  final String weightUnit;
  final void Function(int) onToggleNotes;
  final void Function(int) onRemoveExercise;
  final void Function(int) onAddSet;
  final void Function(int, int) onRemoveSet;
  final void Function(
    int,
    int, {
    int? targetReps,
    double? targetWeight,
    String? type,
    int? targetRestSeconds,
  })
  onUpdateSet;
  final void Function(int, String) onUpdateNotes;
  final void Function(int, int) onToggleRepRange;
  final void Function(int, int) onReorderExercises;

  const CreateWorkoutExercisesSection({
    super.key,
    required this.exercises,
    required this.expandedNotes,
    required this.weightUnit,
    required this.onToggleNotes,
    required this.onRemoveExercise,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    required this.onUpdateNotes,
    required this.onToggleRepRange,
    required this.onReorderExercises,
  });

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const SizedBox(height: 400, child: CreateWorkoutEmptyState());
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: exercises.length,
      onReorder: onReorderExercises,
      itemBuilder: (context, index) {
        return EditExerciseCard(
          key: ValueKey(exercises[index].id),
          exercise: exercises[index],
          exerciseIndex: index,
          isNotesExpanded: expandedNotes.contains(index),
          onToggleNotes: onToggleNotes,
          onRemoveExercise: onRemoveExercise,
          onAddSet: onAddSet,
          onRemoveSet: onRemoveSet,
          onUpdateSet: onUpdateSet,
          onUpdateNotes: onUpdateNotes,
          onToggleRepRange: onToggleRepRange,
          weightUnit: weightUnit,
        );
      },
    );
  }
}

class CreateWorkoutBottomBar extends StatelessWidget {
  final VoidCallback onAddExercise;

  const CreateWorkoutBottomBar({super.key, required this.onAddExercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.appScheme.surface)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 5.0,
            bottom: 5.0,
          ),
          child: EditWorkoutActionButtons(onAddExercise: onAddExercise),
        ),
      ),
    );
  }
}

class CreateWorkoutEmptyState extends StatelessWidget {
  const CreateWorkoutEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.appScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 40,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text('No exercises added yet', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Add exercises to build your workout',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
