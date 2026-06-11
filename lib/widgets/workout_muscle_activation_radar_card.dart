import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/workout_muscle_activation_service.dart';
import '../theme/app_theme.dart';

// policy: allow-public-api reusable workout muscle activation radar card.
class WorkoutMuscleActivationRadarCard extends StatefulWidget {
  const WorkoutMuscleActivationRadarCard({super.key, required this.profile});

  final WorkoutMuscleActivationProfile profile;

  @override
  State<WorkoutMuscleActivationRadarCard> createState() =>
      _WorkoutMuscleActivationRadarCardState();
}

class _WorkoutMuscleActivationRadarCardState
    extends State<WorkoutMuscleActivationRadarCard> {
  int? _selectedAxisIndex;

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.hasActivation || widget.profile.points.length < 3) {
      return const SizedBox.shrink();
    }

    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final points = widget.profile.points;
    final selectedPoint = _selectedAxisIndex == null
        ? null
        : points[_selectedAxisIndex!.clamp(0, points.length - 1)];

    return Container(
      key: const Key('workout_muscle_activation_card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.field,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.radar_outlined,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Muscle activation', style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      selectedPoint == null
                          ? 'Tap a point to inspect the split'
                          : _selectedSummary(selectedPoint),
                      style: textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: textTheme.labelSmall?.copyWith(
                  color: colors.transparent,
                  fontSize: 1,
                ),
                radarBackgroundColor: colors.field.withValues(alpha: 0.22),
                radarBorderData: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
                gridBorderData: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.8),
                  width: 0.8,
                ),
                tickBorderData: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
                  width: 0.8,
                ),
                titlePositionPercentageOffset: 0.18,
                titleTextStyle: textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: _shortLabel(points[index].label),
                    angle: _readableAngle(angle),
                  );
                },
                radarTouchData: RadarTouchData(
                  touchSpotThreshold: 18,
                  touchCallback: (event, response) {
                    final spot = response?.touchedSpot;
                    if (spot == null) {
                      return;
                    }
                    setState(() {
                      _selectedAxisIndex = spot.touchedRadarEntryIndex;
                    });
                  },
                ),
                dataSets: [
                  RadarDataSet(
                    dataEntries: points
                        .map((point) => RadarEntry(value: point.planned))
                        .toList(growable: false),
                    borderColor: colors.textTertiary,
                    fillColor: colors.textTertiary.withValues(alpha: 0.18),
                    borderWidth: 1.8,
                    entryRadius: 2.5,
                  ),
                  RadarDataSet(
                    dataEntries: points
                        .map((point) => RadarEntry(value: point.actual))
                        .toList(growable: false),
                    borderColor: scheme.primary,
                    fillColor: scheme.primary.withValues(alpha: 0.18),
                    borderWidth: 2.4,
                    entryRadius: 3.5,
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _LegendSwatch(color: colors.textTertiary),
              const SizedBox(width: 8),
              Text('Planned', style: textTheme.labelMedium),
              const SizedBox(width: 18),
              _LegendSwatch(color: scheme.primary),
              const SizedBox(width: 8),
              Text('Actual', style: textTheme.labelMedium),
            ],
          ),
        ],
      ),
    );
  }

  String _selectedSummary(WorkoutMuscleActivationPoint point) {
    final actual = (point.actual * 100).round();
    final planned = (point.planned * 100).round();
    return '${point.label}: $actual actual / $planned planned';
  }

  String _shortLabel(String label) {
    if (label == 'Shoulders') {
      return 'Delts';
    }
    return label;
  }

  double _readableAngle(double angle) {
    final normalized = angle % 360;
    if (normalized > 90 && normalized < 270) {
      return angle + 180;
    }
    return angle;
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
