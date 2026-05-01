import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart' show Units;
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../screens/exercise_info_screen.dart';
import '../services/user_service.dart';
import '../services/workout_session_service.dart';
import '../theme/app_theme.dart';
import '../utils/weight_text_input_formatter.dart';
import 'edit_exercise/edit_exercise_card_sections.dart';

class EditExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final bool isNotesExpanded;
  final Function(int) onToggleNotes;
  final Function(int) onRemoveExercise;
  final Function(int) onAddSet;
  final Function(int, int) onRemoveSet;
  final Function(
    int,
    int, {
    int? targetReps,
    double? targetWeight,
    String? type,
    int? targetRestSeconds,
  })
  onUpdateSet;
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

class _EditExerciseCardState extends State<EditExerciseCard>
    with TickerProviderStateMixin {
  late Map<String, TextEditingController> _controllers;
  late TextEditingController _notesController;
  late AnimationController _reorderModeController;
  late Animation<Color?> _borderColorAnimation;
  Color? _lastOutlineColor;
  Color? _lastWarningColor;

  // Track focus for each weight field to avoid overwriting user input mid-typing.
  final Map<String, FocusNode> _weightFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _reorderModeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _borderColorAnimation = const AlwaysStoppedAnimation<Color?>(null);
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

  void _initializeControllers() {
    _controllers = {};

    for (final set in widget.exercise.sets) {
      final repsKey = 'reps_${widget.exercise.id}_${set.id}';
      final weightKey = 'weight_${widget.exercise.id}_${set.id}';

      _controllers[repsKey] = TextEditingController(
        text: set.targetReps?.toString() ?? '',
      );
      _controllers[weightKey] = TextEditingController(
        text: set.targetWeight != null
            ? WorkoutSessionService.instance.formatWeight(set.targetWeight!)
            : '',
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
          text: set.targetWeight != null
              ? WorkoutSessionService.instance.formatWeight(set.targetWeight!)
              : '',
        );
      } else {
        // Update existing controller with new value, BUT never overwrite while the user is editing.
        final controller = _controllers[weightKey]!;
        final newText = set.targetWeight != null
            ? WorkoutSessionService.instance.formatWeight(set.targetWeight!)
            : '';
        final isEditing = _weightFocusNodes[weightKey]?.hasFocus ?? false;

        if (!isEditing && controller.text != newText) {
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

    for (final node in _weightFocusNodes.values) {
      node.dispose();
    }
    _weightFocusNodes.clear();

    _notesController.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
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

  String get _weightUnit {
    return UserService.instance.currentProfile?.units == Units.imperial
        ? 'lbs'
        : 'kg';
  }

  int _decimalPlacesFor(double value) {
    // Keep up to 2 decimals, but don't force trailing zeros (e.g. 100 -> "100", 30.5 -> "30.5").
    final scaled = (value * 100).round();
    if (scaled % 100 == 0) return 0;
    if (scaled % 10 == 0) return 1;
    return 2;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final colors = context.appColors;

    return Container(
      key: ValueKey(widget.exercise.id),
      margin: const EdgeInsets.only(bottom: 20.0),
      child: AnimatedBuilder(
        animation: _borderColorAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _borderColorAnimation.value!,
                width: 0.5,
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
              child: EditExerciseAddSetButton(
                onPressed: () => widget.onAddSet(widget.exerciseIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return EditExerciseHeader(
      exercise: widget.exercise,
      exerciseIndex: widget.exerciseIndex,
      isNotesExpanded: widget.isNotesExpanded,
      notesController: _notesController,
      onToggleNotes: widget.onToggleNotes,
      onRemoveExercise: widget.onRemoveExercise,
      onShowExerciseInfo: () => _showExerciseInfo(context),
      onUpdateNotes: (value) =>
          widget.onUpdateNotes(widget.exerciseIndex, value),
    );
  }

  Widget _buildSetsList() {
    final isBodyWeight =
        widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false;
    return EditExerciseSetsList(
      isBodyWeight: isBodyWeight,
      sets: widget.exercise.sets,
      rowBuilder: _buildSetRow,
    );
  }

  Widget _buildSetRow(WorkoutSet set, int setIndex) {
    final isBodyWeight =
        widget.exercise.exerciseDetail?.isBodyWeightExercise ?? false;

    return EditExerciseSetRow(
      setIndex: setIndex,
      isBodyWeight: isBodyWeight,
      repsInput: _buildSetInput(
        controllerKey: 'reps_${widget.exercise.id}_${set.id}',
        initialText: set.targetReps?.toString() ?? '',
        onChanged: (value) {
          final reps = int.tryParse(value);
          widget.onUpdateSet(
            widget.exerciseIndex,
            setIndex,
            targetReps: reps ?? (value.isEmpty ? 0 : null),
          );
        },
      ),
      weightInput: isBodyWeight
          ? null
          : _buildSetInput(
              controllerKey: 'weight_${widget.exercise.id}_${set.id}',
              initialText: set.targetWeight != null
                  ? WorkoutSessionService.instance.formatWeight(
                      set.targetWeight!,
                    )
                  : '',
              onChanged: (value) {
                final weight = double.tryParse(value);
                widget.onUpdateSet(
                  widget.exerciseIndex,
                  setIndex,
                  targetWeight: weight ?? (value.isEmpty ? 0.0 : null),
                );
              },
              showWeightSuffix: true,
            ),
      onRemove: () {
        if (widget.exercise.sets.length > 1) {
          widget.onRemoveSet(widget.exerciseIndex, setIndex);
        } else {
          widget.onRemoveExercise(widget.exerciseIndex);
        }
      },
    );
  }

  Widget _buildSetInput({
    required String controllerKey,
    required String initialText,
    required Function(String) onChanged,
    bool showWeightSuffix = false,
  }) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    final controller = _getController(controllerKey, initialText);

    // Normalize + clamp weight and commit to model on blur.
    void commitWeightIfNeeded() {
      if (!showWeightSuffix) return;

      final raw = controller.text.trim();
      if (raw.isEmpty) {
        onChanged('');
        return;
      }

      final normalized = raw.replaceAll(',', '.');
      final parsed = double.tryParse(normalized);
      if (parsed == null) return;

      // Clamp and round to 2 decimals.
      final clamped = parsed.clamp(0.0, 999.0);
      final rounded = (clamped * 100).roundToDouble() / 100;

      final formatted = rounded.toStringAsFixed(_decimalPlacesFor(rounded));

      if (controller.text != formatted) {
        controller.text = formatted;
        controller.selection = TextSelection.collapsed(
          offset: formatted.length,
        );
      }

      // Ensure stored numeric value reflects the committed value.
      onChanged(formatted);
    }

    final FocusNode? focusNode = showWeightSuffix
        ? _weightFocusNodes.putIfAbsent(controllerKey, () {
            final node = FocusNode();
            node.addListener(() {
              if (!node.hasFocus) {
                commitWeightIfNeeded();
              }
            });
            return node;
          })
        : null;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        if (showWeightSuffix)
          WeightTextInputFormatter()
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      textAlign: TextAlign.center,
      style: textTheme.titleSmall?.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.field.withValues(alpha: 0.5),
        suffixText: showWeightSuffix ? _weightUnit : null,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        // Normalize commas while typing so parsing stays stable.
        if (showWeightSuffix && value.contains(',')) {
          final normalized = value.replaceAll(',', '.');
          controller.value = controller.value.copyWith(
            text: normalized,
            selection: TextSelection.collapsed(offset: normalized.length),
            composing: TextRange.empty,
          );
          onChanged(normalized);
          return;
        }
        onChanged(value);
      },
      onTap: () {
        if (controller.text.isNotEmpty) {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        }
      },
    );
  }
}
