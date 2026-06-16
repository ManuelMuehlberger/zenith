import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/insight_feed.dart';

void main() {
  group('InsightFeedCard', () {
    test('serializes and restores card payloads', () {
      final card = InsightFeedCard(
        id: 'card-1',
        type: InsightFeedCardType.trainingVelocity,
        priority: 90,
        title: 'Training velocity',
        body: 'Recent pace is up.',
        metric: '+28%',
        accent: 'success',
        icon: 'bolt',
        generatedAt: DateTime.utc(2026, 6, 11, 10),
        sourceWorkoutId: 'workout-1',
        visualType: InsightFeedVisualType.trainingVelocityLine,
        size: InsightFeedCardSize.featured,
        visualData: const {
          'points': [
            {'label': '4/1', 'value': 2.1},
            {'label': '4/8', 'value': 3.0},
          ],
          'average': 3.0,
        },
        detailMetricLabel: 'Workout rate',
        comparisonLabel: 'Previous 90 days average: 2.1 workouts/week',
      );

      final restored = InsightFeedCard.fromMap(card.toMap());

      expect(restored.id, card.id);
      expect(restored.type, InsightFeedCardType.trainingVelocity);
      expect(restored.metric, '+28%');
      expect(restored.sourceWorkoutId, 'workout-1');
      expect(restored.visualType, InsightFeedVisualType.trainingVelocityLine);
      expect(restored.size, InsightFeedCardSize.featured);
      expect(restored.visualData['points'], isA<List>());
      expect(restored.detailMetricLabel, 'Workout rate');
      expect(
        restored.comparisonLabel,
        'Previous 90 days average: 2.1 workouts/week',
      );
    });
  });

  group('InsightFeedRule', () {
    test('parses enabled rules and params', () {
      final rule = InsightFeedRule.fromMap(const {
        'id': 'consistency',
        'type': 'consistencyPulse',
        'enabled': true,
        'priority': 50,
        'params': {'recentDays': 7},
        'visual': {
          'enabled': true,
          'type': 'calendarStrip',
          'size': 'wide',
          'params': {'baselineDays': 14},
        },
      });

      expect(rule.type, InsightFeedCardType.consistencyPulse);
      expect(rule.enabled, isTrue);
      expect(rule.params['recentDays'], 7);
      expect(rule.visual.enabled, isTrue);
      expect(rule.visual.type, InsightFeedVisualType.calendarStrip);
      expect(rule.visual.size, InsightFeedCardSize.wide);
      expect(rule.visual.params['baselineDays'], 14);
    });
  });
}
