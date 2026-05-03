import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/workout.dart';
import '../../theme/app_theme.dart';

class ArchiveWorkoutRow extends StatelessWidget {
  final Workout workout;

  const ArchiveWorkoutRow({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    // Compact Layout:
    // [Date] [Card]
    // Date is to the left. Card takes remaining space.

    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // Reduced vertical space
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Text
          // Aligned to match the text inside the card.
          // Card height 44. Center 22.
          // Date text height ~16. Center 8.
          // Top padding = 22 - 8 = 14.
          Padding(
            padding: const EdgeInsets.only(top: 14, right: 10),
            child: SizedBox(
              width: 40,
              child: Text(
                _formatDate(
                  workout.completedAt ?? workout.startedAt ?? DateTime.now(),
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),

          // Slim Card
          Expanded(
            child: Transform.translate(
              offset: const Offset(-20, 0),
              child: Container(
                height: 44, // Reduced height
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: AppTheme.workoutCardBorderRadius,
                ),
                padding: const EdgeInsets.only(left: 20, right: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Middle: Title
                    // Use Flexible to allow centering but truncate if too long
                    Flexible(
                      child: Text(
                        workout.name,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // "Sun 30" format
    return DateFormat('E d').format(date);
  }
}
