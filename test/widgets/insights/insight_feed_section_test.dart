import 'package:fl_chart/fl_chart.dart';
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
          title: 'Training rhythm',
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

    expect(find.text('Training rhythm'), findsOneWidget);
    expect(find.text('3/7'), findsOneWidget);
    expect(find.text('LAST WORKOUT'), findsOneWidget);
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
              title: 'Training rhythm',
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

    expect(find.text('LAST WORKOUT'), findsOneWidget);
    expect(find.text('RECENT TRENDS'), findsOneWidget);
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
    final tallCardHeight = tester
        .getSize(find.byKey(const Key('insight_feed_page_card_tall')))
        .height;

    expect(draggedHeight, greaterThan(initialHeight));
    expect(draggedHeight, lessThan(tallCardHeight + 16));

    await gesture.up();
  });

  testWidgets('renders visual feed cards', (tester) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-1',
          type: InsightFeedCardType.consistencyPulse,
          priority: 50,
          title: 'Training rhythm',
          body: 'You trained 3 times in the last 14 days.',
          metric: '3/14',
          accent: 'info',
          icon: 'calendar',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.calendarStrip,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'recentDays': [
              true,
              false,
              true,
              false,
              false,
              true,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
            ],
            'recentLabels': [
              '28 May',
              '29 May',
              '30 May',
              '31 May',
              '1 Jun',
              '2 Jun',
              '3 Jun',
              '4 Jun',
              '5 Jun',
              '6 Jun',
              '7 Jun',
              '8 Jun',
              '9 Jun',
              '10 Jun',
            ],
            'baselineDays': [
              false,
              true,
              false,
              false,
              false,
              false,
              true,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
            ],
            'baselineLabels': [
              '14 May',
              '15 May',
              '16 May',
              '17 May',
              '18 May',
              '19 May',
              '20 May',
              '21 May',
              '22 May',
              '23 May',
              '24 May',
              '25 May',
              '26 May',
              '27 May',
            ],
            'futureLabels': ['11 Jun', '12 Jun', '13 Jun'],
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

    expect(find.text('Training rhythm'), findsOneWidget);
    expect(
      find.byKey(const Key('insight_feed_visual_calendarStrip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('insight_feed_rhythm_timeline_plot')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('insight_feed_rhythm_timeline_scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('insight_feed_rhythm_workout_legend')),
      findsOneWidget,
    );
    expect(find.byType(Scrollbar), findsNothing);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('10'), findsNothing);
    expect(find.text('Workout day'), findsOneWidget);
    expect(find.text('previous 14 days'), findsNothing);
    expect(find.text('last 14 days'), findsNothing);
    expect(find.textContaining('Previous 14 days:'), findsNothing);

    for (var index = 0; index < 31; index++) {
      expect(
        find.byKey(Key('insight_feed_rhythm_tick_$index')),
        findsOneWidget,
      );
    }
    expect(find.text('May'), findsOneWidget);
    expect(find.text('Jun'), findsOneWidget);
    expect(find.text('12 Jun'), findsNothing);

    await tester.drag(
      find.byKey(const Key('insight_feed_rhythm_timeline_scroll')),
      const Offset(120, 0),
    );
    await tester.pump();
  });

  testWidgets('today indicator turns neutral when today has no workout', (
    tester,
  ) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-2',
          type: InsightFeedCardType.consistencyPulse,
          priority: 50,
          title: 'Training rhythm',
          body: 'You trained 2 times in the last 14 days.',
          metric: '2/14',
          accent: 'info',
          icon: 'calendar',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.calendarStrip,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'recentDays': [
              true,
              false,
              true,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
            ],
            'recentLabels': [
              '28 May',
              '29 May',
              '30 May',
              '31 May',
              '1 Jun',
              '2 Jun',
              '3 Jun',
              '4 Jun',
              '5 Jun',
              '6 Jun',
              '7 Jun',
              '8 Jun',
              '9 Jun',
              '10 Jun',
            ],
            'baselineDays': [
              false,
              true,
              false,
              false,
              false,
              false,
              true,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
            ],
            'baselineLabels': [
              '14 May',
              '15 May',
              '16 May',
              '17 May',
              '18 May',
              '19 May',
              '20 May',
              '21 May',
              '22 May',
              '23 May',
              '24 May',
              '25 May',
              '26 May',
              '27 May',
            ],
            'futureLabels': ['11 Jun', '12 Jun', '13 Jun'],
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

    final todayIndicatorDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byKey(const Key('insight_feed_rhythm_tick_27')),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as BoxDecoration;
    expect(
      todayIndicatorDecoration.color,
      AppTheme.light.colorScheme.onSurface,
    );
    final todayText = tester.widget<Text>(find.text('Today'));
    expect(
      todayText.style?.color,
      AppTheme.light.extension<AppThemeTokens>()!.textTertiary,
    );
    expect(find.text('10'), findsNothing);
  });

  testWidgets('today indicator highlights when today has a workout', (
    tester,
  ) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-3',
          type: InsightFeedCardType.consistencyPulse,
          priority: 50,
          title: 'Training rhythm',
          body: 'You trained 3 times in the last 14 days.',
          metric: '3/14',
          accent: 'info',
          icon: 'calendar',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.calendarStrip,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'recentDays': [
              true,
              false,
              true,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              true,
            ],
            'recentLabels': [
              '28 May',
              '29 May',
              '30 May',
              '31 May',
              '1 Jun',
              '2 Jun',
              '3 Jun',
              '4 Jun',
              '5 Jun',
              '6 Jun',
              '7 Jun',
              '8 Jun',
              '9 Jun',
              '10 Jun',
            ],
            'baselineDays': [
              false,
              true,
              false,
              false,
              false,
              false,
              true,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
            ],
            'baselineLabels': [
              '14 May',
              '15 May',
              '16 May',
              '17 May',
              '18 May',
              '19 May',
              '20 May',
              '21 May',
              '22 May',
              '23 May',
              '24 May',
              '25 May',
              '26 May',
              '27 May',
            ],
            'futureLabels': ['11 Jun', '12 Jun', '13 Jun'],
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

    final highlightedTodayText = tester.widget<Text>(find.text('Today'));
    expect(
      highlightedTodayText.style?.color,
      AppTheme.light.extension<AppThemeTokens>()!.info,
    );
    expect(find.text('10'), findsNothing);
    final todayIndicatorDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byKey(const Key('insight_feed_rhythm_tick_27')),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as BoxDecoration;
    expect(
      todayIndicatorDecoration.color,
      AppTheme.light.extension<AppThemeTokens>()!.info,
    );
  });

  testWidgets('renders baseline bar legend below the graph with delta labels', (
    tester,
  ) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-latest',
          type: InsightFeedCardType.latestWorkoutComparison,
          priority: 50,
          title: 'Workout progress',
          body: 'Workout latest compared with your recent baseline.',
          metric: '+39%',
          accent: 'success',
          icon: 'chart',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.baselineBars,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'items': [
              {
                'label': 'Duration',
                'baseline': 36.0,
                'actual': 50.0,
                'deltaLabel': '70%',
                'unit': 'min',
              },
              {
                'label': 'Sets',
                'baseline': 3.0,
                'actual': 4.0,
                'deltaLabel': '39%',
                'unit': 'sets',
              },
              {
                'label': 'Volume',
                'baseline': 1500.0,
                'actual': 2000.0,
                'deltaLabel': '97%',
                'unit': '',
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

    expect(find.text('Workout progress'), findsOneWidget);
    expect(find.text('recent baseline'), findsNothing);
    expect(find.text('+70%'), findsOneWidget);
    expect(find.text('+39%'), findsNothing);
    expect(find.text('+97%'), findsNothing);
    expect(find.text('39%'), findsOneWidget);
    expect(find.text('97%'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('+39%'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('+97%'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('+70%'), findsOneWidget);

    final cardHeight = tester
        .getSize(find.byKey(const Key('insight_feed_page_card_card-latest')))
        .height;
    expect(cardHeight, 248);

    final durationLabel = tester.getTopLeft(find.text('Duration'));
    final baselineLegend = tester.getTopLeft(find.text('baseline'));
    expect(baselineLegend.dy, greaterThan(durationLabel.dy));
  });

  testWidgets('baseline bar legend stays visible when tapped', (tester) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-latest',
          type: InsightFeedCardType.latestWorkoutComparison,
          priority: 50,
          title: 'Workout progress',
          body: 'Workout latest compared with your recent baseline.',
          metric: '+39%',
          accent: 'success',
          icon: 'chart',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.baselineBars,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'items': [
              {
                'label': 'Duration',
                'baseline': 36.0,
                'actual': 50.0,
                'deltaLabel': '70%',
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

    expect(find.byKey(const Key('insight_feed_baseline_bar')), findsOneWidget);
    expect(find.byKey(const Key('insight_feed_latest_bar')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('insight_feed_baseline_bars_legend_baseline')),
    );
    await tester.pump();

    expect(find.byKey(const Key('insight_feed_baseline_bar')), findsOneWidget);
    expect(find.byKey(const Key('insight_feed_latest_bar')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('insight_feed_baseline_bars_legend_latest')),
    );
    await tester.pump();

    expect(find.byKey(const Key('insight_feed_baseline_bar')), findsOneWidget);
    expect(find.byKey(const Key('insight_feed_latest_bar')), findsOneWidget);
  });

  testWidgets('advanced insights launcher exposes home-style pull state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AdvancedInsightsLauncher(
            onPressed: () {},
            glowProgress: 1,
            pullProgress: 1,
            detentArmed: true,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('advanced_insights_launcher')), findsOneWidget);
    expect(find.text('Advanced Insights'), findsOneWidget);

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const Key('advanced_insights_launcher')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final padding = container.padding as EdgeInsets;

    expect(padding.left, 20);
    expect(padding.top, 12);
  });

  testWidgets('labels body weight trend line and baseline', (tester) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-weight',
          type: InsightFeedCardType.bodyWeightTrend,
          priority: 50,
          title: 'Body weight trend',
          body: 'Your latest body weight compared with recent entries.',
          metric: '+1.2',
          accent: 'info',
          icon: 'weight',
          generatedAt: DateTime(2026, 6, 11),
          comparisonLabel: '90 day trend',
          visualType: InsightFeedVisualType.bodyWeightLine,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'points': [
              {
                'label': '5/1',
                'date': '2026-05-01T12:00:00.000',
                'value': 81.2,
              },
              {
                'label': '5/15',
                'date': '2026-05-15T12:00:00.000',
                'value': 81.8,
              },
              {
                'label': '6/1',
                'date': '2026-06-01T12:00:00.000',
                'value': 82.4,
              },
            ],
            'baseline': 81.2,
            'unit': '',
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

    expect(
      find.byKey(const Key('insight_feed_visual_bodyWeightLine')),
      findsOneWidget,
    );
    expect(find.text('logged weight'), findsOneWidget);
    expect(find.text('avg / 1m'), findsOneWidget);
    expect(find.text('average'), findsNothing);
    expect(find.text('start'), findsNothing);
    expect(find.text('5/1'), findsOneWidget);
    expect(find.text('6/1'), findsOneWidget);
    final endLabel = tester.getTopLeft(find.text('6/1'));
    final legendLabel = tester.getTopLeft(find.text('logged weight'));
    expect(legendLabel.dy, greaterThan(endLabel.dy));
    expect(find.text('90 day trend'), findsNothing);
  });

  testWidgets('renders balance fingerprint visual without radar', (
    tester,
  ) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-balance',
          type: InsightFeedCardType.trainingBalance,
          priority: 90,
          title: 'Training balance',
          body: 'Your long-term work leans Chest. Prioritize Back next.',
          metric: '68%',
          accent: 'info',
          icon: 'chart',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.balanceFingerprint,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'segments': [
              {
                'axisId': 'chest',
                'label': 'Chest',
                'value': 20.0,
                'percent': 0.55,
              },
              {
                'axisId': 'legs',
                'label': 'Legs',
                'value': 10.0,
                'percent': 0.30,
              },
              {
                'axisId': 'back',
                'label': 'Back',
                'value': 5.0,
                'percent': 0.15,
              },
            ],
            'dominantLabel': 'Chest',
            'focusLabel': 'Back',
            'balanceScore': 68.0,
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

    expect(
      find.byKey(const Key('insight_feed_visual_balanceFingerprint')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('insight_feed_balance_fingerprint_bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('insight_feed_balance_segment_chest')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('insight_feed_balance_score_line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('insight_feed_balance_score_marker')),
      findsOneWidget,
    );
    expect(find.text('68%'), findsWidgets);
    expect(find.text('68'), findsNothing);
    expect(find.text('Balance'), findsNothing);
    expect(find.text('Dominant'), findsNothing);
    expect(find.text('Focus'), findsNothing);
    expect(find.text('Chest'), findsWidgets);
    expect(
      find.text('Tap a segment to inspect its long-term share'),
      findsOneWidget,
    );
    expect(find.byType(RadarChart), findsNothing);

    await tester.tap(
      find.byKey(const Key('insight_feed_balance_segment_chest')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Chest accounts for 55% of long-term work'),
      findsOneWidget,
    );
    final selectedLeadingDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byKey(
                      const Key('insight_feed_balance_segment_chest'),
                    ),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as BoxDecoration;
    expect(
      selectedLeadingDecoration.borderRadius,
      const BorderRadius.horizontal(left: Radius.circular(14)),
    );

    await tester.tap(
      find.byKey(const Key('insight_feed_balance_segment_back')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Back accounts for 15% of long-term work'),
      findsOneWidget,
    );
    final selectedTrailingDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byKey(
                      const Key('insight_feed_balance_segment_back'),
                    ),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as BoxDecoration;
    expect(
      selectedTrailingDecoration.borderRadius,
      const BorderRadius.horizontal(right: Radius.circular(14)),
    );

    await tester.tap(
      find.byKey(const Key('insight_feed_balance_segment_back')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Tap a segment to inspect its long-term share'),
      findsOneWidget,
    );
  });

  testWidgets('balance fingerprint ignores malformed segments', (tester) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-balance-empty',
          type: InsightFeedCardType.trainingBalance,
          priority: 90,
          title: 'Training balance',
          body: 'Balance body.',
          metric: '0',
          accent: 'info',
          icon: 'chart',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.balanceFingerprint,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'segments': [
              {'axisId': 'chest', 'label': 'Chest', 'percent': 1.0},
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

    expect(find.text('Training balance'), findsOneWidget);
    expect(
      find.byKey(const Key('insight_feed_balance_fingerprint_bar')),
      findsNothing,
    );
  });

  testWidgets('sparkline reference legend updates painter inputs', (
    tester,
  ) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-weight',
          type: InsightFeedCardType.bodyWeightTrend,
          priority: 50,
          title: 'Body weight trend',
          body: 'Your latest body weight compared with recent entries.',
          metric: '+1.2',
          accent: 'info',
          icon: 'weight',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.bodyWeightLine,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'points': [
              {
                'label': '5/1',
                'date': '2026-05-01T12:00:00.000',
                'value': 81.2,
              },
              {
                'label': '5/15',
                'date': '2026-05-15T12:00:00.000',
                'value': 81.8,
              },
              {
                'label': '6/1',
                'date': '2026-06-01T12:00:00.000',
                'value': 82.4,
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

    dynamic painter = tester
        .widget<CustomPaint>(
          find.byKey(const Key('insight_feed_sparkline_plot')),
        )
        .painter;
    expect(painter.showReference, isTrue);

    await tester.tap(
      find.byKey(const Key('insight_feed_sparkline_legend_reference')),
    );
    await tester.pump();

    painter = tester
        .widget<CustomPaint>(
          find.byKey(const Key('insight_feed_sparkline_plot')),
        )
        .painter;
    expect(painter.showReference, isFalse);
    expect(painter.showPrimary, isTrue);
  });

  testWidgets('renders radar legend labels', (tester) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-radar',
          type: InsightFeedCardType.muscleActivationRadar,
          priority: 90,
          title: 'Muscle focus',
          body: 'Latest workout compared with your recent average.',
          metric: '2',
          accent: 'primary',
          icon: 'radar',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.radar,
          size: InsightFeedCardSize.featured,
          visualData: const {
            'plannedLabel': 'recent average',
            'actualLabel': 'Push Day A',
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
    expect(find.text('recent average'), findsOneWidget);
    expect(find.text('Push Day A'), findsOneWidget);
    expect(find.text('2'), findsNothing);

    final latestLegend = tester.getTopLeft(
      find.byKey(const Key('insight_feed_radar_legend_latest')),
    );
    final averageLegend = tester.getTopLeft(
      find.byKey(const Key('insight_feed_radar_legend_average')),
    );
    expect(latestLegend.dx, lessThan(averageLegend.dx));
  });

  testWidgets('radar legend tap hides and restores the matching dataset', (
    tester,
  ) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'card-radar',
          type: InsightFeedCardType.muscleActivationRadar,
          priority: 90,
          title: 'Muscle focus',
          body: 'Latest workout compared with your recent average.',
          metric: '2',
          accent: 'primary',
          icon: 'radar',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.radar,
          size: InsightFeedCardSize.featured,
          visualData: const {
            'plannedLabel': 'recent average',
            'actualLabel': 'Push Day A',
            'points': [
              {'label': 'Chest', 'planned': 0.5, 'actual': 1},
              {'label': 'Back', 'planned': 0.2, 'actual': 0.1},
              {'label': 'Legs', 'planned': 0.4, 'actual': 0.3},
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

    RadarChart radar = tester.widget(find.byType(RadarChart));
    expect(radar.data.dataSets, hasLength(2));

    await tester.tap(find.byKey(const Key('insight_feed_radar_legend_latest')));
    await tester.pump();

    radar = tester.widget(find.byType(RadarChart));
    expect(radar.data.dataSets, hasLength(2));
    expect(radar.data.dataSets.last.entryRadius, 0);

    await tester.tap(find.byKey(const Key('insight_feed_radar_legend_latest')));
    await tester.pump();

    radar = tester.widget(find.byType(RadarChart));
    expect(radar.data.dataSets, hasLength(2));
    expect(radar.data.dataSets.last.entryRadius, 3);
  });

  testWidgets('renders compact training velocity legend labels', (
    tester,
  ) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'velocity',
          type: InsightFeedCardType.trainingVelocity,
          priority: 90,
          title: 'Training velocity',
          body: '2.0 workouts/week in the last 7 days.',
          metric: '+25%',
          accent: 'success',
          icon: 'bolt',
          generatedAt: DateTime(2026, 6, 20),
          visualType: InsightFeedVisualType.trainingVelocityLine,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'points': [
              {'label': '5/1', 'value': 1.2},
              {'label': '5/8', 'value': 1.8},
              {'label': '5/15', 'value': 2.0},
            ],
            'average': 1.4,
            'summaryItems': [
              {'label': 'Recent', 'displayValue': '2.0/wk'},
              {'label': 'Baseline', 'displayValue': '1.4/wk'},
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

    expect(find.text('Recent 2.0/wk'), findsOneWidget);
    expect(find.text('Baseline 1.4/wk'), findsOneWidget);
    expect(find.text('5/1'), findsOneWidget);
    expect(find.text('5/15'), findsOneWidget);
  });

  testWidgets('velocity average legend updates painter inputs', (tester) async {
    final service = _FakeInsightFeedService(
      cards: [
        InsightFeedCard(
          id: 'velocity',
          type: InsightFeedCardType.trainingVelocity,
          priority: 90,
          title: 'Training velocity',
          body: '2.0 workouts/week in the last 7 days.',
          metric: '+25%',
          accent: 'success',
          icon: 'bolt',
          generatedAt: DateTime(2026, 6, 20),
          visualType: InsightFeedVisualType.trainingVelocityLine,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'points': [
              {'label': '5/1', 'value': 1.2},
              {'label': '5/8', 'value': 1.8},
              {'label': '5/15', 'value': 2.0},
            ],
            'average': 1.4,
            'summaryItems': [
              {'label': 'Recent', 'displayValue': '2.0/wk'},
              {'label': 'Baseline', 'displayValue': '1.4/wk'},
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

    dynamic painter = tester
        .widget<CustomPaint>(
          find.byKey(const Key('insight_feed_velocity_plot')),
        )
        .painter;
    expect(painter.showAverage, isTrue);

    await tester.tap(
      find.byKey(const Key('insight_feed_velocity_legend_average')),
    );
    await tester.pump();

    painter = tester
        .widget<CustomPaint>(
          find.byKey(const Key('insight_feed_velocity_plot')),
        )
        .painter;
    expect(painter.showAverage, isFalse);
    expect(painter.showValues, isTrue);
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

  testWidgets('insets the achievement card icon evenly from top and left', (
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

    final cardTop = tester.getTopLeft(
      find.byKey(const Key('insight_feed_visual_awardPreview')),
    );
    final iconTopLeft = tester.getTopLeft(
      find.byKey(const Key('insight_feed_award_icon_container')),
    );

    expect(iconTopLeft.dx - cardTop.dx, closeTo(16, 0.01));
    expect(iconTopLeft.dy - cardTop.dy, closeTo(16, 0.01));
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
