import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/insight_feed.dart';
import 'package:zenith/services/insights/cache/insights_cache_store.dart';
import 'package:zenith/services/insights/insight_feed_service.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/insights/insight_feed_section.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders fallback copy when the feed is empty', (tester) async {
    final service = InsightFeedService(
      workoutsProvider: () async => const [],
      nowProvider: () => DateTime(2026, 6, 11),
      cacheStore: const InsightsCacheStore(cacheKey: 'insight-feed-empty'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: InsightsFeedSection(service: service)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(
      find.text('Keep logging workouts to unlock fresh trends and shoutouts.'),
      findsOneWidget,
    );
  });

  testWidgets('renders supplied feed cards', (tester) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-1',
          type: InsightFeedCardType.consistencyPulse,
          priority: 50,
          title: 'Consistency pulse',
          body: 'You trained 3 times in the last 7 days.',
          metric: '3/7',
          accent: 'info',
          icon: 'calendar',
          generatedAt: DateTime(2026, 6, 11),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: InsightsFeedSection(service: service)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Consistency pulse'), findsOneWidget);
    expect(find.text('3/7'), findsOneWidget);
  });
}

class _FakeInsightFeedService extends InsightFeedService {
  _FakeInsightFeedService({required this.cards})
    : super(
        cacheStore: const InsightsCacheStore(cacheKey: 'insight-feed-fake'),
      );

  final List<InsightFeedCard> cards;

  @override
  Future<List<InsightFeedCard>> getCards({
    bool forceRefresh = false,
    int maxCards = 5,
  }) async {
    return cards;
  }
}
