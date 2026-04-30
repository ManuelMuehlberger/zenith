import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import 'award_stack.dart';
import 'award_balloons.dart';

class TimelineHeaderRow extends StatelessWidget {
  final String dateText;
  final List<Award> awards;
  final Widget child;

  const TimelineHeaderRow({
    super.key,
    required this.dateText,
    required this.awards,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1 (The Header)
        // Align with the TimelineNode which is centered at y=18 in the parent TimelineRow.
        // Adding top padding to align the text center with y=18.
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Row(
            children: [
              Text(
                dateText,
                style: AppConstants.IOS_SUBTITLE_TEXT_STYLE.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.TEXT_PRIMARY_COLOR,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              AwardBalloons(awards: awards),
            ],
          ),
        ),
        
        // Row 2 (The Body)
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: child,
        ),
      ],
    );
  }
}
