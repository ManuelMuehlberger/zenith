import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/services/insights/weight_trend_provider.dart';

void main() {
  group('WeightTrendProvider', () {
    test('uses daily slots for 1M and keeps latest value per day', () async {
      final provider = WeightTrendProvider(
        weightHistoryProvider: () => [
          WeightEntry(timestamp: DateTime(2026, 5, 1, 8), value: 75.0),
          WeightEntry(timestamp: DateTime(2026, 5, 1, 18), value: 74.5),
          WeightEntry(timestamp: DateTime(2026, 5, 11, 9), value: 74.0),
        ],
      );

      final data = await provider.getData(timeframe: '1M', monthsBack: 1);

      expect(data, hasLength(11));
      expect(data.first.date, DateTime(2026, 5, 1));
      expect(data.last.date, DateTime(2026, 5, 11));
      expect(data.first.value, 74.5);
      expect(data.first.minValue, 74.5);
      expect(data.first.maxValue, 75.0);
      expect(data.first.count, 2);
      expect(data.last.value, 74.0);
    });

    test('uses weekly slots for 6M', () async {
      final provider = WeightTrendProvider(
        weightHistoryProvider: () => [
          WeightEntry(timestamp: DateTime(2026, 1, 6, 9), value: 80.0),
          WeightEntry(timestamp: DateTime(2026, 5, 13, 9), value: 77.5),
        ],
      );

      final data = await provider.getData(timeframe: '6M', monthsBack: 6);

      expect(data, isNotEmpty);
      expect(data.last.value, 77.5);
      expect(data.last.count, 1);
      expect(data.any((point) => point.value == 0.0), isFalse);
      expect(data.any((point) => point.value == 80.0), isTrue);
    });

    test(
      'skips empty weeks instead of emitting zero-valued placeholders',
      () async {
        final provider = WeightTrendProvider(
          weightHistoryProvider: () => [
            WeightEntry(timestamp: DateTime(2026, 4, 7, 9), value: 78.4),
            WeightEntry(timestamp: DateTime(2026, 4, 28, 9), value: 77.9),
          ],
        );

        final data = await provider.getData(timeframe: '6M', monthsBack: 6);

        expect(data, hasLength(2));
        expect(data.map((point) => point.date), [
          DateTime(2026, 4, 6),
          DateTime(2026, 4, 27),
        ]);
        expect(data.map((point) => point.value), [78.4, 77.9]);
        expect(data.every((point) => (point.count ?? 0) > 0), isTrue);
      },
    );

    test('uses daily slots for 1W', () async {
      final provider = WeightTrendProvider(
        weightHistoryProvider: () => [
          WeightEntry(timestamp: DateTime(2026, 5, 7, 9), value: 76.5),
          WeightEntry(timestamp: DateTime(2026, 5, 11, 9), value: 76.0),
          WeightEntry(timestamp: DateTime(2026, 5, 13, 9), value: 75.5),
        ],
      );

      final data = await provider.getData(timeframe: '1W', monthsBack: 1);

      expect(data, hasLength(7));
      expect(data.first.date, DateTime(2026, 5, 7));
      expect(data.last.date, DateTime(2026, 5, 13));
      expect(data.last.value, 75.5);
    });
  });
}
