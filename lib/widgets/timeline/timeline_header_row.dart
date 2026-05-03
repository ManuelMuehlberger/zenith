import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'award_balloons.dart';
import 'award_stack.dart';

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
    final appText = context.appText;
    final appColors = context.appColors;

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
                style: appText.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
              ),
              const Spacer(),
              AwardBalloons(awards: awards),
            ],
          ),
        ),

        // Row 2 (The Body)
        Padding(padding: const EdgeInsets.only(left: 2.0), child: child),
      ],
    );
  }
}
