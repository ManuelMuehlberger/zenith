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

    test('aligns 1M daily windows to the start of the reference month', () {
      final windowStart = InsightsTimeframeResolver.resolveWindowStart(
        referenceDate: DateTime(2026, 5, 11),
        monthsBack: 1,
        grouping: InsightsGrouping.day,
      );

      expect(windowStart, DateTime(2026, 5, 1));
    });
  });

  group('InsightsTimeframeResolver.resolveSlotCount', () {
    test('uses month-to-date slots for 1M daily charts', () {
      final slots = InsightsTimeframeResolver.resolveSlotCount(
        referenceDate: DateTime(2026, 5, 11),
        monthsBack: 1,
        grouping: InsightsGrouping.day,
      );

      expect(slots, 11);
    });
  });
}
