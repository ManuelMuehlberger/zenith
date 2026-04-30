import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../constants/app_constants.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_set.dart';

class EditExerciseAddSetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EditExerciseAddSetButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPressed();
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 110,
        height: 36,
        decoration: BoxDecoration(
          color: AppConstants.ACCENT_COLOR_ORANGE,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.3).round()),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 18),
            const SizedBox(width: 2),
            Text(
              'Add',
              style: AppConstants.HEADER_BUTTON_TEXT_STYLE.copyWith(
                color: Colors.white,
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
                      style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(
                        color: AppConstants.ACCENT_COLOR,
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
                          ? Colors.amber
                          : (exercise.notes?.isNotEmpty ?? false)
                              ? Colors.amber.withAlpha(150)
                              : Colors.grey[500],
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
                        color: AppConstants.TEXT_SECONDARY_COLOR,
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
                        color: AppConstants.ACCENT_COLOR_ORANGE.withAlpha(
                          (255 * 0.2).round(),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.drag_handle,
                        color: AppConstants.ACCENT_COLOR_ORANGE,
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
                style: AppConstants.IOS_BODY_TEXT_STYLE,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  hintText: 'Add notes for this exercise...',
                  hintStyle: AppConstants.IOS_HINT_TEXT_STYLE,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.blue.withAlpha((255 * 0.5).round()),
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
                    style: AppConstants.IOS_SUBTEXT_STYLE,
                  ),
                ),
                if (!isBodyWeight) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Weight',
                      textAlign: TextAlign.center,
                      style: AppConstants.IOS_SUBTEXT_STYLE,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${setIndex + 1}',
                style: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(
                  color: AppConstants.TEXT_PRIMARY_COLOR,
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
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.red,
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