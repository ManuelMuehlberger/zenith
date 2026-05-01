import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EditWorkoutActionButtons extends StatelessWidget {
  final VoidCallback onAddExercise;

  const EditWorkoutActionButtons({super.key, required this.onAddExercise});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;

    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: CupertinoButton(
          color: colors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          padding: EdgeInsets.zero,
          onPressed: onAddExercise,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.add, color: colors.success, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                'Add Exercise',
                style: textTheme.labelLarge?.copyWith(color: colors.success),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
