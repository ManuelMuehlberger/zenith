import 'package:flutter/material.dart';

import '../../models/workout_exercise.dart';
import 'create_workout_reorderable_section.dart';
import 'create_workout_template_configuration_section.dart';

class CreateWorkoutContent extends StatelessWidget {
  final double headerHeight;
  final TextEditingController nameController;
  final Color selectedColor;
  final IconData selectedIcon;
  final VoidCallback onIconTap;
  final List<WorkoutExercise> exercises;
  final Set<int> expandedNotes;
  final String weightUnit;
  final void Function(int) onToggleNotes;
  final void Function(int) onRemoveExercise;
  final void Function(int) onAddSet;
  final void Function(int, int) onRemoveSet;
  final void Function(
    int,
    int, {
    int? targetReps,
    double? targetWeight,
    String? type,
    int? targetRestSeconds,
  })
  onUpdateSet;
  final void Function(int, String) onUpdateNotes;
  final void Function(int, int) onToggleRepRange;
  final void Function(int, int) onReorderExercises;

  const CreateWorkoutContent({
    super.key,
    required this.headerHeight,
    required this.nameController,
    required this.selectedColor,
    required this.selectedIcon,
    required this.onIconTap,
    required this.exercises,
    required this.expandedNotes,
    required this.weightUnit,
    required this.onToggleNotes,
    required this.onRemoveExercise,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    required this.onUpdateNotes,
    required this.onToggleRepRange,
    required this.onReorderExercises,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
        SliverToBoxAdapter(
          child: CreateWorkoutTemplateConfigurationSection(
            nameController: nameController,
            selectedColor: selectedColor,
            selectedIcon: selectedIcon,
            onIconTap: onIconTap,
            exercises: exercises,
          ),
        ),
        SliverToBoxAdapter(
          child: CreateWorkoutReorderableSection(
            exercises: exercises,
            expandedNotes: expandedNotes,
            weightUnit: weightUnit,
            onToggleNotes: onToggleNotes,
            onRemoveExercise: onRemoveExercise,
            onAddSet: onAddSet,
            onRemoveSet: onRemoveSet,
            onUpdateSet: onUpdateSet,
            onUpdateNotes: onUpdateNotes,
            onToggleRepRange: onToggleRepRange,
            onReorderExercises: onReorderExercises,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 150.0)),
      ],
    );
  }
}
