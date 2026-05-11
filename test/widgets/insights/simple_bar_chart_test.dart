import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/weekly_bar_data.dart';
import 'package:zenith/services/insights_service.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/insights/simple_bar_chart.dart';

void main() {
  Widget buildChart({
    required ThemeData theme,
    required Widget child,
    double width = 180,
    double height = 140,
  }) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );
  }

  WeeklyBarData barData({required DateTime weekStart, double value = 4}) {
    return WeeklyBarData(
      label: '',
      minValue: 0,
      maxValue: value,
      weekStart: weekStart,
    );
  }

  testWidgets('uses a subtle background track in light mode', (tester) async {
    final accent = AppTheme.light.colorScheme.primary;

    await tester.pumpWidget(
      buildChart(
        theme: AppTheme.light,
        child: SimpleBarChart(
          weeklyData: [
            barData(weekStart: DateTime(2024, 1, 1), value: 3),
            barData(weekStart: DateTime(2024, 1, 8), value: 5),
          ],
          maxYValue: 8,
          color: accent,
        ),
      ),
    );

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final backgroundColor =
        chart.data.barGroups.first.barRods.first.backDrawRodData.color;

    expect(backgroundColor, accent.withValues(alpha: 0.10));
  });

  testWidgets('shows month labels when weekly data crosses months', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildChart(
        theme: AppTheme.light,
        width: 260,
        child: SimpleBarChart(
          weeklyData: [
            barData(weekStart: DateTime(2024, 1, 25)),
            barData(weekStart: DateTime(2024, 2, 8)),
            barData(weekStart: DateTime(2024, 2, 15)),
            barData(weekStart: DateTime(2024, 3, 14)),
          ],
          maxYValue: 8,
          color: AppTheme.light.colorScheme.primary,
          showTitles: true,
          grouping: InsightsGrouping.week,
        ),
      ),
    );

    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Feb'), findsOneWidget);
    expect(find.text('Mar'), findsOneWidget);
  });

  testWidgets('narrows collapsed bars when many data points are shown', (
    tester,
  ) async {
    final data = List.generate(
      24,
      (index) => barData(
        weekStart: DateTime(2024, 1, 1).add(Duration(days: index)),
        value: (index % 5 + 1).toDouble(),
      ),
    );

    await tester.pumpWidget(
      buildChart(
        theme: AppTheme.dark,
        width: 120,
        height: 120,
        child: SimpleBarChart(
          weeklyData: data,
          maxYValue: 8,
          color: AppTheme.dark.colorScheme.primary,
        ),
      ),
    );

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final barWidth = chart.data.barGroups.first.barRods.first.width;

    expect(barWidth, lessThan(4.0));
  });
}
