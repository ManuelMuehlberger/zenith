import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/insight_detail_screen.dart';
import 'package:zenith/services/insights_service.dart';
import 'package:zenith/theme/app_theme.dart';

void main() {
  group('InsightDetailScreen layout helpers', () {
    test('expands compact insight summaries into readable detail text', () {
      expect(
        formatInsightDetailSummaryText(
          title: 'Workouts',
          summary: 'Avg / Week',
        ),
        'average workouts per week',
      );
      expect(
        formatInsightDetailSummaryText(
          title: 'Duration',
          summary: 'Avg / Workout',
        ),
        'average per workout',
      );
      expect(
        formatInsightDetailSummaryText(title: 'Volume', summary: 'This Week'),
        'this Week',
      );
    });

    test('uses the selected timeframe window for detail fetches', () {
      expect(resolveInsightDetailMonthsToFetch('1W'), 1);
      expect(resolveInsightDetailMonthsToFetch('1M'), 1);
      expect(resolveInsightDetailMonthsToFetch('3M'), 3);
      expect(resolveInsightDetailMonthsToFetch('6M'), 6);
      expect(resolveInsightDetailMonthsToFetch('1Y'), 12);
      expect(resolveInsightDetailMonthsToFetch('2Y'), 24);
      expect(resolveInsightDetailMonthsToFetch('All'), 999);
    });

    test('accounts for axis footprint when sizing the chart viewport', () {
      expect(
        calculateInsightDetailChartViewportWidth(
          availableWidth: 360,
          hasAxis: true,
        ),
        312,
      );
      expect(
        calculateInsightDetailChartViewportWidth(
          availableWidth: 360,
          hasAxis: false,
        ),
        360,
      );
    });

    test('preserves viewport width for short datasets', () {
      expect(
        calculateInsightDetailChartContentWidth(
          availableWidth: 360,
          hasAxis: true,
          dataCount: 4,
          itemWidth: 40,
        ),
        312,
      );
    });

    test('adds edge padding for dense datasets', () {
      expect(
        calculateInsightDetailChartContentWidth(
          availableWidth: 360,
          hasAxis: true,
          dataCount: 30,
          itemWidth: 12,
        ),
        384,
      );
      expect(insightDetailChartSectionHeight, 366);
    });
  });

  group('InsightDetailScreen filters', () {
    setUp(() {
      InsightsService.instance.reset();
      InsightsService.instance.setWorkoutsProvider(() async => []);
    });

    tearDown(() {
      InsightsService.instance.reset();
    });

    testWidgets('can hide workout filters while keeping timeframe control', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: InsightDetailScreen(
            title: 'Body Weight',
            icon: Icons.monitor_weight_outlined,
            color: Colors.lightBlue,
            unit: 'kg',
            showFilters: false,
            dataFetcher: (timeframe, months, filters) async => [],
            chartBuilder: (context, data, timeframe, months) =>
                const SizedBox.shrink(),
            mainValueBuilder: (data, timeframe) => '0',
            subLabelBuilder: (data, timeframe) => '',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workout'), findsNothing);
      expect(find.text('Muscle'), findsNothing);
      expect(find.text('Equipment'), findsNothing);
      expect(find.text('Bodyweight'), findsNothing);
      expect(find.text('6M'), findsOneWidget);
    });
  });
}
