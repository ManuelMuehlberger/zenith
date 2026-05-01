import 'package:flutter/material.dart';

import '../../models/workout_exercise.dart';
import '../edit_workout_name_section.dart';
import '../workout_metrics_widget.dart';

class CreateWorkoutTemplateConfigurationSection extends StatelessWidget {
  final TextEditingController nameController;
  final Color selectedColor;
  final IconData selectedIcon;
  final VoidCallback onIconTap;
  final List<WorkoutExercise> exercises;

  const CreateWorkoutTemplateConfigurationSection({
    super.key,
    required this.nameController,
    required this.selectedColor,
    required this.selectedIcon,
    required this.onIconTap,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EditWorkoutNameSection(
          nameController: nameController,
          selectedColor: selectedColor,
          selectedIcon: selectedIcon,
          onIconTap: onIconTap,
        ),
        WorkoutMetricsWidget(exercises: exercises),
      ],
    );
  }
}
