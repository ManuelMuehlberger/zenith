import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../utils/unit_converter.dart';
import '../../services/user_service.dart';
import '../../models/user_data.dart';

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
      // Removed decoration (transparent background)
      child: Row(
        children: [
          Expanded(
            child: _buildMetricColumn(
              label: 'THIS MONTH',
              count: currentMonthWorkouts,
              volume: currentMonthVolume,
              isCurrent: true,
            ),
          ),
          // Removed vertical divider to make it cleaner
          Expanded(
            child: _buildMetricColumn(
              label: 'LAST MONTH',
              count: lastMonthWorkouts,
              volume: lastMonthVolume,
              isCurrent: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required String label,
    required int count,
    required double volume,
    required bool isCurrent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display', // Assuming default font
                ),
              ),
              TextSpan(
                text: ' Workouts',
                style: TextStyle(
                  color: Colors.grey[400],
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
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
