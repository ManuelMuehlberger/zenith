import 'package:flutter/material.dart';
import '../../models/exercise.dart';

class ExerciseInstructionsSection extends StatelessWidget {
  final Exercise exercise;

  const ExerciseInstructionsSection({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          if (exercise.instructions.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercise.instructions.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey[800], height: 24),
              itemBuilder: (context, index) {
                final instruction = exercise.instructions[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        instruction,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[200],
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
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'No instructions available for this exercise',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
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
