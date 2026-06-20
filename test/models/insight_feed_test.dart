import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/insight_feed.dart';

void main() {
  group('InsightFeedCard', () {
    test('serializes and restores card payloads', () {
      final card = InsightFeedCard(
        id: 'card-1',
        type: InsightFeedCardType.trainingBalance,
        priority: 90,
        title: 'Training balance',
        body: 'Long-term work leans Push.',
        metric: '74%',
        accent: 'success',
        icon: 'chart',
        generatedAt: DateTime.utc(2026, 6, 11, 10),
        sourceWorkoutId: 'workout-1',
        visualType: InsightFeedVisualType.balanceFingerprint,
        size: InsightFeedCardSize.featured,
        visualData: const {
          'segments': [
            {'label': 'Chest', 'percent': 0.5},
            {'label': 'Back', 'percent': 0.25},
            {'label': 'Legs', 'percent': 0.25},
          ],
          'balanceScore': 74,
        },
        detailMetricLabel: 'Balance score',
        comparisonLabel: 'Last 180 days',
      );

      final restored = InsightFeedCard.fromMap(card.toMap());

      expect(restored.id, card.id);
      expect(restored.type, InsightFeedCardType.trainingBalance);
      expect(restored.metric, '74%');
      expect(restored.sourceWorkoutId, 'workout-1');
      expect(restored.visualType, InsightFeedVisualType.balanceFingerprint);
      expect(restored.size, InsightFeedCardSize.featured);
      expect(restored.visualData['segments'], isA<List>());
      expect(restored.detailMetricLabel, 'Balance score');
      expect(restored.comparisonLabel, 'Last 180 days');
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
