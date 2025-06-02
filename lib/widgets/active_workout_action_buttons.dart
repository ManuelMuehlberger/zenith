import 'package:flutter/material.dart';

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
    return Column(
      children: [
        _buildAddExerciseButton(),
        if (showAbortButton) _buildAbortButton(),
      ],
    );
  }

  Widget _buildAddExerciseButton() {
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
            backgroundColor: Colors.green.withAlpha((255 * 0.1).round()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.green.withAlpha((255 * 0.3).round()),
                width: 1,
              ),
            ),
          ),
          icon: const Icon(
            Icons.add,
            color: Colors.green,
            size: 20,
          ),
          label: const Text(
            'Add Exercise',
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAbortButton() {
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
            backgroundColor: Colors.red.withAlpha((255 * 0.1).round()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red, width: 1),
            ),
          ),
          child: const Text(
            'Abort Workout',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
