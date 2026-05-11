import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/insight_detail_screen.dart';

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
}
