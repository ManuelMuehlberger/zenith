import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../services/workout_timeline_grouping_service.dart';
import '../../theme/app_theme.dart';

class MonthSummaryCard extends StatefulWidget {
  final MonthlyWorkoutGroup group;
  final bool isExpanded;
  final VoidCallback onTap;

  const MonthSummaryCard({
    super.key,
    required this.group,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<MonthSummaryCard> createState() => _MonthSummaryCardState();
}

class _MonthSummaryCardState extends State<MonthSummaryCard> {
  bool _isPressed = false;

  String _formatVolume(double weight) {
    if (weight.abs() >= 1000) {
      return '${(weight / 1000).toStringAsFixed(0)}k';
    }
    return weight.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final now = DateTime.now();
    final isCurrentMonth =
        widget.group.key.year == now.year &&
        widget.group.key.month == now.month;
    final title = isCurrentMonth ? 'Current Month' : widget.group.key.monthName;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      // Hit Test: Ensure the hit test area spans the full width of the screen
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isPressed ? 0.5 : 1.0,
        child: Padding(
          // Adjust padding to align with the node
          // Node is at 23px center. TimelineRow padding left is trackWidth (46).
          // We want Title to start after a gap.
          // If we assume TimelineRow handles the Node, we just need to layout the rest.
          padding: const EdgeInsets.only(top: 12, bottom: 12, right: 16),
          child: Row(
            children: [
              // Title
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const Spacer(),

              // Stats (Right justified)
              Text(
                '${widget.group.workoutCount} workouts • ${_formatVolume(widget.group.totalVolume)} kg',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 8),

              // Chevron
              Icon(
                widget.isExpanded
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                color: colorScheme.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
