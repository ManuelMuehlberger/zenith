import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_constants.dart';
import '../../models/weekly_bar_data.dart';
import '../../services/insights_service.dart';

class SimpleBarChart extends StatelessWidget {
  final List<WeeklyBarData> weeklyData;
  final double maxYValue;
  final Color color;
  final bool showTitles;
  final bool showGrid;
  final bool showBorder;
  final bool touchEnabled;
  final double? barWidth;
  final bool onlyAxis;
  final InsightsGrouping? grouping;

  const SimpleBarChart({
    super.key,
    required this.weeklyData,
    required this.maxYValue,
    required this.color,
    this.showTitles = false,
    this.showGrid = false,
    this.showBorder = false,
    this.touchEnabled = false,
    this.barWidth,
    this.onlyAxis = false,
    this.grouping,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty && !onlyAxis) {
      return const Center(
        child: Text(
          'No data',
          style: TextStyle(
            color: AppConstants.TEXT_TERTIARY_COLOR,
            fontSize: 13,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxYValue,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: touchEnabled && !onlyAxis,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2C2C2E),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toStringAsFixed(1),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !onlyAxis,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= weeklyData.length) return const SizedBox.shrink();
                
                final currentData = weeklyData[index];
                final effectiveGrouping = grouping ?? InsightsGrouping.week;
                
                if (effectiveGrouping == InsightsGrouping.day) {
                  // If few days (1W), show every day
                  if (weeklyData.length <= 8) {
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        days[currentData.weekStart.weekday - 1],
                        style: const TextStyle(
                          color: AppConstants.TEXT_TERTIARY_COLOR,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    // Many days (1M), show weeks (Mondays)
                    if (currentData.weekStart.weekday == 1) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          "${currentData.weekStart.day}",
                          style: const TextStyle(
                            color: AppConstants.TEXT_TERTIARY_COLOR,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                  }
                } else if (effectiveGrouping == InsightsGrouping.week) {
                  // Show day of month for each week
                  String label = '${currentData.weekStart.day}';
                  bool isHighlight = false;

                  // Highlight first week of month with month name
                  if (currentData.weekStart.day <= 7) {
                    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    label = monthNames[currentData.weekStart.month - 1];
                    isHighlight = true;
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
                } else {
                  // Month grouping
                  // Show Jan, Apr, Jul, Oct
                  if (currentData.weekStart.month % 3 == 1) {
                    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    final monthName = monthNames[currentData.weekStart.month - 1];
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        monthName,
                        style: const TextStyle(
                          color: AppConstants.TEXT_TERTIARY_COLOR,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: onlyAxis,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppConstants.TEXT_TERTIARY_COLOR,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: showGrid && !onlyAxis,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: maxYValue > 0 ? maxYValue / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppConstants.DIVIDER_COLOR,
              strokeWidth: 0.5,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: onlyAxis ? [] : _buildBarGroups(),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(weeklyData.length, (index) {
      final data = weeklyData[index];
      final double effectiveMin = data.minValue;
      final double effectiveMax = data.maxValue == data.minValue && data.maxValue > 0 
          ? data.maxValue + (maxYValue * 0.02) 
          : data.maxValue;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: effectiveMin,
            toY: effectiveMax,
            color: color.withOpacity(0.8),
            width: barWidth ?? (showTitles ? 12 : 6),
            borderRadius: BorderRadius.circular(showTitles ? 4 : 3),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxYValue,
              color: color.withOpacity(0.15),
            ),
          ),
        ],
      );
    });
  }
}
