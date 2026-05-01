import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../constants/app_constants.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../models/workout_template.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/create_workout/create_workout_content.dart';
import '../widgets/create_workout/create_workout_exercise_picker_section.dart';
import '../widgets/create_workout/create_workout_header.dart';
import '../widgets/create_workout/create_workout_screen_helpers.dart';
import 'exercise_picker_screen.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final WorkoutTemplate? workoutTemplate;
  final String? folderId;

  const CreateWorkoutScreen({super.key, this.workoutTemplate, this.folderId});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final Logger _logger = Logger('CreateWorkoutScreen');
  final _nameController = TextEditingController();
  final List<WorkoutExercise> _exercises = [];
  final Set<int> _expandedNotes = {};
  bool _isLoading = false;
  late Color _selectedColor;
  IconData _selectedIcon = Icons.fitness_center;
  bool _hasInitializedSelectedColor = false;

  Color _defaultSelectedColor(BuildContext context) =>
      context.appScheme.primary;

  List<Color> _availableColors(BuildContext context) => <Color>[
    context.appScheme.primary,
    context.appColors.success,
    context.appColors.warning,
    context.appScheme.error,
  ];

  Color _resolveTemplateColor(BuildContext context, int? colorValue) {
    final availableColors = _availableColors(context);
    final defaultColor = _defaultSelectedColor(context);
    if (colorValue == null) return defaultColor;

    return availableColors.firstWhere(
      (color) => color.toARGB32() == colorValue,
      orElse: () => defaultColor,
    );
  }

  @override
  void initState() {
    super.initState();
    final template = widget.workoutTemplate;
    if (template == null) return;

    _nameController.text = template.name;
    _selectedIcon = WorkoutIcons.getIconDataFromCodePoint(
      template.iconCodePoint,
    );
    unawaited(_loadTemplateExercises());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitializedSelectedColor) return;

    _selectedColor = _defaultSelectedColor(context);
    final template = widget.workoutTemplate;
    if (template != null) {
      _selectedColor = _resolveTemplateColor(context, template.colorValue);
    }
    _hasInitializedSelectedColor = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + kToolbarHeight + 24.0;

    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        final weightUnit =
            UserService.instance.currentProfile?.units == Units.imperial
            ? 'lbs'
            : 'kg';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: CreateWorkoutContent(
                  headerHeight: headerHeight,
                  nameController: _nameController,
                  selectedColor: _selectedColor,
                  selectedIcon: _selectedIcon,
                  exercises: _exercises,
                  expandedNotes: _expandedNotes,
                  weightUnit: weightUnit,
                  onIconTap: _showWorkoutCustomization,
                  onToggleNotes: _toggleNotesExpansion,
                  onRemoveExercise: _removeExercise,
                  onAddSet: _addSetToExercise,
                  onRemoveSet: _removeSetFromExercise,
                  onUpdateSet: _updateSet,
                  onUpdateNotes: _updateExerciseNotes,
                  onToggleRepRange: _toggleRepRange,
                  onReorderExercises: _reorderExercises,
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
                      color: context.appColors.overlayMedium,
                      child: SafeArea(
                        bottom: false,
                        child: CreateWorkoutHeader(
                          isEditing: widget.workoutTemplate != null,
                          exerciseCount: _exercises.length,
                          isLoading: _isLoading,
                          onClose: () => Navigator.of(context).pop(),
                          onSave: _saveWorkout,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CreateWorkoutExercisePickerSection(
                  onAddExercise: _addExercise,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveWorkout() async {
    if (_nameController.text.trim().isEmpty) {
      showCreateWorkoutErrorDialog(
        context,
        'Please enter a workout template name',
      );
      return;
    }
    if (_exercises.isEmpty) {
      showCreateWorkoutErrorDialog(context, 'Please add at least one exercise');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await saveCreateWorkoutTemplate(
        workoutTemplate: widget.workoutTemplate,
        folderId: widget.folderId,
        name: _nameController.text.trim(),
        selectedIcon: _selectedIcon,
        selectedColor: _selectedColor,
        exercises: _exercises,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        showCreateWorkoutErrorDialog(
          context,
          'Error saving workout template: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTemplateExercises() async {
    final template = widget.workoutTemplate;
    if (template == null) return;

    setState(() => _isLoading = true);
    try {
      final exercises = await loadCreateWorkoutTemplateExercises(
        template: template,
        logger: _logger,
      );
      if (mounted) {
        setState(() {
          _exercises
            ..clear()
            ..addAll(exercises);
        });
      }
    } catch (_) {
      // Silently ignore for now; UI will still allow editing.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addExercise() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExercisePickerScreen(multiSelect: true),
      ),
    );
    final selectedExercises = selectedExercisesFromResult(result);
    if (selectedExercises.isEmpty) return;

    setState(() {
      _exercises.addAll(
        createWorkoutExercisesFromExercises(
          exercises: selectedExercises,
          workoutTemplateId:
              widget.workoutTemplate?.id ?? 'PENDING_TEMPLATE_ID',
        ),
      );
    });
    unawaited(HapticFeedback.lightImpact());
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      _expandedNotes.remove(index);
      final newExpandedNotes = <int>{};
      for (final expandedIndex in _expandedNotes) {
        if (expandedIndex > index) {
          newExpandedNotes.add(expandedIndex - 1);
        } else if (expandedIndex < index) {
          newExpandedNotes.add(expandedIndex);
        }
      }
      _expandedNotes
        ..clear()
        ..addAll(newExpandedNotes);
    });
    unawaited(HapticFeedback.lightImpact());
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
    });
    unawaited(HapticFeedback.mediumImpact());
  }

  void _addSetToExercise(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    final newSet = WorkoutSet(
      workoutExerciseId: exercise.id,
      setIndex: exercise.sets.length,
      targetReps: lastSet?.targetReps,
      targetWeight: lastSet?.targetWeight,
    );

    setState(() {
      _exercises[exerciseIndex] = exercise.copyWith(
        sets: [...exercise.sets, newSet],
      );
    });
    unawaited(HapticFeedback.lightImpact());
  }

  void _removeSetFromExercise(int exerciseIndex, int setIndex) {
    final exercise = _exercises[exerciseIndex];
    if (exercise.sets.length <= 1) return;

    final updatedSets = List<WorkoutSet>.from(exercise.sets)
      ..removeAt(setIndex);
    setState(() {
      _exercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
    });
    unawaited(HapticFeedback.lightImpact());
  }

  void _updateSet(
    int exerciseIndex,
    int setIndex, {
    int? targetReps,
    double? targetWeight,
    String? type,
    int? targetRestSeconds,
  }) {
    final exercise = _exercises[exerciseIndex];
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    final currentSet = updatedSets[setIndex];
    updatedSets[setIndex] = currentSet.copyWith(
      targetReps: targetReps ?? currentSet.targetReps,
      targetWeight: targetWeight ?? currentSet.targetWeight,
      targetRestSeconds: targetRestSeconds ?? currentSet.targetRestSeconds,
    );

    _logger.fine(
      'Update set: exIdx=$exerciseIndex setIdx=$setIndex '
      'targetReps=$targetReps targetWeight=$targetWeight '
      'rest=$targetRestSeconds',
    );

    setState(() {
      _exercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
    });
  }

  void _updateExerciseNotes(int exerciseIndex, String notes) {
    setState(() {
      _exercises[exerciseIndex] = _exercises[exerciseIndex].copyWith(
        notes: notes,
      );
    });
  }

  void _toggleRepRange(int exerciseIndex, int setIndex) {
    _logger.warning(
      'Rep range toggling is not supported for template set '
      'exerciseIndex=$exerciseIndex setIndex=$setIndex',
    );
  }

  void _toggleNotesExpansion(int exerciseIndex) {
    setState(() {
      if (_expandedNotes.contains(exerciseIndex)) {
        _expandedNotes.remove(exerciseIndex);
      } else {
        _expandedNotes.add(exerciseIndex);
      }
    });
  }

  void addExerciseForTest(Exercise exercise) {
    setState(() {
      _exercises.addAll(
        createWorkoutExercisesFromExercises(
          exercises: [exercise],
          workoutTemplateId:
              widget.workoutTemplate?.id ?? 'PENDING_TEMPLATE_ID',
        ),
      );
    });
  }

  void updateSetForTest(
    int exerciseIndex,
    int setIndex, {
    int? targetReps,
    double? targetWeight,
  }) {
    _updateSet(
      exerciseIndex,
      setIndex,
      targetReps: targetReps,
      targetWeight: targetWeight,
    );
  }

  void _showWorkoutCustomization() {
    unawaited(
      showCreateWorkoutCustomizationSheet(
        context: context,
        selectedColor: _selectedColor,
        selectedIcon: _selectedIcon,
        availableColors: _availableColors(context),
        onColorChanged: (color) => setState(() => _selectedColor = color),
        onIconChanged: (icon) => setState(() => _selectedIcon = icon),
      ),
    );
  }
}
