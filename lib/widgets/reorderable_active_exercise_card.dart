import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../screens/exercise_info_screen.dart';
import '../services/workout_session_service.dart';
import '../theme/app_theme.dart';
import '../utils/weight_text_input_formatter.dart';

class ReorderableActiveExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final String weightUnit;
  final Set<int> expandedNotes;
  final int exerciseIndex;
  final bool isReorderMode;
  final bool isDragging;
  final bool isOtherDragging;
  final Function(int) onToggleNotes;
  final Function(String, String, {int? reps, double? weight, bool? isCompleted})
  onUpdateSet;
  final Function(String, String) onToggleSetCompletion;
  final VoidCallback onAddSet;
  final Function(String) onRemoveSet;
  final Color workoutColor;
  final DateTime? workoutStartedAt;

  const ReorderableActiveExerciseCard({
    super.key,
    required this.exercise,
    required this.weightUnit,
    required this.expandedNotes,
    required this.exerciseIndex,
    required this.isReorderMode,
    this.isDragging = false,
    this.isOtherDragging = false,
    required this.onToggleNotes,
    required this.onUpdateSet,
    required this.onToggleSetCompletion,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.workoutColor,
    required this.workoutStartedAt,
  });

  @override
  State<ReorderableActiveExerciseCard> createState() =>
      _ReorderableActiveExerciseCardState();
}

