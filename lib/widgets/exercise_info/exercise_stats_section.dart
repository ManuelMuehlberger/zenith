import 'package:flutter/material.dart';
import '../../services/insights_service.dart';
import '../../widgets/workout_chart.dart';
import '../../utils/unit_converter.dart';

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

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey[400],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Time Period: ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onTimePeriodPressed,
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getTimePeriodText(selectedMonths),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        if (isLoading) ...[
          const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          ),
        ] else if (exerciseInsights == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Unable to load exercise statistics',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ] else if (exerciseInsights!.totalSessions == 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No workout data found for this exercise in the selected time period',
                    style: Theme.of(context).textTheme.bodyMedium,
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
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                context,
                'Total Sessions',
                exerciseInsights!.totalSessions.toString(),
                Icons.fitness_center,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                'Total Sets',
                exerciseInsights!.totalSets.toString(),
                Icons.repeat,
                Colors.green,
              ),
              _buildStatCard(
                context,
                'Total Reps',
                exerciseInsights!.totalReps.toString(),
                Icons.numbers,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                'Max Weight',
                _formatWeight(exerciseInsights!.maxWeight),
                Icons.trending_up,
                Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Charts
          Text(
            'Progress Charts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),

          const SizedBox(height: 16),

          WorkoutChart(
            title: 'Monthly Volume',
            data: exerciseInsights!.monthlyVolume,
            color: Colors.blue,
            unit: useKg ? 'kg' : 'lbs',
          ),

          const SizedBox(height: 16),

          WorkoutChart(
            title: 'Max Weight Progress',
            data: exerciseInsights!.monthlyMaxWeight,
            color: Colors.red,
            unit: useKg ? 'kg' : 'lbs',
          ),

          const SizedBox(height: 16),

          WorkoutChart(
            title: 'Monthly Frequency',
            data: exerciseInsights!.monthlyFrequency,
            color: Colors.green,
            unit: 'sessions',
          ),

          const SizedBox(height: 16),

          // Additional stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Averages',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Average Weight per Set:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[300],
                          ),
                    ),
                    Text(
                      _formatWeight(exerciseInsights!.averageWeight),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[300],
                          ),
                    ),
                    Text(
                      exerciseInsights!.averageReps.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[300],
                          ),
                    ),
                    Text(
                      exerciseInsights!.averageSets.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
