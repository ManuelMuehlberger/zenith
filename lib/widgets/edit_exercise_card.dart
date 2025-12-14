import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:pull_down_button/pull_down_button.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../services/user_service.dart';
import '../services/workout_session_service.dart';
import '../screens/exercise_info_screen.dart';
import '../constants/app_constants.dart';

class EditExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final bool isNotesExpanded;
  final Function(int) onToggleNotes;
  final Function(int) onRemoveExercise;
  final Function(int) onAddSet;
  final Function(int, int) onRemoveSet;
  final Function(int, int, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) onUpdateSet;
  final Function(int, String) onUpdateNotes;
  final Function(int, int) onToggleRepRange;
  final String weightUnit;

  const EditExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.isNotesExpanded,
    required this.onToggleNotes,
    required this.onRemoveExercise,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    required this.onUpdateNotes,
    required this.onToggleRepRange,
    required this.weightUnit,
  });

  @override
  State<EditExerciseCard> createState() => _EditExerciseCardState();
}

class _EditExerciseCardState extends State<EditExerciseCard> with TickerProviderStateMixin {
  late Map<String, TextEditingController> _controllers;
  late TextEditingController _notesController;
  late AnimationController _reorderModeController;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _reorderModeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _borderColorAnimation = ColorTween(
      begin: AppConstants.CARD_STROKE_COLOR,
      end: AppConstants.ACCENT_COLOR_ORANGE.withAlpha((255 * 0.6).round()),
    ).animate(_reorderModeController);
  }

  void _initializeControllers() {
    _controllers = {};
    
    for (final set in widget.exercise.sets) {
      final repsKey = 'reps_${widget.exercise.id}_${set.id}';
      final weightKey = 'weight_${widget.exercise.id}_${set.id}';
      
      _controllers[repsKey] = TextEditingController(
        text: set.targetReps?.toString() ?? '',
      );
      _controllers[weightKey] = TextEditingController(
        text: set.targetWeight != null ? WorkoutSessionService.instance.formatWeight(set.targetWeight!) : '',
      );
    }
    
    _notesController = TextEditingController(text: widget.exercise.notes ?? '');
  }

  @override
  void didUpdateWidget(EditExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.exercise.id != widget.exercise.id) {
      _disposeControllers();
      _initializeControllers();
      return;
    }

    // Update controllers for current sets
    final currentSetIds = widget.exercise.sets.map((s) => s.id).toSet();
    final existingKeys = _controllers.keys.toSet();
    
    // Remove controllers for sets that no longer exist
    final keysToRemove = existingKeys.where((key) {
      final setId = key.split('_').last;
      return !currentSetIds.contains(setId);
    }).toList();
    
    for (final key in keysToRemove) {
      _controllers.remove(key)?.dispose();
    }

    // Add or update controllers for all current sets
    for (final set in widget.exercise.sets) {
      final repsKey = 'reps_${widget.exercise.id}_${set.id}';
      final weightKey = 'weight_${widget.exercise.id}_${set.id}';
      
      if (!_controllers.containsKey(repsKey)) {
        _controllers[repsKey] = TextEditingController(
          text: set.targetReps?.toString() ?? '',
        );
      } else {
        // Update existing controller with new value
        final controller = _controllers[repsKey]!;
        final newText = set.targetReps?.toString() ?? '';
        if (controller.text != newText) {
          controller.text = newText;
        }
      }
      
      if (!_controllers.containsKey(weightKey)) {
        _controllers[weightKey] = TextEditingController(
          text: set.targetWeight != null ? WorkoutSessionService.instance.formatWeight(set.targetWeight!) : '',
        );
      } else {
        // Update existing controller with new value
        final controller = _controllers[weightKey]!;
        final newText = set.targetWeight != null ? WorkoutSessionService.instance.formatWeight(set.targetWeight!) : '';
        if (controller.text != newText) {
          controller.text = newText;
        }
      }
    }
    
    // Update notes controller if needed
    if (_notesController.text != (widget.exercise.notes ?? '')) {
      _notesController.text = widget.exercise.notes ?? '';
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _notesController.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    _reorderModeController.dispose();
    super.dispose();
  }

  TextEditingController _getController(String controllerKey, String textToInitializeWith) {
    if (!_controllers.containsKey(controllerKey)) {
      _controllers[controllerKey] = TextEditingController(text: textToInitializeWith);
    }
    return _controllers[controllerKey]!;
  }

  String get _weightUnit {
    return UserService.instance.currentProfile?.units == Units.imperial ? 'lbs' : 'kg';
  }

  void _showExerciseInfo(BuildContext context) {
    if (widget.exercise.exerciseDetail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseInfoScreen(
            exercise: widget.exercise.exerciseDetail!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exercise details not available for ${widget.exercise.exerciseSlug}',
            style: AppConstants.IOS_BODY_TEXT_STYLE,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(widget.exercise.id),
      margin: const EdgeInsets.only(bottom: 20.0),
      child: AnimatedBuilder(
        animation: _borderColorAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: AppConstants.CARD_BG_COLOR,
              borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
              border: Border.all(
                color: _borderColorAnimation.value!,
                width: AppConstants.CARD_STROKE_WIDTH,
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
              child: _buildAddSetButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSetButton() {
    return GestureDetector(
      onTap: () {
        widget.onAddSet(widget.exerciseIndex);
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
                    onPressed: () => widget.onToggleNotes(widget.exerciseIndex),
                    icon: Icon(
                      widget.isNotesExpanded
                        ? Icons.sticky_note_2
                        : Icons.sticky_note_2_outlined,
                      color: widget.isNotesExpanded
                        ? Colors.amber
                        : (widget.exercise.notes?.isNotEmpty ?? false)
                          ? Colors.amber.withAlpha(150)
                          : Colors.grey[500],
                      size: 24,
                    ),
                    tooltip: widget.isNotesExpanded ? 'Hide notes' : 'Show notes',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                  PullDownButton(
                    itemBuilder: (context) => [
                      PullDownMenuItem(
                        onTap: () => _showExerciseInfo(context),
                        title: 'Exercise Info',
                        icon: Icons.info_outline,
                      ),
                      PullDownMenuItem(
                        onTap: () => widget.onRemoveExercise(widget.exerciseIndex),
                        title: 'Remove Exercise',
                        icon: Icons.delete_outline,
                        isDestructive: true,
                      ),
                    ],
                    buttonBuilder: (context, showMenu) => IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                    index: widget.exerciseIndex,
                    child: Container(
                      width: 40,
                      height: 40,
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
                  ),
                ],
              ),
            ],
          ),
          if (widget.isNotesExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextFormField(
                controller: _notesController,
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
                onChanged: (value) => widget.onUpdateNotes(widget.exerciseIndex, value),
              ),
            ),
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
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            child: Row(
              children: [
                const SizedBox(width: 28), // Set number space
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
                const SizedBox(width: 32), // Action button space
              ],
            ),
          ),
          // Sets
          ...widget.exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 4.0),
              child: _buildSetRow(set, setIndex),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSetRow(WorkoutSet set, int setIndex) {
    final isBodyWeight = widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
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
          // Reps input
          Flexible(
            child: _buildSetInput(
              controllerKey: 'reps_${widget.exercise.id}_${set.id}',
              initialText: set.targetReps?.toString() ?? "",
              onChanged: (value) {
                final reps = int.tryParse(value);
                widget.onUpdateSet(widget.exerciseIndex, setIndex, targetReps: reps ?? (value.isEmpty ? 0 : null));
              },
            ),
          ),
          const SizedBox(width: 16),
          // Weight input (if not bodyweight)
          if (!isBodyWeight) ...[
            Flexible(
              child: _buildSetInput(
                controllerKey: 'weight_${widget.exercise.id}_${set.id}',
                initialText: set.targetWeight != null 
                    ? WorkoutSessionService.instance.formatWeight(set.targetWeight!) 
                    : "",
                onChanged: (value) {
                  final weight = double.tryParse(value);
                  widget.onUpdateSet(widget.exerciseIndex, setIndex, targetWeight: weight ?? (value.isEmpty ? 0.0 : null));
                },
                showWeightSuffix: true,
              ),
            ),
            const SizedBox(width: 16),
          ],
          // Remove set button
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 24),
              onPressed: () {
                if (widget.exercise.sets.length > 1) {
                  widget.onRemoveSet(widget.exerciseIndex, setIndex);
                } else {
                  widget.onRemoveExercise(widget.exerciseIndex);
                }
                HapticFeedback.lightImpact();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetInput({
    required String controllerKey,
    required String initialText,
    required Function(String) onChanged,
    bool showWeightSuffix = false,
  }) {
    return TextFormField(
      controller: _getController(controllerKey, initialText),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          showWeightSuffix ? RegExp(r'^\d*\.?\d{0,2}') : RegExp(r'^\d*')
        )
      ],
      textAlign: TextAlign.center,
      style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(
        color: AppConstants.TEXT_PRIMARY_COLOR,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
        suffixText: showWeightSuffix ? _weightUnit : null,
        suffixStyle: AppConstants.IOS_SUBTEXT_STYLE,
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
            color: Colors.blue.withAlpha((255 * 0.5).round()),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: onChanged,
      onTap: () {
        if (_controllers.containsKey(controllerKey)) {
          final controller = _controllers[controllerKey]!;
          if (controller.text.isNotEmpty) {
            // Store the future and cancel any previous one to prevent "Timer is still pending" errors in tests
            // This ensures that if a new tap occurs before the previous Future.delayed completes,
            // the previous one is effectively cancelled, preventing the test framework from
            // complaining about pending timers.
            // Removed Future.delayed to prevent "Timer is still pending" errors in tests.
            // The text selection on tap is not critical for test logic and can be handled synchronously.
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          }
        }
      },
    );
  }
}
