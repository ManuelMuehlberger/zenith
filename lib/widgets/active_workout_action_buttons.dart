import 'package:flutter/material.dart';
import 'package:zenith/theme/app_theme.dart';

class ActiveWorkoutActionButtons extends StatelessWidget {
  final VoidCallback onAddExercise;
  final VoidCallback onAbortWorkout;
  final bool showAbortButton;

  const ActiveWorkoutActionButtons({
    super.key,
    required this.onAddExercise,
    required this.onAbortWorkout,
    this.showAbortButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final colors = context.appColors;

    return Column(
      children: [
        _buildAddExerciseButton(colors),
        if (showAbortButton) _buildAbortButton(colorScheme),
      ],
    );
  }

  Widget _buildAddExerciseButton(AppThemeTokens colors) {
    // If abort button is shown, this one doesn't need bottom padding for spacing,
    // as abort button's top padding will handle it.
    // If abort button is NOT shown, this one needs bottom padding.
    final double bottomPadding = showAbortButton ? 0.0 : 20.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, bottomPadding),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onAddExercise,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.success.withValues(alpha: 0.1),
            foregroundColor: colors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colors.success.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Exercise'),
        ),
      ),
    );
  }

  Widget _buildAbortButton(ColorScheme colorScheme) {
    // This button is only shown if showAbortButton is true.
    // It needs top padding to separate from AddExercise, and bottom padding for overall spacing.
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onAbortWorkout,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error.withValues(alpha: 0.1),
            foregroundColor: colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.error, width: 1),
            ),
          ),
          child: const Text('Abort Workout'),
        ),
      ),
    );
  }
}
