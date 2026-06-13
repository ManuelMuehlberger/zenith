import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/insight_feed.dart';
import 'package:zenith/models/workout_achievement.dart';
import 'package:zenith/services/insights/cache/insights_cache_store.dart';
import 'package:zenith/services/insights/insight_feed_service.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/app_bottom_sheet.dart';
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

    expect(find.text('Today'), findsNothing);
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

  testWidgets('renders visual feed cards', (tester) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-1',
          type: InsightFeedCardType.consistencyPulse,
          priority: 50,
          title: 'Consistency pulse',
          body: 'You trained 3 times in the last 14 days.',
          metric: '3/14',
          accent: 'info',
          icon: 'calendar',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.calendarStrip,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'recentDays': [true, false, true, false, false, true, false],
            'baselineDays': [false, true, false, false, false, false, true],
          },
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
    expect(
      find.byKey(const Key('insight_feed_visual_calendarStrip')),
      findsOneWidget,
    );
  });

  testWidgets('renders clickable award previews for achievement cards', (
    tester,
  ) async {
    final achievement = WorkoutAchievement(
      workoutId: 'workout-1',
      ruleId: 'long_session',
      type: WorkoutAchievementType.longSession,
      title: 'Long Session',
      reason: 'You trained longer than usual.',
      earnedAt: DateTime(2026, 6, 11),
      metrics: const {'durationMinutes': 90},
    );
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-1',
          type: InsightFeedCardType.recentAchievementShoutout,
          priority: 100,
          title: 'Long Session',
          body: 'You trained longer than usual.',
          metric: '',
          accent: 'primary',
          icon: 'award',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.awardPreview,
          size: InsightFeedCardSize.wide,
          visualData: {
            'achievements': [achievement.toMap()],
          },
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

    expect(find.text('Earned'), findsNothing);
    expect(
      find.byKey(const Key('insight_feed_visual_awardPreview')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Long Session'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsOneWidget);
    expect(find.byKey(const Key('award_reason_text')), findsOneWidget);
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
