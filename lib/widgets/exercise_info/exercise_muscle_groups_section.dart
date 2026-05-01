import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../models/exercise.dart';
import '../../theme/app_theme.dart';

class ExerciseMuscleGroupsSection extends StatelessWidget {
  final Exercise exercise;

  const ExerciseMuscleGroupsSection({super.key, required this.exercise});

  Widget _buildMuscleGroupChip(
    BuildContext context,
    String muscleGroup,
    bool isPrimary,
  ) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary
            ? colorScheme.primary.withValues(alpha: 0.2)
            : colors.field,
        border: Border.all(
          color: isPrimary ? colorScheme.primary : colors.textTertiary,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        muscleGroup,
        style: isPrimary
            ? textTheme.labelMedium?.copyWith(color: colorScheme.primary)
            : textTheme.labelMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.primaryMuscleGroup.name, style: textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Primary', style: textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    _buildMuscleGroupChip(
                      context,
                      exercise.primaryMuscleGroup.name,
                      true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.ITEM_HORIZONTAL_GAP),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Secondary', style: textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    if (exercise.secondaryMuscleGroups.isNotEmpty) ...[
                      ...exercise.secondaryMuscleGroups.map(
                        (muscle) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildMuscleGroupChip(
                            context,
                            muscle.name,
                            false,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text('None', style: textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
