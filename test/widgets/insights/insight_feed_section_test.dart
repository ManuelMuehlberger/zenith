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
    expect(find.text('Last Workout'), findsOneWidget);
  });

  testWidgets('renders feed stack headings in order', (tester) async {
    final service = _FakeInsightFeedService(
      stacks: [
        InsightFeedStack(
          id: 'last_workout',
          title: 'Last Workout',
          priority: 100,
          cards: [
            _feedCard(
              id: 'latest',
              title: 'Latest workout',
              type: InsightFeedCardType.latestWorkoutComparison,
            ),
            _feedCard(
              id: 'focus',
              title: 'Muscle focus',
              type: InsightFeedCardType.muscleActivationRadar,
            ),
          ],
        ),
        InsightFeedStack(
          id: 'recent_trends',
          title: 'Recent Trends',
          priority: 80,
          cards: [
            _feedCard(
              id: 'consistency',
              title: 'Consistency pulse',
              type: InsightFeedCardType.consistencyPulse,
            ),
          ],
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

    expect(find.text('Last Workout'), findsOneWidget);
    expect(find.text('Recent Trends'), findsOneWidget);
    expect(find.text('Latest workout'), findsOneWidget);
    expect(find.byKey(const Key('insight_feed_stack_rail')), findsNWidgets(2));
    expect(find.byKey(const Key('insight_feed_page_dots')), findsOneWidget);
  });

  testWidgets('keeps each horizontal page card at its own height', (
    tester,
  ) async {
    final service = _FakeInsightFeedService(
      stacks: [
        InsightFeedStack(
          id: 'last_workout',
          title: 'Last Workout',
          priority: 100,
          cards: [
            _feedCard(
              id: 'short',
              title: 'Short card',
              type: InsightFeedCardType.comebackCard,
            ),
            InsightFeedCard(
              id: 'tall',
              type: InsightFeedCardType.muscleActivationRadar,
              priority: 90,
              title: 'Tall card',
              body: 'Latest workout compared with your recent average.',
              metric: '2',
              accent: 'primary',
              icon: 'radar',
              generatedAt: DateTime(2026, 6, 11),
              visualType: InsightFeedVisualType.radar,
              size: InsightFeedCardSize.featured,
              visualData: const {
                'points': [
                  {
                    'axisId': 'chest',
                    'label': 'Chest',
                    'planned': 0.5,
                    'actual': 1,
                  },
                  {
                    'axisId': 'back',
                    'label': 'Back',
                    'planned': 0.2,
                    'actual': 0.1,
                  },
                  {
                    'axisId': 'legs',
                    'label': 'Legs',
                    'planned': 0.4,
                    'actual': 0.3,
                  },
                ],
              },
            ),
          ],
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

    final shortCardHeight = tester
        .getSize(find.byKey(const Key('insight_feed_page_card_short')))
        .height;
    final railHeight = tester
        .getSize(find.byKey(const Key('insight_feed_stack_rail')))
        .height;

    expect(railHeight, shortCardHeight + 16);
  });

  testWidgets('interpolates rail height during horizontal drag', (
    tester,
  ) async {
    final service = _FakeInsightFeedService(
      stacks: [
        InsightFeedStack(
          id: 'last_workout',
          title: 'Last Workout',
          priority: 100,
          cards: [
            _feedCard(
              id: 'short',
              title: 'Short card',
              type: InsightFeedCardType.comebackCard,
            ),
            InsightFeedCard(
              id: 'tall',
              type: InsightFeedCardType.muscleActivationRadar,
              priority: 90,
              title: 'Tall card',
              body: 'Latest workout compared with your recent average.',
              metric: '2',
              accent: 'primary',
              icon: 'radar',
              generatedAt: DateTime(2026, 6, 11),
              visualType: InsightFeedVisualType.radar,
              size: InsightFeedCardSize.featured,
              visualData: const {
                'points': [
                  {
                    'axisId': 'chest',
                    'label': 'Chest',
                    'planned': 0.5,
                    'actual': 1,
                  },
                  {
                    'axisId': 'back',
                    'label': 'Back',
                    'planned': 0.2,
                    'actual': 0.1,
                  },
                  {
                    'axisId': 'legs',
                    'label': 'Legs',
                    'planned': 0.4,
                    'actual': 0.3,
                  },
                ],
              },
            ),
          ],
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

    final railFinder = find.byKey(const Key('insight_feed_stack_rail'));
    final initialHeight = tester.getSize(railFinder).height;

    final gesture = await tester.startGesture(tester.getCenter(railFinder));
    await gesture.moveBy(const Offset(-160, 0));
    await tester.pump();

    final draggedHeight = tester.getSize(railFinder).height;

    expect(draggedHeight, greaterThan(initialHeight));
    expect(draggedHeight, lessThan(396 + 16));

    await gesture.up();
  });

  testWidgets('renders visual feed cards', (tester) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-1',
          type: InsightFeedCardType.consistencyPulse,
          priority: 50,
          title: 'Consistency pulse',
          body:
              'You trained 3 times in the last 14 days compared with your previous pattern.',
          metric: '3/14',
          accent: 'info',
          icon: 'calendar',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.calendarStrip,
          size: InsightFeedCardSize.wide,
          comparisonLabel: 'Previous 14 days: 2 workouts',
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

  testWidgets('renders radar legend labels', (tester) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-radar',
          type: InsightFeedCardType.muscleActivationRadar,
          priority: 90,
          title: 'Muscle focus',
          body: 'Latest workout compared with your 14-day workout average.',
          metric: '2',
          accent: 'primary',
          icon: 'radar',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.radar,
          size: InsightFeedCardSize.featured,
          visualData: const {
            'plannedLabel': '14-day workout average',
            'actualLabel': 'Last workout',
            'points': [
              {
                'axisId': 'chest',
                'label': 'Chest',
                'planned': 0.5,
                'actual': 1,
              },
              {
                'axisId': 'back',
                'label': 'Back',
                'planned': 0.2,
                'actual': 0.1,
              },
              {
                'axisId': 'legs',
                'label': 'Legs',
                'planned': 0.4,
                'actual': 0.3,
              },
            ],
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

    expect(find.text('Muscle focus'), findsOneWidget);
    expect(find.byKey(const Key('insight_feed_visual_radar')), findsOneWidget);
    expect(find.text('14-day workout average'), findsOneWidget);
    expect(find.text('Last workout'), findsOneWidget);
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
  _FakeInsightFeedService({
    List<InsightFeedCard>? cards,
    List<InsightFeedStack>? stacks,
  }) : cards = cards ?? const [],
       stacks =
           stacks ??
           [
             InsightFeedStack(
               id: 'last_workout',
               title: 'Last Workout',
               priority: 100,
               cards: cards ?? const [],
             ),
           ],
       super(
         cacheStore: const InsightsCacheStore(cacheKey: 'insight-feed-fake'),
       );

  final List<InsightFeedCard> cards;
  final List<InsightFeedStack> stacks;

  @override
  Future<List<InsightFeedCard>> getCards({
    bool forceRefresh = false,
    int maxCards = 5,
  }) async {
    return cards;
  }

  @override
  Future<List<InsightFeedStack>> getCardStacks({
    bool forceRefresh = false,
  }) async {
    return stacks.where((stack) => stack.cards.isNotEmpty).toList();
  }
}

InsightFeedCard _feedCard({
  required String id,
  required String title,
  required InsightFeedCardType type,
}) {
  return InsightFeedCard(
    id: id,
    type: type,
    priority: 50,
    title: title,
    body: 'Feed card body.',
    metric: '',
    accent: 'info',
    icon: 'calendar',
    generatedAt: DateTime(2026, 6, 11),
  );
}
