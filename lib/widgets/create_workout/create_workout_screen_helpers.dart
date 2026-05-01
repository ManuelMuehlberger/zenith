import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../constants/app_constants.dart';
import '../../models/exercise.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_set.dart';
import '../../models/workout_template.dart';
import '../../services/exercise_service.dart';
import '../../services/workout_template_service.dart';
import '../workout_customization_sheet.dart';

Future<void> saveCreateWorkoutTemplate({
  required WorkoutTemplate? workoutTemplate,
  required String? folderId,
  required String name,
  required IconData selectedIcon,
  required Color selectedColor,
  required List<WorkoutExercise> exercises,
}) async {
  final template = workoutTemplate;
  if (template != null) {
    final updatedTemplate = template.copyWith(
      name: name,
      iconCodePoint: selectedIcon.codePoint,
      colorValue: selectedColor.toARGB32(),
    );
    await WorkoutTemplateService.instance.updateWorkoutTemplate(
      updatedTemplate,
    );
    await WorkoutTemplateService.instance.saveTemplateExercises(
      updatedTemplate.id,
      exercises,
    );
    return;
  }

  final newTemplate = await WorkoutTemplateService.instance
      .createWorkoutTemplate(
        name: name,
        folderId: folderId,
        iconCodePoint: selectedIcon.codePoint,
        colorValue: selectedColor.toARGB32(),
      );
  await WorkoutTemplateService.instance.saveTemplateExercises(
    newTemplate.id,
    exercises,
  );
}

Future<List<WorkoutExercise>> loadCreateWorkoutTemplateExercises({
  required WorkoutTemplate template,
  required Logger logger,
}) async {
  final templateId = template.id;
  final exercises = await WorkoutTemplateService.instance.getTemplateExercises(
    templateId,
  );

  if (ExerciseService.instance.exercises.isEmpty) {
    await ExerciseService.instance.loadExercises();
  }
  final allExercises = ExerciseService.instance.exercises;
  final withDetails = exercises.map((exercise) {
    final matches = allExercises.where(
      (item) => item.slug == exercise.exerciseSlug,
    );
    final detail = matches.isNotEmpty ? matches.first : null;
    return exercise.copyWith(exerciseDetail: detail);
  }).toList();

  logger.fine(
    'Loaded ${withDetails.length} exercises for template $templateId',
  );
  for (final exercise in withDetails) {
    final setsInfo = exercise.sets
        .map(
          (set) =>
              'idx=${set.setIndex},reps=${set.targetReps},wt=${set.targetWeight}',
        )
        .join('; ');
    logger.finer(
      'Exercise ${exercise.exerciseSlug} (${exercise.id}) sets: [$setsInfo]',
    );
  }

  return withDetails;
}

void showCreateWorkoutErrorDialog(BuildContext context, String message) {
  showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

List<Exercise> selectedExercisesFromResult(Object? result) {
  if (result is List<Exercise>) return result;
  if (result is Exercise) return [result];
  return const <Exercise>[];
}

List<WorkoutExercise> createWorkoutExercisesFromExercises({
  required Iterable<Exercise> exercises,
  required String workoutTemplateId,
}) {
  return exercises.map((selectedExercise) {
    final workoutExercise = WorkoutExercise(
      workoutTemplateId: workoutTemplateId,
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
}

Future<void> showCreateWorkoutCustomizationSheet({
  required BuildContext context,
  required Color selectedColor,
  required IconData selectedIcon,
  required List<Color> availableColors,
  required ValueChanged<Color> onColorChanged,
  required ValueChanged<IconData> onIconChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(
      context,
    ).scaffoldBackgroundColor.withValues(alpha: 0),
    isScrollControlled: true,
    builder: (context) => WorkoutCustomizationSheet(
      selectedColor: selectedColor,
      selectedIcon: selectedIcon,
      availableColors: availableColors,
      availableIcons: WorkoutIcons.items
          .map((item) => item.icon)
          .whereType<IconData>()
          .toList(),
      onColorChanged: onColorChanged,
      onIconChanged: onIconChanged,
    ),
  );
}
