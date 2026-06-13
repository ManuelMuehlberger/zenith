import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/insights.dart';
import 'package:zenith/services/insights/insight_data_provider.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/insights/simple_bar_chart.dart';
import 'package:zenith/widgets/insights/small_bar_card.dart';

void main() {
  testWidgets('WeeklyTrendCard uses chartValueBuilder for rendered bars', (
    tester,
  ) async {
    final provider = _FakeInsightDataProvider([
      InsightDataPoint(
        date: DateTime(2026, 6, 1),
        value: 12,
        maxValue: 24,
        count: 3,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WeeklyTrendCard(
            title: 'Workouts',
            icon: CupertinoIcons.flame_fill,
            color: Colors.orange,
            unit: 'workouts',
            provider: provider,
            filters: const {'timeframe': '6M'},
            chartValueBuilder: (point, grouping) => point.count!.toDouble(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<SimpleBarChart>(
      find.byType(SimpleBarChart).first,
    );
    expect(chart.weeklyData, isNotEmpty);
    expect(chart.weeklyData.first.maxValue, 3);
  });
}

class _FakeInsightDataProvider implements InsightDataProvider {
  const _FakeInsightDataProvider(this.data);

  final List<InsightDataPoint> data;

  @override
  Future<List<InsightDataPoint>> getData({
    required String timeframe,
    required int monthsBack,
    Map<String, dynamic> filters = const {},
  }) async {
    return data;
  }
}
