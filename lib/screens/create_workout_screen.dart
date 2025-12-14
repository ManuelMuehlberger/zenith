import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../models/workout_template.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../services/workout_template_service.dart';
import '../services/user_service.dart';
import '../widgets/edit_workout_name_section.dart';
import '../widgets/edit_exercise_card.dart';
import '../widgets/edit_workout_action_buttons.dart';
import '../widgets/workout_customization_sheet.dart';
import '../widgets/workout_metrics_widget.dart';
import 'exercise_picker_screen.dart';
import '../constants/app_constants.dart';
import '../services/exercise_service.dart';
import 'package:logging/logging.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final WorkoutTemplate? workoutTemplate;
  final String? folderId;

  const CreateWorkoutScreen({
    super.key,
    this.workoutTemplate,
    this.folderId,
  });

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final Logger _logger = Logger('CreateWorkoutScreen');
  final _nameController = TextEditingController();
  List<WorkoutExercise> _exercises = [];
  bool _isLoading = false;
  final Set<int> _expandedNotes = {};
  
  // Workout customization
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.fitness_center;
  
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.workoutTemplate != null) {
      _nameController.text = widget.workoutTemplate!.name;
      // WorkoutTemplate doesn't have exercises directly, we'll need to load them separately
      // For now, initialize as empty and load exercises in a separate method if needed
      _exercises = [];
      _selectedColor = widget.workoutTemplate!.colorValue != null 
          ? Color(widget.workoutTemplate!.colorValue!) 
          : Colors.blue;
      _selectedIcon = WorkoutIcons.getIconDataFromCodePoint(widget.workoutTemplate!.iconCodePoint);

      // Load template exercises and attach details
      _loadTemplateExercises();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight + 24.0;

    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        final String weightUnit = (UserService.instance.currentProfile?.units == Units.imperial) ? 'lbs' : 'kg';
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: _buildMainContent(headerHeight, weightUnit),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                    child: Container(
                      height: headerHeight,
                      color: AppConstants.HEADER_BG_COLOR_MEDIUM,
                      child: SafeArea(
                        bottom: false,
                        child: _buildHeaderContent(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    border: Border(top: BorderSide(color: Color(0xFF222222))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 5.0, bottom: 5.0),
                      child: EditWorkoutActionButtons(
                        onAddExercise: _addExercise,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderContent() {
    final isEditing = widget.workoutTemplate != null;
    
    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEditing ? 'Edit Workout' : 'Create Workout',
                    style: AppConstants.HEADER_SMALL_TITLE_TEXT_STYLE,
                  ),
                  if (_exercises.isNotEmpty)
                  Text(
                    '${_exercises.length} ${_exercises.length == 1 ? 'exercise' : 'exercises'}',
                    style: AppConstants.IOS_SUBTEXT_STYLE,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveWorkout,
              style: TextButton.styleFrom(
                backgroundColor: AppConstants.FINISH_BUTTON_BG_COLOR,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: AppConstants.ACCENT_COLOR_GREEN.withAlpha((255 * 0.3).round()),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.ACCENT_COLOR_GREEN,
                      ),
                    )
                  : Text(
                      'Save',
                      style: AppConstants.HEADER_BUTTON_TEXT_STYLE.copyWith(color: AppConstants.ACCENT_COLOR_GREEN),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double headerHeight, String weightUnit) {
    return CustomScrollView(
      slivers: [
        // Space for header
        SliverToBoxAdapter(
          child: SizedBox(height: headerHeight),
        ),
        
        // Workout name section
        SliverToBoxAdapter(
          child: EditWorkoutNameSection(
            nameController: _nameController,
            selectedColor: _selectedColor,
            selectedIcon: _selectedIcon,
            onIconTap: _showWorkoutCustomization,
          ),
        ),
        
        // Workout metrics
        SliverToBoxAdapter(
          child: WorkoutMetricsWidget(
            exercises: _exercises,
          ),
        ),
        
        // Exercises content
        SliverToBoxAdapter(
          child: _buildExercisesContent(weightUnit),
        ),
        // Add padding at the bottom for the action button
        SliverToBoxAdapter(
          child: SizedBox(height: 150.0),
        ),
      ],
    );
  }

  Widget _buildExercisesContent(String weightUnit) {
    if (_exercises.isEmpty) {
      return Column(
        children: [
          SizedBox(
            height: 400,
            child: _buildEmptyState(),
          ),
        ],
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _exercises.length,
      onReorder: _reorderExercises,
      itemBuilder: (context, index) {
        
        return EditExerciseCard(
          key: ValueKey(_exercises[index].id),
          exercise: _exercises[index],
          exerciseIndex: index,
          isNotesExpanded: _expandedNotes.contains(index),
          onToggleNotes: _toggleNotesExpansion,
          onRemoveExercise: _removeExercise,
          onAddSet: _addSetToExercise,
          onRemoveSet: _removeSetFromExercise,
          onUpdateSet: _updateSet,
          onUpdateNotes: _updateExerciseNotes,
          onToggleRepRange: _toggleRepRange,
          weightUnit: weightUnit,
        );
      },
    );
  }

  Future<void> _saveWorkout() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a workout template name');
      return;
    }

    if (_exercises.isEmpty) {
      _showErrorDialog('Please add at least one exercise');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.workoutTemplate != null) {
        // Update existing workout template metadata and exercises
        final updatedTemplate = widget.workoutTemplate!.copyWith(
          name: _nameController.text.trim(),
          iconCodePoint: _selectedIcon.codePoint,
          colorValue: _selectedColor.toARGB32(),
        );
        await WorkoutTemplateService.instance.updateWorkoutTemplate(updatedTemplate);
        await WorkoutTemplateService.instance.saveTemplateExercises(updatedTemplate.id, _exercises);
      } else {
        // Create new workout template and persist its exercises
        final newTemplate = await WorkoutTemplateService.instance.createWorkoutTemplate(
          name: _nameController.text.trim(),
          folderId: widget.folderId,
          iconCodePoint: _selectedIcon.codePoint,
          colorValue: _selectedColor.toARGB32(),
        );
        await WorkoutTemplateService.instance.saveTemplateExercises(newTemplate.id, _exercises);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error saving workout template: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTemplateExercises() async {
    if (widget.workoutTemplate == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final templateId = widget.workoutTemplate!.id;
      final exercises = await WorkoutTemplateService.instance.getTemplateExercises(templateId);

      // Ensure ExerciseService has data to attach details for UI
      if (ExerciseService.instance.exercises.isEmpty) {
        await ExerciseService.instance.loadExercises();
      }
      final allExercises = ExerciseService.instance.exercises;

      final withDetails = exercises.map((e) {
        final matches = allExercises.where((ex) => ex.slug == e.exerciseSlug);
        final detail = matches.isNotEmpty ? matches.first : null;
        return e.copyWith(exerciseDetail: detail);
      }).toList();

      _logger.fine('Loaded ${withDetails.length} exercises for template $templateId');
      for (final ex in withDetails) {
        final setsInfo = ex.sets.map((s) => 'idx=${s.setIndex},reps=${s.targetReps},wt=${s.targetWeight}').join('; ');
        _logger.finer('Exercise ${ex.exerciseSlug} (${ex.id}) sets: [$setsInfo]');
      }

      if (mounted) {
        setState(() {
          _exercises = withDetails;
        });
      }
    } catch (_) {
      // Silently ignore for now; UI will still allow editing
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addExercise() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExercisePickerScreen(multiSelect: true),
      ),
    );

    if (result is List<Exercise>) {
      final newWorkoutExercises = result.map((selectedExercise) {
        var workoutExercise = WorkoutExercise(
          workoutTemplateId: widget.workoutTemplate?.id ?? "PENDING_TEMPLATE_ID",
          exerciseSlug: selectedExercise.slug,
          exerciseDetail: selectedExercise,
          sets: const [],
        );

        final defaultSet = WorkoutSet(
          workoutExerciseId: workoutExercise.id,
          setIndex: 0,
          targetReps: 10,
          targetWeight: 0.0,
        );

        return workoutExercise.copyWith(sets: [defaultSet]);
      }).toList();

      setState(() {
        _exercises.addAll(newWorkoutExercises);
      });

      HapticFeedback.lightImpact();
    } else if (result is Exercise) {
      // Handle single exercise selection for backward compatibility
      final selectedExercise = result;
      var workoutExercise = WorkoutExercise(
        workoutTemplateId: widget.workoutTemplate?.id ?? "PENDING_TEMPLATE_ID",
        exerciseSlug: selectedExercise.slug,
        exerciseDetail: selectedExercise,
        sets: const [],
      );

      final defaultSet = WorkoutSet(
        workoutExerciseId: workoutExercise.id,
        setIndex: 0,
        targetReps: 10,
        targetWeight: 0.0,
      );

      workoutExercise = workoutExercise.copyWith(sets: [defaultSet]);

      setState(() {
        _exercises.add(workoutExercise);
      });

      HapticFeedback.lightImpact();
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      _expandedNotes.remove(index);
      // Adjust expanded notes indices
      final newExpandedNotes = <int>{};
      for (final expandedIndex in _expandedNotes) {
        if (expandedIndex > index) {
          newExpandedNotes.add(expandedIndex - 1);
        } else if (expandedIndex < index) {
          newExpandedNotes.add(expandedIndex);
        }
      }
      _expandedNotes.clear();
      _expandedNotes.addAll(newExpandedNotes);
    });
    HapticFeedback.lightImpact();
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
    });
    HapticFeedback.mediumImpact();
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
    HapticFeedback.lightImpact();
  }

  void _removeSetFromExercise(int exerciseIndex, int setIndex) {
    final exercise = _exercises[exerciseIndex];
    if (exercise.sets.length > 1) {
      final updatedSets = List<WorkoutSet>.from(exercise.sets);
      updatedSets.removeAt(setIndex);
      
      setState(() {
        _exercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
      });
      HapticFeedback.lightImpact();
    }
  }

  void _updateSet(int exerciseIndex, int setIndex, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {
    final exercise = _exercises[exerciseIndex];
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    final currentSet = updatedSets[setIndex];
    
    // Only update the fields that are provided, preserve existing values for others
    updatedSets[setIndex] = currentSet.copyWith(
      targetReps: targetReps ?? currentSet.targetReps,
      targetWeight: targetWeight ?? currentSet.targetWeight,
      targetRestSeconds: targetRestSeconds ?? currentSet.targetRestSeconds,
    );

    _logger.fine('Update set: exIdx=$exerciseIndex setIdx=$setIndex targetReps=$targetReps targetWeight=$targetWeight rest=$targetRestSeconds');

    setState(() {
      _exercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
    });
  }

  void _updateExerciseNotes(int exerciseIndex, String notes) {
    setState(() {
      _exercises[exerciseIndex] = _exercises[exerciseIndex].copyWith(notes: notes);
    });
  }

  void _toggleRepRange(int exerciseIndex, int setIndex) {
    // final exercise = _exercises[exerciseIndex];
    // final set = exercise.sets[setIndex];
    
    // isRepRange, repRangeMin, repRangeMax were removed from WorkoutSet.
    // This functionality needs to be re-evaluated or removed.
    // For now, making it a no-op to fix compilation.
    debugPrint("Toggling rep range is currently not supported for template sets.");
    
    // if (set.isRepRange) {
    //   // Convert from rep range to single reps
    //   final updatedSets = List<WorkoutSet>.from(exercise.sets);
    //   updatedSets[setIndex] = WorkoutSet(
    //     id: set.id,
    //     targetReps: set.targetReps ?? 10, // Was repRangeMin
    //     targetWeight: set.targetWeight,
    //     // repRangeMin: null,
    //     // repRangeMax: null,
    //   );
      
    //   setState(() {
    //     _exercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
    //   });
    // } else {
    //   // Convert from single reps to rep range
    //   final updatedSets = List<WorkoutSet>.from(exercise.sets);
    //   updatedSets[setIndex] = WorkoutSet(
    //     id: set.id,
    //     targetReps: set.targetReps,
    //     targetWeight: set.targetWeight,
    //     // repRangeMin: set.targetReps,
    //     // repRangeMax: (set.targetReps ?? 0) + 2,
    //   );
      
    //   setState(() {
    //     _exercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
    //   });
    // }
    // HapticFeedback.lightImpact();
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

  // Method to be called from tests to add an exercise
  void addExerciseForTest(Exercise exercise) {
    final workoutExercise = WorkoutExercise(
      workoutTemplateId: widget.workoutTemplate?.id ?? "PENDING_TEMPLATE_ID",
      exerciseSlug: exercise.slug,
      exerciseDetail: exercise,
      sets: [
        WorkoutSet(
          workoutExerciseId: 'temp_id', // This will be replaced by the actual ID
          setIndex: 0,
          targetReps: 10,
          targetWeight: 0.0,
        ),
      ],
    );
    setState(() {
      _exercises.add(workoutExercise);
    });
  }

  // Method to be called from tests to update a set
  void updateSetForTest(int exerciseIndex, int setIndex, {int? targetReps, double? targetWeight}) {
    _updateSet(exerciseIndex, setIndex, targetReps: targetReps, targetWeight: targetWeight);
  }

  void _showWorkoutCustomization() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WorkoutCustomizationSheet(
        selectedColor: _selectedColor,
        selectedIcon: _selectedIcon,
        availableColors: _availableColors,
        availableIcons: WorkoutIcons.items.where((item) => item.isIcon).map((item) => item.icon!).toList(),
        onColorChanged: (color) {
          setState(() {
            _selectedColor = color;
          });
        },
        onIconChanged: (icon) {
          setState(() {
            _selectedIcon = icon;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppConstants.WORKOUT_BUTTON_BG_COLOR,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 40,
              color: AppConstants.TEXT_TERTIARY_COLOR,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No exercises added yet',
            style: AppConstants.IOS_TITLE_TEXT_STYLE,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add exercises to build your workout',
            style: AppConstants.IOS_SUBTITLE_TEXT_STYLE,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
