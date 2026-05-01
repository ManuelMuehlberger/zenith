import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../edit_workout_action_buttons.dart';

class CreateWorkoutExercisePickerSection extends StatelessWidget {
  final VoidCallback onAddExercise;

  const CreateWorkoutExercisePickerSection({
    super.key,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.appScheme.surface)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 5.0,
            bottom: 5.0,
          ),
          child: EditWorkoutActionButtons(onAddExercise: onAddExercise),
        ),
      ),
    );
  }
}