class _ReorderableActiveExerciseCardState
    extends State<ReorderableActiveExerciseCard>
    with TickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  late AnimationController _reorderModeController;
  late Animation<Color?> _borderColorAnimation;
  Color? _lastOutlineColor;
  Color? _lastWarningColor;

  @override
  void initState() {
    super.initState();
    _reorderModeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _borderColorAnimation = const AlwaysStoppedAnimation<Color?>(null);

    if (widget.isReorderMode) {
      _reorderModeController.value = 1.0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final colors = context.appColors;
    final dividerColor = Theme.of(context).dividerColor;
    if (_lastOutlineColor == dividerColor &&
        _lastWarningColor == colors.warning) {
      return;
    }

    _lastOutlineColor = dividerColor;
    _lastWarningColor = colors.warning;
    _borderColorAnimation = ColorTween(
      begin: dividerColor,
      end: colors.warning.withValues(alpha: 0.6),
    ).animate(_reorderModeController);
  }

  @override
  void didUpdateWidget(covariant ReorderableActiveExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReorderMode != oldWidget.isReorderMode) {
      if (widget.isReorderMode) {
        _reorderModeController.forward();
      } else {
        _reorderModeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _reorderModeController.dispose();
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
        if (exercise.sets[i].isCompleted) return false;
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
    final colors = context.appColors;
    final colorScheme = context.appScheme;
    return AnimatedBuilder(
      animation: _borderColorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _borderColorAnimation.value!,
              width: widget.isReorderMode ? 1.5 : 0.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.15),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(children: [_buildHeader(), _buildSetsList()]),
          Positioned(
            bottom: -15,
            right: 15,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: widget.isReorderMode
                  ? _buildAddSetButton()
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSetButton() {
    final colors = context.appColors;
    final textTheme = context.appText;

    return GestureDetector(
      onTap: () {
        widget.onAddSet();
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 120,
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
            Icon(Icons.add, color: colors.textPrimary, size: 20),
            const SizedBox(width: 4),
            Text(
              'Add Set',
              style: textTheme.labelLarge?.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                      widget.exercise.exerciseDetail?.name ??
                          widget.exercise.exerciseSlug,
                      style: textTheme.titleSmall?.copyWith(
                        color: widget.workoutColor,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.exercise.notes?.isNotEmpty ?? false)
                IconButton(
                  onPressed: () => widget.onToggleNotes(widget.exerciseIndex),
                  icon: Icon(
                    widget.expandedNotes.contains(widget.exerciseIndex)
                        ? Icons.sticky_note_2
                        : Icons.sticky_note_2_outlined,
                    color: widget.expandedNotes.contains(widget.exerciseIndex)
                        ? colors.warning
                        : colors.textTertiary,
                    size: 24,
                  ),
                  tooltip: widget.expandedNotes.contains(widget.exerciseIndex)
                      ? 'Hide notes'
                      : 'Show notes',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              SizedBox(
                width: 40,
                height: 40,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: widget.isReorderMode
                      ? ReorderableDragStartListener(
                          key: ValueKey('drag_handle_${widget.exercise.id}'),
                          index: widget.exerciseIndex,
                          child: Container(
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
                        )
                      : IconButton(
                          key: ValueKey('info_button_${widget.exercise.id}'),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () => _showExerciseInfo(context),
                          icon: Icon(
                            Icons.info_outline,
                            color: colors.textSecondary,
                            size: 28,
                          ),
                          tooltip: 'Exercise Info',
                        ),
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
                widget.exercise.notes ?? "",
                style: textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetsList() {
    final textTheme = context.appText;
    final isBodyWeight =
        widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
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
    );
  }

  Widget _buildSetRow(WorkoutSet set, int setNumber) {
    final colors = context.appColors;
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final isCompleted = set.isCompleted;
    final canComplete = _canCompleteSet(widget.exercise.id, setNumber);
    final originalSet = setNumber <= widget.exercise.sets.length
        ? widget.exercise.sets[setNumber - 1]
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isCompleted
            ? colors.success.withValues(alpha: 0.08)
            : colorScheme.surface.withValues(alpha: 0),
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
                  : "",
              goalValue: originalSet?.targetReps?.toString(),
              onChanged: (value) {
                final reps = int.tryParse(value);
                widget.onUpdateSet(
                  widget.exercise.id,
                  set.id,
                  reps: reps ?? (value.isEmpty ? 0 : null),
                );
              },
              enabled: !isCompleted,
            ),
          ),
          const SizedBox(width: 16),
          if (!(widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false))
            Expanded(
              child: _buildDecoratedSetInput(
                controllerKey: '${widget.exercise.id}_${set.id}_weight',
                initialText: (set.actualWeight ?? 0.0) > 0.0
                    ? WorkoutSessionService.instance.formatWeight(
                        set.actualWeight!,
                      )
                    : "",
                goalValue: originalSet?.targetWeight != null
                    ? WorkoutSessionService.instance.formatWeight(
                        originalSet!.targetWeight!,
                      )
                    : null,
                onChanged: (value) {
                  final weight = double.tryParse(value);
                  widget.onUpdateSet(
                    widget.exercise.id,
                    set.id,
                    weight: weight ?? (value.isEmpty ? 0.0 : null),
                  );
                },
                enabled: !isCompleted,
                showKgSuffix: true,
              ),
            ),
          if (!(widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false))
            const SizedBox(width: 16),
          SizedBox(
            width: 32,
            height: 32,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: widget.isReorderMode
                  ? IconButton(
                      key: ValueKey('remove_set_${set.id}'),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 24,
                      ),
                      onPressed: () => widget.onRemoveSet(set.id),
                    )
                  : GestureDetector(
                      key: ValueKey('complete_set_${set.id}'),
                      onTap: canComplete
                          ? () {
                              HapticFeedback.lightImpact();
                              widget.onToggleSetCompletion(
                                widget.exercise.id,
                                set.id,
                              );
                            }
                          : null,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? colors.success
                              : canComplete
                              ? colorScheme.surface.withValues(alpha: 0)
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
            ),
          ),
        ],
      ),
    );
  }

  int _decimalPlacesFor(double value) {
    // Keep up to 2 decimals, but don't force trailing zeros (e.g. 100 -> "100", 30.5 -> "30.5").
    final scaled = (value * 100).round();
    if (scaled % 100 == 0) return 0;
    if (scaled % 10 == 0) return 1;
    return 2;
  }

  String _formatGoalValue(String? goalValue) {
    if (goalValue == null || goalValue.isEmpty) return '';
    final parsed = double.tryParse(goalValue);
    if (parsed == null) return goalValue;
    final decimalPlaces = _decimalPlacesFor(parsed);
    return parsed.toStringAsFixed(decimalPlaces);
  }

  Widget _buildDecoratedSetInput({
    required String controllerKey,
    required String initialText,
    String? goalValue,
    required Function(String) onChanged,
    required bool enabled,
    bool showKgSuffix = false,
  }) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    const double goalTextFontSize = 10.0;
    const double verticalPaddingAboveMainText = 2.0;
    const double spaceBetweenMainAndGoal = 1.0;
    const double verticalPaddingBelowGoalText = 3.0;
    const double goalTextLineHeight = goalTextFontSize * 1.2;
    const double bottomPaddingForGoal =
        goalTextLineHeight +
        spaceBetweenMainAndGoal +
        verticalPaddingBelowGoalText;

    final bool showFullGoalText =
        widget.workoutStartedAt == null ||
        DateTime.now().difference(widget.workoutStartedAt!).inSeconds < 5;
    final String formattedGoalValue = _formatGoalValue(goalValue);

    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          controller: _getController(controllerKey, initialText),
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            if (showKgSuffix)
              WeightTextInputFormatter()
            else
              FilteringTextInputFormatter.digitsOnly,
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
                Future.delayed(
                  Duration.zero,
                  () => controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: controller.text.length,
                  ),
                );
              }
            }
          },
        ),
        if (formattedGoalValue.isNotEmpty)
          Positioned(
            bottom: verticalPaddingBelowGoalText,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    child: child,
                  ),
                );
              },
              child: Text(
                showFullGoalText
                    ? 'Goal: $formattedGoalValue${showKgSuffix && !(widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false) ? " ${widget.weightUnit}" : ""}'
                    : formattedGoalValue,
                key: ValueKey<bool>(
                  showFullGoalText,
                ), // Key is crucial for AnimatedSwitcher to work correctly
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  void _showExerciseInfo(BuildContext context) {
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
          ),
        ),
      );
    }
  }
}
