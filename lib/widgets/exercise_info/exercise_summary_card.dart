import 'package:flutter/cupertino.dart';

import '../../constants/app_constants.dart';
import '../../models/insights.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/unit_converter.dart';

class ExerciseSummaryCard extends StatelessWidget {
  final ExerciseInsights insights;

  const ExerciseSummaryCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  CupertinoIcons.chart_bar_square_fill,
                  color: colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Summary',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Stats List
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem(
                  context: context,
                  value: insights.totalSessions.toString(),
                  label: 'Sessions',
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  context: context,
                  value: insights.totalSets.toString(),
                  label: 'Sets',
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  context: context,
                  value: insights.totalReps.toString(),
                  label: 'Reps',
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  context: context,
                  value: _formatWeight(insights.maxWeight),
                  label: 'Max',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String value,
    required String label,
  }) {
    final textTheme = context.appText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodySmall),
        Text(value, style: textTheme.titleSmall),
      ],
    );
  }

  String _formatWeight(double weight) {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    final unitLabel = UnitConverter.getWeightUnit(units.name);
    final kUnitLabel = units == Units.imperial ? 'k lbs' : 'k kg';

    if (weight > 999) {
      return '${(weight / 1000).toStringAsFixed(1)}$kUnitLabel';
    }
    return '${weight.toStringAsFixed(0)} $unitLabel';
  }
}
