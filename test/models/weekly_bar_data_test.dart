import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/weekly_bar_data.dart';

void main() {
  group('WeeklyBarData', () {
    test('constructor stores the provided values', () {
      final weekStart = DateTime(2024, 1, 1);

      final data = WeeklyBarData(
        label: 'This Week',
        minValue: 120.5,
        maxValue: 185.0,
        weekStart: weekStart,
      );

      expect(data.label, 'This Week');
      expect(data.minValue, 120.5);
      expect(data.maxValue, 185.0);
      expect(data.weekStart, weekStart);
    });
  });
}
