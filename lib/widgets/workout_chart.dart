import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/insights_service.dart';
import '../theme/app_theme.dart';

class WorkoutChart extends StatelessWidget {
  final String title;
  final List<InsightDataPoint> data;
  final Color color;
  final String unit;
  final bool showGrid;
  final bool showTitles;
  final double height;
  final double barWidth;
  final double dotRadius;
  final bool showContainer;
  final bool showHeader;
  final String? timeframe;

  const WorkoutChart({
    super.key,
    required this.title,
    required this.data,
    required this.color,
    required this.unit,
    this.showGrid = false,
    this.showTitles = true,
    this.height = 200,
    this.barWidth = 2.5,
    this.dotRadius = 3.5,
    this.showContainer = true,
    this.showHeader = true,
    this.timeframe,
  });

  @override
  Widget build(BuildContext context) {
    const double cardRadius = 16.0;
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    if (data.isEmpty) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.chart_bar,
                size: 32,
                color: colors.textTertiary,
              ),
              const SizedBox(height: 8),
              Text('No data available', style: textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    // Calculate min and max for better chart scaling
    final values = data.map((d) => d.value).toList();

    final rawMinY = values.reduce((a, b) => a < b ? a : b);
    final rawMaxY = values.reduce((a, b) => a > b ? a : b);

    // Apply scaling factors
    double minY = rawMinY * 0.8;
    double maxY = rawMaxY * 1.2;

    // Handle edge case: if all values are the same or very close
    final range = maxY - minY;

    if (range < 0.001) {
      // All values are essentially the same, create artificial range
      if (rawMaxY.abs() < 0.001) {
        // Values are near zero
        minY = -1.0;
        maxY = 1.0;
      } else {
        // Create 20% padding around the value
        final padding = rawMaxY * 0.2;
        minY = rawMaxY - padding;
        maxY = rawMaxY + padding;
      }
    }

    final finalRange = maxY - minY;

    final Widget chart = LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: false,
          horizontalInterval: finalRange / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor,
              strokeWidth: 0.5,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: showTitles,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showTitles,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final date = data[value.toInt()].date;

                  String label = '';
                  bool isHighlight = false;

                  if (timeframe == '1W' || timeframe == '1M') {
                    // Show days
                    label = '${date.day}';
                    // Highlight Mondays or 1st of month
                    if (date.weekday == 1 || date.day == 1) {
                      isHighlight = true;
                      // Maybe show month name for 1st?
                      if (date.day == 1) {
                        final monthNames = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ];
                        label = monthNames[date.month - 1];
                      }
                    }
                  } else if (timeframe == '3M' || timeframe == '6M') {
                    // Show weeks (maybe date of Monday)
                    // Or just month names when month changes
                    if (date.day <= 7) {
                      // First week of month
                      final monthNames = [
                        'Jan',
                        'Feb',
                        'Mar',
                        'Apr',
                        'May',
                        'Jun',
                        'Jul',
                        'Aug',
                        'Sep',
                        'Oct',
                        'Nov',
                        'Dec',
                      ];
                      label = monthNames[date.month - 1];
                      isHighlight = true;
                    } else {
                      label = '${date.day}';
                    }
                  } else {
                    // Monthly view (default)
                    final monthNames = [
                      'Jan',
                      'Feb',
                      'Mar',
                      'Apr',
                      'May',
                      'Jun',
                      'Jul',
                      'Aug',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dec',
                    ];
                    label = monthNames[date.month - 1];
                    if (date.month == 1) {
                      label = "'${date.year.toString().substring(2)}";
                      isHighlight = true;
                    }
                  }

                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      label,
                      style: textTheme.bodySmall?.copyWith(
                        color: isHighlight
                            ? colors.textSecondary
                            : colors.textTertiary,
                        fontSize: 10,
                        fontWeight: isHighlight
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false, // Hide Y-axis labels for cleaner look
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: barWidth,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: dotRadius,
                  color: color,
                  strokeWidth: 1.5,
                  strokeColor: colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => colorScheme.surface,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final dataPoint = data[barSpot.x.toInt()];
                final date = dataPoint.date;

                String dateLabel;
                if (timeframe == '1W' || timeframe == '1M') {
                  dateLabel = '${date.day}/${date.month}';
                } else if (timeframe == '3M' || timeframe == '6M') {
                  dateLabel = 'Week of ${date.day}/${date.month}';
                } else {
                  final monthNames = [
                    'January',
                    'February',
                    'March',
                    'April',
                    'May',
                    'June',
                    'July',
                    'August',
                    'September',
                    'October',
                    'November',
                    'December',
                  ];
                  dateLabel = monthNames[date.month - 1];
                }

                return LineTooltipItem(
                  '$dateLabel\n',
                  textTheme.bodySmall!.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '${barSpot.y.toStringAsFixed(1)} $unit',
                      style: textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: color.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [3, 3],
                    ),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: colors.textPrimary,
                        );
                      },
                    ),
                  );
                }).toList();
              },
        ),
      ),
    );

    if (!showContainer) {
      return SizedBox(height: height, child: chart);
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    unit,
                    style: textTheme.bodySmall?.copyWith(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Expanded(child: chart),
        ],
      ),
    );
  }
}

// Compact chart for summary cards
class CompactChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;

  const CompactChart({
    super.key,
    required this.values,
    required this.color,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(height: height);
    }

    final spots = values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}

// Bar chart for categorical data
class WorkoutBarChart extends StatelessWidget {
  final String title;
  final Map<String, double> data;
  final Color color;
  final double height;

  const WorkoutBarChart({
    super.key,
    required this.title,
    required this.data,
    required this.color,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    const double cardRadius = 16.0;
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    if (data.isEmpty) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.chart_bar_fill,
                size: 32,
                color: colors.textTertiary,
              ),
              const SizedBox(height: 8),
              Text('No data available', style: textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.entries.map((entry) {
                final percentage = entry.value / maxValue;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          entry.value.toStringAsFixed(0),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [color, color.withValues(alpha: 0.7)],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            height: double.infinity,
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: percentage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
