import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/muscle_group.dart';
import '../../constants/app_constants.dart';

class ExerciseMuscleGroupsSection extends StatelessWidget {
  final Exercise exercise;

  const ExerciseMuscleGroupsSection({
    super.key,
    required this.exercise,
  });

  Widget _buildMuscleGroupChip(BuildContext context, String muscleGroup, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.blue.withAlpha((255 * 0.2).round()) : Colors.grey[800],
        border: Border.all(
          color: isPrimary ? Colors.blue : Colors.grey[600]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        muscleGroup,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isPrimary ? Colors.blue : Colors.grey[300],
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
Text(
  exercise.primaryMuscleGroup.name,
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.grey[400],
      ),
),
          const SizedBox(height: 16),
          // Single row with Primary and Secondary side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary section
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildMuscleGroupChip(context, exercise.primaryMuscleGroup.name, true),
                  ],
                ),
              ),
              SizedBox(width: AppConstants.ITEM_HORIZONTAL_GAP), // Space between columns
              // Secondary section
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secondary',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (exercise.secondaryMuscleGroups.isNotEmpty) ...[
                      // List secondary muscles vertically
...exercise.secondaryMuscleGroups
    .map((muscle) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildMuscleGroupChip(context, muscle.name, false),
        ))
    ,
                    ] else ...[
                      Text(
                        'None',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                      ),
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
