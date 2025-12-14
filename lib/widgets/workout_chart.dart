import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/insights_service.dart';
import '../constants/app_constants.dart';

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

  String _formatYAxisLabel(double value) {
    if (value > 999) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging for chart data
    debugPrint('WorkoutChart: Building chart "$title"');
    debugPrint('WorkoutChart: Data points count: ${data.length}');
    
    if (data.isEmpty) {
      debugPrint('WorkoutChart: No data available for "$title"');
      return Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.CARD_BG_COLOR,
          borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
          border: Border.all(
            color: AppConstants.DIVIDER_COLOR,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.chart_bar,
                size: 32,
                color: AppConstants.TEXT_TERTIARY_COLOR,
              ),
              const SizedBox(height: 8),
              Text(
                'No data available',
                style: AppConstants.IOS_SUBTEXT_STYLE,
              ),
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
    debugPrint('WorkoutChart: Raw values for "$title": $values');
    
    final rawMinY = values.reduce((a, b) => a < b ? a : b);
    final rawMaxY = values.reduce((a, b) => a > b ? a : b);
    debugPrint('WorkoutChart: Raw min=$rawMinY, max=$rawMaxY');
    
    // Apply scaling factors
    double minY = rawMinY * 0.8;
    double maxY = rawMaxY * 1.2;
    
    // Handle edge case: if all values are the same or very close
    final range = maxY - minY;
    debugPrint('WorkoutChart: Initial range (maxY - minY) = $range');
    
    if (range < 0.001) {
      // All values are essentially the same, create artificial range
      debugPrint('WorkoutChart: Range too small, creating artificial range around value $rawMaxY');
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
      debugPrint('WorkoutChart: Adjusted to minY=$minY, maxY=$maxY');
    }
    
    final finalRange = maxY - minY;
    debugPrint('WorkoutChart: Final range = $finalRange');

    Widget chart = LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
                  show: showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: finalRange / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppConstants.DIVIDER_COLOR,
                      strokeWidth: 0.5,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: showTitles,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
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
                                final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                             'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                label = monthNames[date.month - 1];
                              }
                            }
                          } else if (timeframe == '3M' || timeframe == '6M') {
                            // Show weeks (maybe date of Monday)
                            // Or just month names when month changes
                            if (date.day <= 7) { // First week of month
                               final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                             'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                               label = monthNames[date.month - 1];
                               isHighlight = true;
                            } else {
                              label = '${date.day}';
                            }
                          } else {
                            // Monthly view (default)
                            final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                               'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
                              style: TextStyle(
                                color: isHighlight ? AppConstants.TEXT_SECONDARY_COLOR : AppConstants.TEXT_TERTIARY_COLOR,
                                fontSize: 10,
                                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
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
                          strokeColor: AppConstants.CARD_BG_COLOR,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withAlpha((255 * 0.25).round()),
                          color.withAlpha((255 * 0.05).round()),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppConstants.WORKOUT_BUTTON_BG_COLOR,
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
                           final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
                                           'July', 'August', 'September', 'October', 'November', 'December'];
                           dateLabel = monthNames[date.month - 1];
                        }

                        return LineTooltipItem(
                          '$dateLabel\n',
                          TextStyle(
                            color: AppConstants.TEXT_SECONDARY_COLOR,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: '${barSpot.y.toStringAsFixed(1)} $unit',
                              style: TextStyle(
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
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: color.withAlpha((255 * 0.3).round()),
                          strokeWidth: 1,
                          dashArray: [3, 3],
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
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
      return SizedBox(
        height: height,
        child: chart,
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.CARD_BG_COLOR,
        borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
        border: Border.all(
          color: AppConstants.DIVIDER_COLOR,
          width: 0.5,
        ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha((255 * 0.15).round()),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    unit,
                    style: TextStyle(
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
          Expanded(
            child: chart,
          ),
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
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withAlpha((255 * 0.2).round()),
                    color.withAlpha((255 * 0.05).round()),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
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
    if (data.isEmpty) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.CARD_BG_COLOR,
          borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
          border: Border.all(
            color: AppConstants.DIVIDER_COLOR,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.chart_bar_fill,
                size: 32,
                color: AppConstants.TEXT_TERTIARY_COLOR,
              ),
              const SizedBox(height: 8),
              Text(
                'No data available',
                style: AppConstants.IOS_SUBTEXT_STYLE,
              ),
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
        color: AppConstants.CARD_BG_COLOR,
        borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
        border: Border.all(
          color: AppConstants.DIVIDER_COLOR,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
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
                          style: TextStyle(
                            color: AppConstants.TEXT_SECONDARY_COLOR,
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
                                colors: [
                                  color,
                                  color.withAlpha((255 * 0.7).round()),
                                ],
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
                          style: TextStyle(
                            color: AppConstants.TEXT_TERTIARY_COLOR,
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
