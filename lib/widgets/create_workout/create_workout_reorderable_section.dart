import 'package:flutter/material.dart';

import '../../models/workout_exercise.dart';
import '../../theme/app_theme.dart';
import '../edit_exercise_card.dart';

class CreateWorkoutReorderableSection extends StatelessWidget {
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

  const CreateWorkoutReorderableSection({
    super.key,
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
    if (exercises.isEmpty) {
      return const SizedBox(height: 400, child: CreateWorkoutEmptyState());
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: exercises.length,
      onReorder: onReorderExercises,
      itemBuilder: (context, index) {
        return EditExerciseCard(
          key: ValueKey(exercises[index].id),
          exercise: exercises[index],
          exerciseIndex: index,
          isNotesExpanded: expandedNotes.contains(index),
          onToggleNotes: onToggleNotes,
          onRemoveExercise: onRemoveExercise,
          onAddSet: onAddSet,
          onRemoveSet: onRemoveSet,
          onUpdateSet: onUpdateSet,
          onUpdateNotes: onUpdateNotes,
          onToggleRepRange: onToggleRepRange,
          weightUnit: weightUnit,
        );
      },
    );
  }
}

class CreateWorkoutEmptyState extends StatelessWidget {
  const CreateWorkoutEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.appScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 40,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text('No exercises added yet', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Add exercises to build your workout',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
