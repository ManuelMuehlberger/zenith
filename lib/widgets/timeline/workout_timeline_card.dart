import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../models/workout.dart';
import '../timeline/award_stack.dart';

class WorkoutTimelineCard extends StatelessWidget {
  final Workout workout;
  final String primaryMetricsLabel;

  /// Used for workouts shown inside an expanded month. Makes the card a bit
  /// more compact to communicate hierarchy.
  final bool compact;

  const WorkoutTimelineCard({
    super.key,
    required this.workout,
    required this.primaryMetricsLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact ? const EdgeInsets.all(10) : const EdgeInsets.all(12);
    final titleStyle = AppConstants.CARD_TITLE_TEXT_STYLE.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: compact ? 16 : 18,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.CARD_STROKE_COLOR,
          width: AppConstants.CARD_STROKE_WIDTH,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.18).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    workout.name,
                    style: titleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 4 : 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    primaryMetricsLabel,
                    style: AppConstants.IOS_SUBTITLE_TEXT_STYLE.copyWith(
                      color: const Color(0xFFB7B7B7),
                      height: 1.1,
                      fontSize: compact ? 13 : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
