import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../screens/exercise_info_screen.dart';
import '../services/workout_session_service.dart';
import '../theme/app_theme.dart';

class ActiveExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final String weightUnit;
  final Set<int> expandedNotes;
  final int exerciseIndex;
  final Function(int) onToggleNotes;
  final Function(String, String, {int? reps, double? weight, bool? isCompleted})
  onUpdateSet;
  final Function(String, String) onToggleSetCompletion;

  const ActiveExerciseCard({
    super.key,
    required this.exercise,
    required this.weightUnit,
    required this.expandedNotes,
    required this.exerciseIndex,
    required this.onToggleNotes,
    required this.onUpdateSet,
    required this.onToggleSetCompletion,
  });

  @override
  State<ActiveExerciseCard> createState() => _ActiveExerciseCardState();
}

class _ActiveExerciseCardState extends State<ActiveExerciseCard> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  TextEditingController _getController(
    String controllerKey,
    String textToInitializeWith,
  ) {
    if (!_controllers.containsKey(controllerKey)) {
      _controllers[controllerKey] = TextEditingController(
        text: textToInitializeWith,
      );
    }
    return _controllers[controllerKey]!;
  }

  bool _canCompleteSet(String exerciseId, int setNumber) {
    final exercise = widget.exercise;

    if (setNumber < 1 || setNumber > exercise.sets.length) return false;

    final currentSet = exercise.sets[setNumber - 1];

    if (currentSet.isCompleted) {
      for (int i = setNumber; i < exercise.sets.length; i++) {
        if (exercise.sets[i].isCompleted) {
          return false;
        }
      }
      return true;
    }

    if (setNumber == 1) return true;

    if (setNumber - 2 >= 0 && setNumber - 2 < exercise.sets.length) {
      final previousSet = exercise.sets[setNumber - 2];
      return previousSet.isCompleted;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final colors = context.appColors;
    final textTheme = context.appText;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.surfaceAlt.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 2.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.exercise.exerciseDetail?.name ??
                                widget.exercise.exerciseSlug,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget
                                    .exercise
                                    .exerciseDetail
                                    ?.primaryMuscleGroup
                                    .name ??
                                'N/A',
                            style: textTheme.labelMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.exercise.notes?.isNotEmpty ?? false)
                      IconButton(
                        onPressed: () =>
                            widget.onToggleNotes(widget.exerciseIndex),
                        icon: Icon(
                          widget.expandedNotes.contains(widget.exerciseIndex)
                              ? Icons.sticky_note_2
                              : Icons.sticky_note_2_outlined,
                          color:
                              widget.expandedNotes.contains(
                                widget.exerciseIndex,
                              )
                              ? colors.warning
                              : colors.textTertiary,
                          size: 24,
                        ),
                        tooltip:
                            widget.expandedNotes.contains(widget.exerciseIndex)
                            ? 'Hide notes'
                            : 'Show notes',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => _showExerciseInfo(context),
                        icon: Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        tooltip: 'Exercise Info',
                      ),
                    ),
                  ],
                ),
                if (widget.expandedNotes.contains(widget.exerciseIndex) &&
                    widget.exercise.notes != null &&
                    widget.exercise.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.field,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.textSecondary, width: 1),
                    ),
                    child: Text(
                      widget.exercise.notes ?? '',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Weight',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
                ...widget.exercise.sets.asMap().entries.map((entry) {
                  final setIndex = entry.key;
                  final set = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4.0),
                    child: _buildSetRow(set, setIndex + 1),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(WorkoutSet set, int setNumber) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final theme = Theme.of(context);
    final isCompleted = set.isCompleted;
    final canComplete = _canCompleteSet(widget.exercise.id, setNumber);
    final originalSet = setNumber <= widget.exercise.sets.length
        ? widget.exercise.sets[setNumber - 1]
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isCompleted
            ? colors.success.withValues(alpha: 0.08)
            : theme.colorScheme.surface.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 42,
            decoration: BoxDecoration(
              color: isCompleted
                  ? colors.success
                  : canComplete
                  ? colors.textSecondary
                  : colors.field,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                setNumber.toString(),
                style: textTheme.bodyMedium?.copyWith(
                  color: canComplete || isCompleted
                      ? colors.textPrimary
                      : colors.textTertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDecoratedSetInput(
              controllerKey: '${widget.exercise.id}_${set.id}_reps',
              initialText: (set.actualReps ?? 0) > 0
                  ? set.actualReps.toString()
                  : '',
              goalValue: originalSet?.targetReps?.toString(),
              lastValue: null,
              onChanged: (value) {
                final reps = int.tryParse(value);
                if (reps != null) {
                  widget.onUpdateSet(widget.exercise.id, set.id, reps: reps);
                } else if (value.isEmpty) {
                  widget.onUpdateSet(widget.exercise.id, set.id, reps: 0);
                }
              },
              enabled: !isCompleted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDecoratedSetInput(
              controllerKey: '${widget.exercise.id}_${set.id}_weight',
              initialText: (set.actualWeight ?? 0.0) > 0.0
                  ? WorkoutSessionService.instance.formatWeight(
                      set.actualWeight!,
                    )
                  : '',
              goalValue: originalSet?.targetWeight != null
                  ? WorkoutSessionService.instance.formatWeight(
                      originalSet!.targetWeight!,
                    )
                  : null,
              lastValue: null,
              onChanged: (value) {
                final weight = double.tryParse(value);
                if (weight != null) {
                  widget.onUpdateSet(
                    widget.exercise.id,
                    set.id,
                    weight: weight,
                  );
                } else if (value.isEmpty) {
                  widget.onUpdateSet(widget.exercise.id, set.id, weight: 0.0);
                }
              },
              enabled: !isCompleted,
              showKgSuffix: true,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: canComplete
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onToggleSetCompletion(widget.exercise.id, set.id);
                  }
                : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? colors.success
                    : canComplete
                    ? theme.colorScheme.surface.withValues(alpha: 0)
                    : colors.field,
                border: Border.all(
                  color: isCompleted
                      ? colors.success
                      : canComplete
                      ? colors.textSecondary
                      : colors.textTertiary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check_rounded,
                      color: colors.textPrimary,
                      size: 20,
                    )
                  : !canComplete
                  ? Icon(
                      Icons.lock_outline,
                      color: colors.textTertiary,
                      size: 16,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecoratedSetInput({
    required String controllerKey,
    required String initialText,
    String? goalValue,
    String? lastValue,
    required Function(String) onChanged,
    required bool enabled,
    bool showKgSuffix = false,
  }) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final colorScheme = context.appScheme;

    String valueToInitializeControllerWith = initialText;
    if (lastValue != null && lastValue.isNotEmpty) {
      valueToInitializeControllerWith = lastValue;
    }
    if (showKgSuffix
        ? (valueToInitializeControllerWith == '0.0' ||
              valueToInitializeControllerWith == '0')
        : (valueToInitializeControllerWith == '0')) {
      valueToInitializeControllerWith = '';
    }

    const double goalTextFontSize = 10.0;
    const double verticalPaddingAboveMainText = 2.0;
    const double spaceBetweenMainAndGoal = 1.0;
    const double verticalPaddingBelowGoalText = 3.0;
    const double goalTextLineHeight = goalTextFontSize * 1.2;
    const double bottomPaddingForGoal =
        goalTextLineHeight +
        spaceBetweenMainAndGoal +
        verticalPaddingBelowGoalText;

    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          controller: _getController(
            controllerKey,
            valueToInitializeControllerWith,
          ),
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(showKgSuffix ? r'^\d*\.?\d{0,2}' : r'^\d*'),
            ),
          ],
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.top,
          style: textTheme.titleSmall?.copyWith(
            color: enabled ? colors.textPrimary : colors.textTertiary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? colors.field.withValues(alpha: 0.5)
                : colors.surfaceAlt,
            suffixText: showKgSuffix ? widget.weightUnit : null,
            suffixStyle: textTheme.bodySmall,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
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
            contentPadding: const EdgeInsets.fromLTRB(
              12,
              verticalPaddingAboveMainText,
              12,
              bottomPaddingForGoal,
            ),
          ),
          onChanged: onChanged,
          onTap: () {
            if (_controllers.containsKey(controllerKey)) {
              final controller = _controllers[controllerKey]!;
              if (controller.text.isNotEmpty) {
                Future.delayed(Duration.zero, () {
                  controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: controller.text.length,
                  );
                });
              }
            }
          },
        ),
        if (goalValue != null && goalValue.isNotEmpty)
          Positioned(
            bottom: verticalPaddingBelowGoalText,
            child: Text(
              'Goal: $goalValue${showKgSuffix ? ' ${widget.weightUnit}' : ''}',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textTertiary,
                fontSize: goalTextFontSize,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  void _showExerciseInfo(BuildContext context) {
    final textTheme = context.appText;

    if (widget.exercise.exerciseDetail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ExerciseInfoScreen(exercise: widget.exercise.exerciseDetail!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exercise details not available for ${widget.exercise.exerciseSlug}',
            style: textTheme.bodyLarge,
          ),
        ),
      );
    }
  }
}
