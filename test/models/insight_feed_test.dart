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
      );

      final restored = InsightFeedCard.fromMap(card.toMap());

      expect(restored.id, card.id);
      expect(restored.type, InsightFeedCardType.trainingVelocity);
      expect(restored.metric, '+28%');
      expect(restored.sourceWorkoutId, 'workout-1');
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
      });

      expect(rule.type, InsightFeedCardType.consistencyPulse);
      expect(rule.enabled, isTrue);
      expect(rule.params['recentDays'], 7);
    });
  });
}
