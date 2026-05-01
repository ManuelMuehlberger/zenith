import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class PerformanceMetricsCard extends StatelessWidget {
  final int currentMonthWorkouts;
  final double currentMonthVolume;
  final int lastMonthWorkouts;
  final double lastMonthVolume;

  const PerformanceMetricsCard({
    super.key,
    required this.currentMonthWorkouts,
    required this.currentMonthVolume,
    required this.lastMonthWorkouts,
    required this.lastMonthVolume,
  });

  String _formatVolume(double volume) {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    final isImperial = units == Units.imperial;
    final unitLabel = isImperial ? 'lbs' : 'kg';

    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k $unitLabel';
    }
    return '${volume.toStringAsFixed(0)} $unitLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricColumn(
              context: context,
              label: 'THIS MONTH',
              count: currentMonthWorkouts,
              volume: currentMonthVolume,
            ),
          ),
          Expanded(
            child: _buildMetricColumn(
              context: context,
              label: 'LAST MONTH',
              count: lastMonthWorkouts,
              volume: lastMonthVolume,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required BuildContext context,
    required String label,
    required int count,
    required double volume,
  }) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$count',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' Workouts',
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _formatVolume(volume),
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textTertiary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
