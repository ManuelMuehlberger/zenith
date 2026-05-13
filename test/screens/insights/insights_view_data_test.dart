import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/insights/insights_view_data.dart';

void main() {
  group('Insights view data', () {
    test('filter snapshot reports filters and provider map consistently', () {
      const snapshot = InsightsFilterSnapshot(
        timeframe: '1M',
        workoutName: 'Push Day',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        isBodyWeight: false,
      );

      expect(snapshot.hasAnyFilter, isTrue);
      expect(snapshot.toProviderFilters(), {
        'workoutName': 'Push Day',
        'muscleGroup': 'Chest',
        'equipment': 'Barbell',
        'isBodyWeight': false,
        'timeframe': '1M',
      });
    });

    test('timeframe options stay ordered from shortest to longest', () {
      expect(insightsTimeframeOptions.first.label, '1W');
      expect(insightsTimeframeOptions.last.label, 'All');
      expect(insightsTimeframeOptions.map((option) => option.months), [
        0,
        1,
        3,
        6,
        12,
        24,
        999,
      ]);
    });
  });
}
