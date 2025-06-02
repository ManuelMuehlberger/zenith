import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../services/workout_service.dart';
import '../services/user_service.dart';
import '../widgets/edit_workout_name_section.dart';
import '../widgets/edit_exercise_card.dart';
import '../widgets/edit_workout_action_buttons.dart';
import '../widgets/workout_customization_sheet.dart';
import 'exercise_picker_screen.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final Workout? workout;
  final String? folderId;

  const CreateWorkoutScreen({
    super.key,
    this.workout,
    this.folderId,
  });

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
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
  
  final List<IconData> _availableIcons = [
    Icons.fitness_center,
    Icons.sports_gymnastics,
    Icons.sports_handball,
    Icons.sports_martial_arts,
    Icons.sports_tennis,
    Icons.sports_basketball,
    Icons.sports_soccer,
    Icons.sports_football,
    Icons.sports_volleyball,
    Icons.sports_baseball,
    Icons.sports_hockey,
    Icons.sports_rugby,
    Icons.sports_cricket,
    Icons.sports_golf,
    Icons.sports_mma,
    Icons.sports_kabaddi,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _nameController.text = widget.workout!.name;
      _exercises = List.from(widget.workout!.exercises);
      _selectedColor = widget.workout!.color;
      _selectedIcon = widget.workout!.icon;
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
    final double headerHeight = topPadding + kToolbarHeight + 24.0; // Increased header height by 24.0

    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        final String weightUnit = (UserService.instance.currentProfile?.units == 'imperial') ? 'lbs' : 'kg';
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Main content - allow scrolling behind header
              Positioned.fill(
                child: _buildMainContent(headerHeight, weightUnit),
              ),
              // Glass header overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      height: headerHeight,
                      color: Colors.black54,
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
                    color: Colors.black, // Match scaffold background
                    border: Border(top: BorderSide(color: Color(0xFF222222))), // Subtle top border
                  ),
                  child: SafeArea( 
                    top: false, // We only care about bottom SafeArea
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 5.0, bottom: 5.0), // Reduced top/bottom padding
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
    final isEditing = widget.workout != null;
    
    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Close button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            
            // Title section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEditing ? 'Edit Workout' : 'Create Workout',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_exercises.isNotEmpty)
                    Text(
                      '${_exercises.length} exercise${_exercises.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Save button
                TextButton(
                  onPressed: _isLoading ? null : _saveWorkout,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.withAlpha((255 * 0.1).round()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
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
                            color: Colors.blue,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
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
        
        // Exercises content
        SliverToBoxAdapter(
          child: _buildExercisesContent(weightUnit),
        ),
        // Add padding at the bottom for the action button
        SliverToBoxAdapter(
          child: SizedBox(height:100.0),
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
      _showErrorDialog('Please enter a workout name');
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
      if (widget.workout != null) {
        // Update existing workout
        final updatedWorkout = widget.workout!.copyWith(
          name: _nameController.text.trim(),
          exercises: _exercises,
          iconCodePoint: _selectedIcon.codePoint,
          colorValue: _selectedColor.toARGB32(),
        );
        await WorkoutService.instance.updateWorkout(updatedWorkout);
      } else {
        // Create new workout
        final workout = await WorkoutService.instance.createWorkout(
          _nameController.text.trim(),
          folderId: widget.folderId,
        );
        
        // Update the workout with exercises, icon, and color
        final updatedWorkout = workout.copyWith(
          exercises: _exercises,
          iconCodePoint: _selectedIcon.codePoint,
          colorValue: _selectedColor.toARGB32(),
        );
        await WorkoutService.instance.updateWorkout(updatedWorkout);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error saving workout: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    final selectedExercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (context) => const ExercisePickerScreen(),
      ),
    );

    if (selectedExercise != null) {
      final defaultSet = WorkoutSet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reps: 10,
        weight: 0.0,
      );

      final workoutExercise = WorkoutExercise(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exercise: selectedExercise,
        sets: [defaultSet],
      );

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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reps: lastSet?.reps ?? 10,
      weight: lastSet?.weight ?? 0.0,
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

  void _updateSet(int exerciseIndex, int setIndex, {int? reps, double? weight, int? repRangeMin, int? repRangeMax}) {
    final exercise = _exercises[exerciseIndex];
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(
      reps: reps,
      weight: weight,
      repRangeMin: repRangeMin,
      repRangeMax: repRangeMax,
    );

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
    final exercise = _exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    
    if (set.isRepRange) {
      // Convert from rep range to single reps
      final updatedSets = List<WorkoutSet>.from(exercise.sets);
      updatedSets[setIndex] = WorkoutSet(
        id: set.id,
        reps: set.repRangeMin ?? 10,
        weight: set.weight,
        isCompleted: set.isCompleted,
        repRangeMin: null,
        repRangeMax: null,
      );
      
      setState(() {
        _exercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
      });
    } else {
      // Convert from single reps to rep range
      final updatedSets = List<WorkoutSet>.from(exercise.sets);
      updatedSets[setIndex] = WorkoutSet(
        id: set.id,
        reps: set.reps,
        weight: set.weight,
        isCompleted: set.isCompleted,
        repRangeMin: set.reps,
        repRangeMax: set.reps + 2,
      );
      
      setState(() {
        _exercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);
      });
    }
    HapticFeedback.lightImpact();
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

  void _showWorkoutCustomization() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WorkoutCustomizationSheet(
        selectedColor: _selectedColor,
        selectedIcon: _selectedIcon,
        availableColors: _availableColors,
        availableIcons: _availableIcons,
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
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 40,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No exercises added yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add exercises to build your workout',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
