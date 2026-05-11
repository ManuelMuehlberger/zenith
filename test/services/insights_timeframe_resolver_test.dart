import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/insights.dart';
import 'package:zenith/services/insights/insights_timeframe_resolver.dart';

void main() {
  group('InsightsTimeframeResolver.resolveWindowStart', () {
    test('aligns weekly windows to the oldest generated week slot', () {
      final windowStart = InsightsTimeframeResolver.resolveWindowStart(
        referenceDate: DateTime(2026, 5, 11),
        monthsBack: 3,
        grouping: InsightsGrouping.week,
      );

      expect(windowStart, DateTime(2026, 2, 16));
    });

    test('uses a rolling 30-day window for 1M daily charts', () {
      final windowStart = InsightsTimeframeResolver.resolveWindowStart(
        referenceDate: DateTime(2026, 5, 11),
        monthsBack: 1,
        grouping: InsightsGrouping.day,
      );

      expect(windowStart, DateTime(2026, 4, 12));
    });
  });
}
