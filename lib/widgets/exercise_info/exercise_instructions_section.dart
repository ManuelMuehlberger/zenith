import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../theme/app_theme.dart';

class ExerciseInstructionsSection extends StatelessWidget {
  final Exercise exercise;

  const ExerciseInstructionsSection({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Instructions', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          if (exercise.instructions.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercise.instructions.length,
              separatorBuilder: (context, index) => Divider(
                color: colors.textPrimary.withValues(alpha: 0.12),
                height: 24,
              ),
              itemBuilder: (context, index) {
                final instruction = exercise.instructions[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        instruction,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.info_outline, color: colors.textTertiary, size: 20),
                const SizedBox(width: 12),
                Text(
                  'No instructions available for this exercise',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
