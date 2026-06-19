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
          body:
              'You trained 3 times in the last 14 days compared with your previous pattern.',
          metric: '3/14',
          accent: 'info',
          icon: 'calendar',
          generatedAt: DateTime(2026, 6, 11),
          visualType: InsightFeedVisualType.calendarStrip,
          size: InsightFeedCardSize.wide,
          visualData: const {
            'recentDays': [true, false, true, false, false, true, false],
            'recentLabels': [
              '4 Jun',
              '5 Jun',
              '6 Jun',
              '7 Jun',
              '8 Jun',
              '9 Jun',
              '10 Jun',
            ],
            'baselineDays': [false, true, false, false, false, false, true],
            'baselineLabels': [
              '28 May',
              '29 May',
              '30 May',
              '31 May',
              '1 Jun',
              '2 Jun',
              '3 Jun',
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

    expect(find.text('Training rhythm'), findsOneWidget);
    expect(
      find.byKey(const Key('insight_feed_visual_calendarStrip')),
      findsOneWidget,
    );
    expect(find.text('previous 7 days'), findsOneWidget);
    expect(find.text('last 7 days'), findsOneWidget);
    expect(find.text('4 Jun'), findsOneWidget);
    expect(find.text('5 Jun'), findsOneWidget);
    expect(find.text('6 Jun'), findsOneWidget);
    expect(find.text('7 Jun'), findsOneWidget);
    expect(find.text('8 Jun'), findsNothing);
    expect(find.text('9 Jun'), findsOneWidget);
    expect(find.text('10 Jun'), findsOneWidget);
    expect(find.textContaining('Previous 14 days:'), findsNothing);

    final dayStripsBefore = find.byType(AnimatedContainer);
    expect(dayStripsBefore, findsNWidgets(14));

    await tester.tap(
      find.byKey(const Key('insight_feed_calendar_legend_previous')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('insight_feed_calendar_legend_recent')),
    );
    await tester.pump();

    expect(find.byType(AnimatedContainer), findsNWidgets(14));
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
