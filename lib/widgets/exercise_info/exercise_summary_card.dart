import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/app_constants.dart';
import '../../models/insights.dart';
import '../../utils/unit_converter.dart';
import '../../services/user_service.dart';

class ExerciseSummaryCard extends StatelessWidget {
  final ExerciseInsights insights;

  const ExerciseSummaryCard({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E), // iOS dark grouped background
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
                  color: AppConstants.ACCENT_COLOR,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Summary',
                    style: TextStyle(
                      color: AppConstants.ACCENT_COLOR,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
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
                  value: insights.totalSessions.toString(),
                  label: 'Sessions',
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  value: insights.totalSets.toString(),
                  label: 'Sets',
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  value: insights.totalReps.toString(),
                  label: 'Reps',
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  value: _formatWeight(insights.maxWeight),
                  label: 'Max',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.TEXT_TERTIARY_COLOR,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
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
