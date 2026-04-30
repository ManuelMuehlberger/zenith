import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../models/workout_exercise.dart';
import '../../models/workout_set.dart';
import '../../theme/app_theme.dart';

class EditExerciseAddSetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EditExerciseAddSetButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;

    return GestureDetector(
      onTap: () {
        onPressed();
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 110,
        height: 36,
        decoration: BoxDecoration(
          color: colors.warning,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.overlayStrong, width: 2),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: colors.textPrimary, size: 18),
            const SizedBox(width: 2),
            Text(
              'Add',
              style: textTheme.labelLarge?.copyWith(
                color: colors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditExerciseHeader extends StatelessWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final bool isNotesExpanded;
  final TextEditingController notesController;
  final ValueChanged<int> onToggleNotes;
  final ValueChanged<int> onRemoveExercise;
  final VoidCallback onShowExerciseInfo;
  final ValueChanged<String> onUpdateNotes;

  const EditExerciseHeader({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.isNotesExpanded,
    required this.notesController,
    required this.onToggleNotes,
    required this.onRemoveExercise,
    required this.onShowExerciseInfo,
    required this.onUpdateNotes,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseDetail?.name ?? exercise.exerciseSlug,
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onToggleNotes(exerciseIndex),
                    icon: Icon(
                      isNotesExpanded
                          ? Icons.sticky_note_2
                          : Icons.sticky_note_2_outlined,
                      color: isNotesExpanded
                          ? colors.warning
                          : (exercise.notes?.isNotEmpty ?? false)
                          ? colors.warning.withValues(alpha: 0.6)
                          : colors.textTertiary,
                      size: 24,
                    ),
                    tooltip: isNotesExpanded ? 'Hide notes' : 'Show notes',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PullDownButton(
                    itemBuilder: (context) => [
                      PullDownMenuItem(
                        onTap: onShowExerciseInfo,
                        title: 'Exercise Info',
                        icon: Icons.info_outline,
                      ),
                      PullDownMenuItem(
                        onTap: () => onRemoveExercise(exerciseIndex),
                        title: 'Remove Exercise',
                        icon: Icons.delete_outline,
                        isDestructive: true,
                      ),
                    ],
                    buttonBuilder: (context, showMenu) => IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      onPressed: showMenu,
                      icon: Icon(
                        Icons.more_horiz,
                        color: colors.textSecondary,
                        size: 28,
                      ),
                      tooltip: 'Exercise Options',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ReorderableDragStartListener(
                    index: exerciseIndex,
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.drag_handle,
                        color: colors.warning,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isNotesExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextFormField(
                controller: notesController,
                style: textTheme.bodyLarge,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.field,
                  hintText: 'Add notes for this exercise...',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: onUpdateNotes,
              ),
            ),
        ],
      ),
    );
  }
}

class EditExerciseSetsList extends StatelessWidget {
  final bool isBodyWeight;
  final List<WorkoutSet> sets;
  final Widget Function(WorkoutSet set, int setIndex) rowBuilder;

  const EditExerciseSetsList({
    super.key,
    required this.isBodyWeight,
    required this.sets,
    required this.rowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            child: Row(
              children: [
                const SizedBox(width: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Reps',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall,
                  ),
                ),
                if (!isBodyWeight) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Weight',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(width: 16),
                const SizedBox(width: 32),
              ],
            ),
          ),
          ...sets.asMap().entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 4.0),
              child: rowBuilder(entry.value, entry.key),
            );
          }),
        ],
      ),
    );
  }
}

class EditExerciseSetRow extends StatelessWidget {
  final int setIndex;
  final bool isBodyWeight;
  final Widget repsInput;
  final Widget? weightInput;
  final VoidCallback onRemove;

  const EditExerciseSetRow({
    super.key,
    required this.setIndex,
    required this.isBodyWeight,
    required this.repsInput,
    required this.onRemove,
    this.weightInput,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppThemeColors.clear,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 42,
            decoration: BoxDecoration(
              color: colors.textSecondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${setIndex + 1}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(child: repsInput),
          const SizedBox(width: 16),
          if (!isBodyWeight && weightInput != null) ...[
            Flexible(child: weightInput!),
            const SizedBox(width: 16),
          ],
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.remove_circle_outline,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              onPressed: () {
                onRemove();
                HapticFeedback.lightImpact();
              },
            ),
          ),
        ],
      ),
    );
  }
}
