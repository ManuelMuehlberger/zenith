import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../services/insights_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/unit_converter.dart';
import '../../widgets/workout_chart.dart';

class ExerciseStatsSection extends StatelessWidget {
  final ExerciseInsights? exerciseInsights;
  final bool isLoading;
  final bool useKg;
  final int selectedMonths;
  final VoidCallback onTimePeriodPressed;

  const ExerciseStatsSection({
    super.key,
    required this.exerciseInsights,
    required this.isLoading,
    required this.useKg,
    required this.selectedMonths,
    required this.onTimePeriodPressed,
  });

  String _formatWeight(double weight) {
    final units = useKg ? 'metric' : 'imperial';
    final unitLabel = UnitConverter.getWeightUnit(units);
    return '${weight.toStringAsFixed(1)} $unitLabel';
  }

  String _getTimePeriodText(int months) {
    switch (months) {
      case 3:
        return '3 months';
      case 6:
        return '6 months';
      case 12:
        return '1 year';
      default:
        return '6 months';
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppConstants.CARD_PADDING),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: textTheme.labelMedium?.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Time Period: ',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onTimePeriodPressed,
              style: TextButton.styleFrom(
                backgroundColor: colors.field,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getTimePeriodText(selectedMonths),
                    style: textTheme.labelLarge,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: colorScheme.onSurface,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        if (isLoading) ...[
          const Center(child: CupertinoActivityIndicator()),
        ] else if (exerciseInsights == null) ...[
          Container(
            padding: const EdgeInsets.all(AppConstants.CARD_PADDING),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colors.warning),
                const SizedBox(width: 12),
                Text(
                  'Unable to load exercise statistics',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ] else if (exerciseInsights!.totalSessions == 0) ...[
          Container(
            padding: const EdgeInsets.all(AppConstants.CARD_PADDING),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No workout data found for this exercise in the selected time period',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Statistics cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppConstants.SECTION_VERTICAL_GAP,
            mainAxisSpacing: AppConstants.SECTION_VERTICAL_GAP,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                context,
                'Total Sessions',
                exerciseInsights!.totalSessions.toString(),
                Icons.fitness_center,
                colorScheme.primary,
              ),
              _buildStatCard(
                context,
                'Total Sets',
                exerciseInsights!.totalSets.toString(),
                Icons.repeat,
                colors.success,
              ),
              _buildStatCard(
                context,
                'Total Reps',
                exerciseInsights!.totalReps.toString(),
                Icons.numbers,
                colors.warning,
              ),
              _buildStatCard(
                context,
                'Max Weight',
                _formatWeight(exerciseInsights!.maxWeight),
                Icons.trending_up,
                colorScheme.error,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Charts
          Text(
            'Progress Charts',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          WorkoutChart(
            title: 'Monthly Volume',
            data: exerciseInsights!.monthlyVolume,
            color: colorScheme.primary,
            unit: useKg ? 'kg' : 'lbs',
          ),

          const SizedBox(height: 16),

          WorkoutChart(
            title: 'Max Weight Progress',
            data: exerciseInsights!.monthlyMaxWeight,
            color: colorScheme.error,
            unit: useKg ? 'kg' : 'lbs',
          ),

          const SizedBox(height: 16),

          WorkoutChart(
            title: 'Monthly Frequency',
            data: exerciseInsights!.monthlyFrequency,
            color: colors.success,
            unit: 'sessions',
          ),

          const SizedBox(height: 16),

          // Additional stats
          Container(
            padding: const EdgeInsets.all(AppConstants.CARD_PADDING),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Averages',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Average Weight per Set:',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatWeight(exerciseInsights!.averageWeight),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Average Reps per Set:',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      exerciseInsights!.averageReps.toStringAsFixed(1),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Average Sets per Session:',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      exerciseInsights!.averageSets.toStringAsFixed(1),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }
}
