import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../services/workout_session_service.dart';
import '../screens/exercise_info_screen.dart';
import '../constants/app_constants.dart';

class ReorderableActiveExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final String weightUnit;
  final Set<int> expandedNotes;
  final int exerciseIndex;
  final bool isReorderMode;
  final bool isDragging;
  final bool isOtherDragging;
  final Function(int) onToggleNotes;
  final Function(String, String, {int? reps, double? weight, bool? isCompleted}) onUpdateSet;
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
  State<ReorderableActiveExerciseCard> createState() => _ReorderableActiveExerciseCardState();
}

class _ReorderableActiveExerciseCardState extends State<ReorderableActiveExerciseCard> with TickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  late AnimationController _reorderModeController;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _reorderModeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _borderColorAnimation = ColorTween(
      begin: AppConstants.CARD_STROKE_COLOR,
      end: AppConstants.ACCENT_COLOR_ORANGE.withAlpha((255 * 0.6).round()),
    ).animate(_reorderModeController);

    if (widget.isReorderMode) {
      _reorderModeController.value = 1.0;
    }
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

  TextEditingController _getController(String controllerKey, String textToInitializeWith) {
    if (!_controllers.containsKey(controllerKey)) {
      _controllers[controllerKey] = TextEditingController(text: textToInitializeWith);
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
    return AnimatedBuilder(
      animation: _borderColorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.CARD_BG_COLOR,
            borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
            border: Border.all(
              color: _borderColorAnimation.value!,
              width: widget.isReorderMode ? 1.5 : AppConstants.CARD_STROKE_WIDTH,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.15).round()),
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
          Column(
            children: [
              _buildHeader(),
              _buildSetsList(),
            ],
          ),
          Positioned(
            bottom: -15,
            right: 15,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: widget.isReorderMode ? _buildAddSetButton() : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSetButton() {
    return GestureDetector(
      onTap: () {
        widget.onAddSet();
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 120,
        height: 36,
        decoration: BoxDecoration(
          color: AppConstants.ACCENT_COLOR_ORANGE,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              'Add Set',
              style: AppConstants.HEADER_BUTTON_TEXT_STYLE.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                      widget.exercise.exerciseDetail?.name ?? widget.exercise.exerciseSlug,
                      style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(
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
                      ? Colors.amber
                      : Colors.grey[500],
                    size: 24,
                  ),
                  tooltip: widget.expandedNotes.contains(widget.exerciseIndex) ? 'Hide notes' : 'Show notes',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              SizedBox(
                width: 40,
                height: 40,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: widget.isReorderMode
                      ? ReorderableDragStartListener(
                          key: ValueKey('drag_handle_${widget.exercise.id}'),
                          index: widget.exerciseIndex,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppConstants.ACCENT_COLOR_ORANGE.withAlpha((255 * 0.2).round()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.drag_handle,
                              color: AppConstants.ACCENT_COLOR_ORANGE,
                              size: 24,
                            ),
                          ),
                        )
                      : IconButton(
                          key: ValueKey('info_button_${widget.exercise.id}'),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () => _showExerciseInfo(context),
                          icon: Icon(Icons.info_outline, color: AppConstants.TEXT_SECONDARY_COLOR, size: 28),
                          tooltip: 'Exercise Info',
                        ),
                ),
              ),
            ],
          ),
          if (widget.expandedNotes.contains(widget.exerciseIndex) &&
              widget.exercise.notes != null && widget.exercise.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!, width: 1),
              ),
              child: Text(
                widget.exercise.notes ?? "",
                style: AppConstants.IOS_SUBTEXT_STYLE,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetsList() {
    final isBodyWeight = widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false;
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
                  child: Text('Reps', textAlign: TextAlign.center, style: AppConstants.IOS_SUBTEXT_STYLE),
                ),
                if (!isBodyWeight) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('Weight', textAlign: TextAlign.center, style: AppConstants.IOS_SUBTEXT_STYLE),
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
    final isCompleted = set.isCompleted;
    final canComplete = _canCompleteSet(widget.exercise.id, setNumber);
    final originalSet = setNumber <= widget.exercise.sets.length ? widget.exercise.sets[setNumber - 1] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withAlpha((255 * 0.08).round()) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 42,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : canComplete ? Colors.grey[700] : Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                setNumber.toString(),
                style: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(
                  color: canComplete || isCompleted ? AppConstants.TEXT_PRIMARY_COLOR : AppConstants.TEXT_TERTIARY_COLOR,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDecoratedSetInput(
              controllerKey: '${widget.exercise.id}_${set.id}_reps',
              initialText: (set.actualReps ?? 0) > 0 ? set.actualReps.toString() : "",
              goalValue: originalSet?.targetReps?.toString(),
              onChanged: (value) {
                final reps = int.tryParse(value);
                widget.onUpdateSet(widget.exercise.id, set.id, reps: reps ?? (value.isEmpty ? 0 : null));
              },
              enabled: !isCompleted,
            ),
          ),
          const SizedBox(width: 16),
          if (!(widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false))
            Expanded(
              child: _buildDecoratedSetInput(
                controllerKey: '${widget.exercise.id}_${set.id}_weight',
                initialText: (set.actualWeight ?? 0.0) > 0.0 ? WorkoutSessionService.instance.formatWeight(set.actualWeight!) : "",
                goalValue: originalSet?.targetWeight != null ? WorkoutSessionService.instance.formatWeight(originalSet!.targetWeight!) : null,
                onChanged: (value) {
                  final weight = double.tryParse(value);
                  widget.onUpdateSet(widget.exercise.id, set.id, weight: weight ?? (value.isEmpty ? 0.0 : null));
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
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: widget.isReorderMode
                  ? IconButton(
                      key: ValueKey('remove_set_${set.id}'),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 24),
                      onPressed: () => widget.onRemoveSet(set.id),
                    )
                  : GestureDetector(
                      key: ValueKey('complete_set_${set.id}'),
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
                          color: isCompleted ? Colors.green : canComplete ? Colors.transparent : Colors.grey[800],
                          border: Border.all(
                              color: isCompleted
                                  ? Colors.green
                                  : canComplete
                                      ? Colors.grey[600]!
                                      : Colors.grey[700]!,
                              width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : !canComplete
                                ? Icon(Icons.lock_outline, color: Colors.grey[500], size: 16)
                                : null,
                      ),
                    ),
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
    required Function(String) onChanged,
    required bool enabled,
    bool showKgSuffix = false,
  }) {
    const double mainTextFontSize = 18.0;
    const double goalTextFontSize = 10.0;
    const double verticalPaddingAboveMainText = 2.0;
    const double spaceBetweenMainAndGoal = 1.0;
    const double verticalPaddingBelowGoalText = 3.0;
    const double goalTextLineHeight = goalTextFontSize * 1.2;
    final double bottomPaddingForGoal = goalTextLineHeight + spaceBetweenMainAndGoal + verticalPaddingBelowGoalText;

    final bool showFullGoalText = widget.workoutStartedAt == null || DateTime.now().difference(widget.workoutStartedAt!).inSeconds < 5;

    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          controller: _getController(controllerKey, initialText),
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(showKgSuffix ? r'^\d*\.?\d{0,2}' : r'^\d*'))],
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.top,
          style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(color: enabled ? AppConstants.TEXT_PRIMARY_COLOR : AppConstants.TEXT_TERTIARY_COLOR),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey[800]!.withAlpha((255 * 0.5).round()) : Colors.grey[850],
            suffixText: showKgSuffix ? widget.weightUnit : null,
            suffixStyle: AppConstants.IOS_SUBTEXT_STYLE,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blue.withAlpha((255 * 0.5).round()), width: 1)),
            contentPadding: EdgeInsets.fromLTRB(12, verticalPaddingAboveMainText, 12, bottomPaddingForGoal),
          ),
          onChanged: onChanged,
          onTap: () {
            if (_controllers.containsKey(controllerKey)) {
              final controller = _controllers[controllerKey]!;
              if (controller.text.isNotEmpty) {
                Future.delayed(Duration.zero, () => controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length));
              }
            }
          },
        ),
        if (goalValue != null && goalValue.isNotEmpty)
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
                    ? 'Goal: $goalValue${showKgSuffix && !(widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false) ? " ${widget.weightUnit}" : ""}'
                    : goalValue,
                key: ValueKey<bool>(showFullGoalText), // Key is crucial for AnimatedSwitcher to work correctly
                textAlign: TextAlign.center,
                style: AppConstants.IOS_SUBTEXT_STYLE,
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
        MaterialPageRoute(builder: (context) => ExerciseInfoScreen(exercise: widget.exercise.exerciseDetail!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exercise details not available for ${widget.exercise.exerciseSlug}')),
      );
    }
  }
}
