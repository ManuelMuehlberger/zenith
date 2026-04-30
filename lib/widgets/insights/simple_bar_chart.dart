import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/weekly_bar_data.dart';
import '../../services/insights_service.dart';
import '../../theme/app_theme.dart';

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
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final axisLabelStyle = textTheme.bodySmall?.copyWith(
      color: colors.textTertiary,
    );
    final emphasisLabelStyle = textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
    );
    final tooltipTextStyle =
        textTheme.bodySmall?.copyWith(color: colorScheme.onSurface) ??
        AppTextStyles.caption.copyWith(color: colorScheme.onSurface);

    if (weeklyData.isEmpty && !onlyAxis) {
      return Center(
        child: Text(
          'No data',
          style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
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
            getTooltipColor: (_) => colors.field,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toStringAsFixed(1),
                tooltipTextStyle,
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
                if (index < 0 || index >= weeklyData.length) {
                  return const SizedBox.shrink();
                }

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
                        style: axisLabelStyle,
                      ),
                    );
                  } else {
                    // Many days (1M), show every 7th day
                    if (index % 7 == 0) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          "${currentData.weekStart.day}",
                          style: axisLabelStyle,
                        ),
                      );
                    }
                  }
                } else if (effectiveGrouping == InsightsGrouping.week) {
                  // Only show month name for the first week of the month
                  if (currentData.weekStart.day <= 7) {
                    const monthNames = [
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
                    final label = monthNames[currentData.weekStart.month - 1];
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(label, style: emphasisLabelStyle),
                    );
                  }
                } else {
                  // Month grouping
                  // Show Jan, May, Sep (every 4 months)
                  if (currentData.weekStart.month % 4 == 1) {
                    const monthNames = [
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
                    final monthName =
                        monthNames[currentData.weekStart.month - 1];
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(monthName, style: axisLabelStyle),
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
                return Text(value.toInt().toString(), style: axisLabelStyle);
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: showGrid && !onlyAxis,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: maxYValue > 0 ? maxYValue / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: AppThemeColors.outline,
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
      final double effectiveMax =
          data.maxValue == data.minValue && data.maxValue > 0
          ? data.maxValue + (maxYValue * 0.02)
          : data.maxValue;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: effectiveMin,
            toY: effectiveMax,
            color: color,
            width: barWidth ?? (showTitles ? 12 : 6),
            borderRadius: BorderRadius.circular(showTitles ? 4 : 3),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxYValue,
              color: AppThemeColors.outline,
            ),
          ),
        ],
      );
    });
  }
}
