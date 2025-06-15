import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_session.dart';
import '../services/workout_session_service.dart';
import '../screens/exercise_info_screen.dart';

class ActiveExerciseCard extends StatefulWidget {
  final SessionExercise exercise;
  final String weightUnit;
  final Set<int> expandedNotes;
  final int exerciseIndex;
  final Function(int) onToggleNotes;
  final Function(String, String, {int? reps, double? weight, bool? isCompleted}) onUpdateSet;
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
    // Dispose all controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  TextEditingController _getController(String controllerKey, String textToInitializeWith) {
    if (!_controllers.containsKey(controllerKey)) {
      _controllers[controllerKey] = TextEditingController(text: textToInitializeWith);
    }
    // If controller exists, return it. Its text is managed by user input.
    return _controllers[controllerKey]!;
  }

  // Helper method to determine if a set can be completed (sequential completion)
  bool _canCompleteSet(String exerciseId, int setNumber) {
    final exercise = widget.exercise;
    
    // Check if setNumber is valid
    if (setNumber < 1 || setNumber > exercise.sets.length) return false;
    
    final currentSet = exercise.sets[setNumber - 1];
    
    // If this set is already completed, check if it can be uncompleted
    if (currentSet.isCompleted) {
      // Can only uncheck if all sets after this one are unchecked (reverse order)
      for (int i = setNumber; i < exercise.sets.length; i++) {
        if (exercise.sets[i].isCompleted) {
          return false; // Cannot uncheck because a later set is still checked
        }
      }
      return true; // Can uncheck because all later sets are unchecked
    }
    
    // For uncompleted sets, check if they can be completed (forward order)
    // For the first set, it can always be completed
    if (setNumber == 1) return true;
    
    // For other sets, check if the previous set is completed
    if (setNumber - 2 >= 0 && setNumber - 2 < exercise.sets.length) {
      final previousSet = exercise.sets[setNumber - 2];
      return previousSet.isCompleted;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!.withAlpha((255 * 0.3).round()),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Exercise header with notes
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 2.0),
            child: Column(
              children: [
                // Top row with exercise info and buttons
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.exercise.workoutExercise.exerciseDetail?.name ?? widget.exercise.workoutExercise.exerciseSlug,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.exercise.workoutExercise.exerciseDetail?.primaryMuscleGroup ?? "N/A",
                            style: TextStyle(
                              color: Colors.blue[300],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notes toggle button
                    if (widget.exercise.workoutExercise.notes?.isNotEmpty ?? false)
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
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    // Info button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => _showExerciseInfo(context),
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 24,
                        ),
                        tooltip: 'Exercise Info',
                      ),
                    ),
                  ],
                ),
                
                // Notes field integrated in header (read-only)
                    if (widget.expandedNotes.contains(widget.exerciseIndex) && 
                    widget.exercise.workoutExercise.notes != null && widget.exercise.workoutExercise.notes!.isNotEmpty) ...[
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
                      widget.exercise.workoutExercise.notes ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Sets list
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Column(
              children: [
                // Header row with labels
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
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Weight',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildSetRow(SessionSet set, int setNumber) {
    final isCompleted = set.isCompleted;
    final canComplete = _canCompleteSet(widget.exercise.id, setNumber);
    
    // Find the original workout set to get target values
    final originalSet = setNumber <= widget.exercise.workoutExercise.sets.length
        ? widget.exercise.workoutExercise.sets[setNumber - 1]
        : null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isCompleted 
            ? Colors.green.withAlpha((255 * 0.08).round())
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Set number
          Container(
            width: 28,
            height: 42, 
            decoration: BoxDecoration(
              color: isCompleted 
                  ? Colors.green 
                  : canComplete 
                      ? Colors.grey[700] 
                      : Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                setNumber.toString(),
                style: TextStyle(
                  color: canComplete || isCompleted ? Colors.white : Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Reps input
          Expanded(
            child: _buildDecoratedSetInput(
              controllerKey: '${widget.exercise.id}_${set.id}_reps',
              initialText: set.reps > 0 ? set.reps.toString() : "",
              goalValue: originalSet?.targetReps?.toString(), // Use targetReps, repRange removed
              lastValue: set.lastReps != null && set.lastReps! > 0 ? set.lastReps.toString() : null,
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
          
          // Weight input
          Expanded(
            child: _buildDecoratedSetInput(
              controllerKey: '${widget.exercise.id}_${set.id}_weight',
              initialText: set.weight > 0.0 ? WorkoutSessionService.instance.formatWeight(set.weight) : "",
              goalValue: originalSet?.targetWeight != null
                  ? WorkoutSessionService.instance.formatWeight(originalSet!.targetWeight!)
                  : null, // Use targetWeight
              lastValue: set.lastWeight != null && set.lastWeight! > 0.0 ? WorkoutSessionService.instance.formatWeight(set.lastWeight!) : null,
              onChanged: (value) {
                final weight = double.tryParse(value);
                if (weight != null) {
                  widget.onUpdateSet(widget.exercise.id, set.id, weight: weight);
                } else if (value.isEmpty) {
                  widget.onUpdateSet(widget.exercise.id, set.id, weight: 0.0);
                }
              },
              enabled: !isCompleted,
              showKgSuffix: true,
            ),
          ),
          const SizedBox(width: 16),
          
          // Completion button
          GestureDetector(
            onTap: canComplete ? () {
              HapticFeedback.lightImpact();
              widget.onToggleSetCompletion(widget.exercise.id, set.id);
            } : null,
            child: Container(
              width: 32,
              height: 32, // Square shape
              decoration: BoxDecoration(
                color: isCompleted 
                    ? Colors.green 
                    : canComplete 
                        ? Colors.transparent 
                        : Colors.grey[800],
                border: Border.all(
                  color: isCompleted 
                      ? Colors.green 
                      : canComplete 
                          ? Colors.grey[600]! 
                          : Colors.grey[700]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : !canComplete
                      ? Icon(
                          Icons.lock_outline,
                          color: Colors.grey[500],
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
    final Color goalTextColor = Colors.grey[500]!;

    String valueToInitializeControllerWith = initialText;
    if (lastValue != null && lastValue.isNotEmpty) {
      valueToInitializeControllerWith = lastValue;
    }
    if (showKgSuffix ? (valueToInitializeControllerWith == "0.0" || valueToInitializeControllerWith == "0") : (valueToInitializeControllerWith == "0")) {
      valueToInitializeControllerWith = "";
    }

    // Define nominal heights/font sizes for calculation
    const double mainTextFontSize = 18.0;
    const double goalTextFontSize = 10.0;
    const double verticalPaddingAboveMainText = 2.0;
    const double spaceBetweenMainAndGoal = 1.0;
    const double verticalPaddingBelowGoalText = 3.0;
    const double goalTextLineHeight = goalTextFontSize * 1.2;
    final double bottomPaddingForGoal = goalTextLineHeight + spaceBetweenMainAndGoal + verticalPaddingBelowGoalText;
    

    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          controller: _getController(controllerKey, valueToInitializeControllerWith),
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(showKgSuffix ? r'^\d*\.?\d{0,2}' : r'^\d*'))
          ],
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey[600],
            fontSize: mainTextFontSize,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey[800]!.withAlpha((255 * 0.5).round()) : Colors.grey[850],
            suffixText: showKgSuffix ? widget.weightUnit : null,
            suffixStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
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
              borderSide: BorderSide(color: Colors.blue.withAlpha((255 * 0.5).round()), width: 1),
            ),
            contentPadding: EdgeInsets.fromLTRB(12, verticalPaddingAboveMainText, 12, bottomPaddingForGoal),
          ),
          onChanged: onChanged,
          onTap: () {
            if (_controllers.containsKey(controllerKey)) {
              final controller = _controllers[controllerKey]!;
              if (controller.text.isNotEmpty) {
                Future.delayed(Duration.zero, () {
                  controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
                });
              }
            }
          },
        ),
        if (goalValue != null && goalValue.isNotEmpty)
          Positioned(
            bottom: verticalPaddingBelowGoalText,
            child: Text(
              'Goal: $goalValue${showKgSuffix ? " ${widget.weightUnit}" : ""}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: goalTextColor,
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
    if (widget.exercise.workoutExercise.exerciseDetail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseInfoScreen(exercise: widget.exercise.workoutExercise.exerciseDetail!),
        ),
      );
    } else {
      // Optionally show a message that details are not available or try to fetch them
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exercise details not available for ${widget.exercise.workoutExercise.exerciseSlug}')),
      );
    }
  }
}
