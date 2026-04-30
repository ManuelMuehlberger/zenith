import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
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
            padding: const EdgeInsets.only(top: 14, right: 12),
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
            child: Container(
              height: 44, // Reduced height
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppThemeColors.outline,
                  width: AppConstants.CARD_STROKE_WIDTH,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center content
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
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // "Sun 30" format
    return DateFormat('E d').format(date);
  }
}
