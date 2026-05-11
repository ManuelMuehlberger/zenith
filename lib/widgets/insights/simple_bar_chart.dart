import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/weekly_bar_data.dart';
import '../../services/insights_service.dart';
import '../../theme/app_theme.dart';

class SimpleBarChartBounds {
  final double minY;
  final double maxY;

  const SimpleBarChartBounds({required this.minY, required this.maxY});

  double get range => maxY - minY;
}

@visibleForTesting
SimpleBarChartBounds resolveSimpleBarChartBounds({
  required List<WeeklyBarData> weeklyData,
  required InsightsGrouping? grouping,
  required double suggestedMaxY,
}) {
  if (weeklyData.isEmpty) {
    return const SimpleBarChartBounds(minY: 0, maxY: 10);
  }

  final effectiveGrouping = grouping ?? InsightsGrouping.week;
  final allBarsNonZero = weeklyData.every((data) => data.maxValue > 0);

  if (effectiveGrouping != InsightsGrouping.day && allBarsNonZero) {
    final minValue = weeklyData
        .map((data) => data.minValue > 0 ? data.minValue : data.maxValue)
        .reduce(math.min);
    final maxValue = weeklyData.map((data) => data.maxValue).reduce(math.max);
    final spread = (maxValue - minValue).abs();
    final padding = math.max(
      1.0,
      spread < 0.5 ? maxValue * 0.15 : spread * 0.25,
    );
    final minY = math.max(0.0, minValue - padding);
    final maxY = math.max(minY + 2.0, maxValue + padding);

    return SimpleBarChartBounds(minY: minY, maxY: maxY);
  }

  return SimpleBarChartBounds(minY: 0, maxY: math.max(suggestedMaxY, 4));
}

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
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final axisLabelStyle = textTheme.bodySmall?.copyWith(
      color: colors.textTertiary,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
    final emphasisLabelStyle = textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    final tooltipTextStyle =
        textTheme.bodySmall?.copyWith(color: colorScheme.onSurface) ??
        Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface) ??
        DefaultTextStyle.of(
          context,
        ).style.copyWith(color: colorScheme.onSurface);

    if (weeklyData.isEmpty && !onlyAxis) {
      return Center(
        child: Text(
          'No data',
          style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
        ),
      );
    }

    final backgroundBarColor = color.withValues(
      alpha: isLightMode
          ? (showTitles ? 0.12 : 0.10)
          : (showTitles ? 0.24 : 0.18),
    );
    final gridLineColor = colorScheme.outline.withValues(
      alpha: isLightMode ? 0.12 : 0.28,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedBarWidth = _resolveBarWidth(constraints.maxWidth);
        final bounds = resolveSimpleBarChartBounds(
          weeklyData: weeklyData,
          grouping: grouping,
          suggestedMaxY: maxYValue,
        );

        return BarChart(
          BarChartData(
            alignment: _resolveAlignment(),
            maxY: bounds.maxY,
            minY: bounds.minY,
            barTouchData: BarTouchData(
              enabled: touchEnabled && !onlyAxis,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => colors.surfaceAlt,
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
                  reservedSize: showTitles ? 28 : 0,
                  getTitlesWidget: (value, meta) => _buildBottomTitle(
                    value: value,
                    meta: meta,
                    axisLabelStyle: axisLabelStyle,
                    emphasisLabelStyle: emphasisLabelStyle,
                  ),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: onlyAxis,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) {
                      return const SizedBox.shrink();
                    }

                    return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        value.toInt().toString(),
                        textAlign: TextAlign.right,
                        style: axisLabelStyle,
                      ),
                    );
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
              horizontalInterval: bounds.range > 0 ? bounds.range / 4 : 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: gridLineColor,
                  strokeWidth: 0.5,
                  dashArray: const [5, 5],
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: onlyAxis
                ? []
                : _buildBarGroups(backgroundBarColor, resolvedBarWidth, bounds),
          ),
        );
      },
    );
  }

  Widget _buildBottomTitle({
    required double value,
    required TitleMeta meta,
    required TextStyle? axisLabelStyle,
    required TextStyle? emphasisLabelStyle,
  }) {
    final index = value.toInt();
    if (index < 0 || index >= weeklyData.length) {
      return const SizedBox.shrink();
    }

    final label = _getBottomLabel(index);
    if (label == null) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: SizedBox(
        width: _labelWidthForGrouping(),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: _isEmphasizedBottomLabel(index)
              ? emphasisLabelStyle
              : axisLabelStyle,
        ),
      ),
    );
  }

  String? _getBottomLabel(int index) {
    final currentData = weeklyData[index];
    final effectiveGrouping = grouping ?? InsightsGrouping.week;

    if (effectiveGrouping == InsightsGrouping.day) {
      if (weeklyData.length <= 8) {
        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return days[currentData.weekStart.weekday - 1];
      }

      final isWeeklyTick = index % 7 == 0;
      final isLast = index == weeklyData.length - 1;
      if (isWeeklyTick || isLast) {
        return '${currentData.weekStart.day}';
      }

      return null;
    }

    if (effectiveGrouping == InsightsGrouping.week) {
      final previousDate = index > 0 ? weeklyData[index - 1].weekStart : null;
      if (index == 0 || previousDate?.month != currentData.weekStart.month) {
        return _monthName(currentData.weekStart.month);
      }

      return null;
    }

    final interval = _monthLabelInterval();
    final isFirst = index == 0;
    final isLast = index == weeklyData.length - 1;
    if (isFirst || isLast || index % interval == 0) {
      return _monthName(currentData.weekStart.month);
    }

    return null;
  }

  bool _isEmphasizedBottomLabel(int index) {
    return (grouping ?? InsightsGrouping.week) == InsightsGrouping.week;
  }

  double _labelWidthForGrouping() {
    switch (grouping ?? InsightsGrouping.week) {
      case InsightsGrouping.day:
        return weeklyData.length <= 8 ? 16 : 24;
      case InsightsGrouping.week:
        return 30;
      case InsightsGrouping.month:
        return 32;
    }
  }

  int _monthLabelInterval() {
    if (weeklyData.length <= 6) return 1;
    if (weeklyData.length <= 12) return 2;
    if (weeklyData.length <= 24) return 3;
    return 4;
  }

  String _monthName(int month) {
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

    return monthNames[month - 1];
  }

  BarChartAlignment _resolveAlignment() {
    if (weeklyData.length >= 10) {
      return BarChartAlignment.spaceBetween;
    }

    return showTitles
        ? BarChartAlignment.spaceAround
        : BarChartAlignment.spaceEvenly;
  }

  double _resolveBarWidth(double availableWidth) {
    if (barWidth != null) {
      return barWidth!;
    }

    if (!availableWidth.isFinite || weeklyData.isEmpty) {
      return showTitles ? 12 : 6;
    }

    final slotWidth = availableWidth / weeklyData.length;
    final widthFactor = showTitles ? 0.42 : 0.58;
    final minWidth = showTitles ? 3.0 : 2.0;
    final maxWidth = showTitles ? 12.0 : 8.0;

    return math.max(minWidth, math.min(maxWidth, slotWidth * widthFactor));
  }

  List<BarChartGroupData> _buildBarGroups(
    Color backgroundBarColor,
    double resolvedBarWidth,
    SimpleBarChartBounds bounds,
  ) {
    return List.generate(weeklyData.length, (index) {
      final data = weeklyData[index];
      double effectiveMin = data.minValue;
      double effectiveMax = data.maxValue;

      if (data.maxValue == data.minValue && data.maxValue > 0) {
        final halfHeight = math.max(bounds.range * 0.06, 0.35);
        effectiveMin = math.max(bounds.minY, data.minValue - halfHeight);
        effectiveMax = math.min(bounds.maxY, data.maxValue + halfHeight);
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: effectiveMin,
            toY: effectiveMax,
            color: color,
            width: resolvedBarWidth,
            borderRadius: BorderRadius.circular(showTitles ? 4 : 3),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: bounds.maxY,
              color: backgroundBarColor,
            ),
          ),
        ],
      );
    });
  }
}
