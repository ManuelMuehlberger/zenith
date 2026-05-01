import 'package:flutter/material.dart';
import '../models/workout_set.dart';
import '../theme/app_theme.dart';

class SetEditOptionsSheet extends StatelessWidget {
  final WorkoutSet set;
  final int setIndex;
  final bool canRemoveSet;
  final VoidCallback onToggleRepRange;
  final VoidCallback? onRemoveSet;

  const SetEditOptionsSheet({
    super.key,
    required this.set,
    required this.setIndex,
    required this.canRemoveSet,
    required this.onToggleRepRange,
    this.onRemoveSet,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: colors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Text('Set ${setIndex + 1} Options', style: textTheme.titleMedium),

            const SizedBox(height: 16),

            if (canRemoveSet && onRemoveSet != null)
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete, color: colorScheme.error, size: 20),
                ),
                title: Text('Remove Set', style: textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  onRemoveSet!();
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
