import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CreateWorkoutHeader extends StatelessWidget {
  final bool isEditing;
  final int exerciseCount;
  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onSave;

  const CreateWorkoutHeader({
    super.key,
    required this.isEditing,
    required this.exerciseCount,
    required this.isLoading,
    required this.onClose,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: colors.textPrimary, size: 28),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEditing ? 'Edit Workout' : 'Create Workout',
                    style: textTheme.titleLarge,
                  ),
                  if (exerciseCount > 0)
                    Text(
                      '$exerciseCount '
                      '${exerciseCount == 1 ? 'exercise' : 'exercises'}',
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: isLoading ? null : onSave,
              style: TextButton.styleFrom(
                backgroundColor: colors.surfaceAlt,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: colors.success.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.success,
                      ),
                    )
                  : Text(
                      'Save',
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.success,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
