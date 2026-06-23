import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/screens/advanced_insights_screen.dart';
import 'package:zenith/screens/insights_screen.dart';
import 'package:zenith/services/insights_service.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/insights/insights_screen_sections.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InsightsService.instance.reset();
  });

  tearDown(() {
    InsightsService.instance.reset();
  });

  testWidgets('main insights renders feed launcher without global filters', (
    tester,
  ) async {
    InsightsService.instance.setWorkoutsProvider(
      () async => [
        _workout('one', DateTime(2026, 6, 10)),
        _workout('two', DateTime(2026, 6, 11)),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const InsightsScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(find.text('Advanced Insights'), findsOneWidget);
    expect(find.byKey(const Key('workout_filter_tag_button')), findsNothing);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('pull-to-refresh keeps insights content available', (
    tester,
  ) async {
    InsightsService.instance.setWorkoutsProvider(
      () async => [
        _workout('one', DateTime(2026, 6, 10)),
        _workout('two', DateTime(2026, 6, 11)),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const InsightsScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Advanced Insights'), findsOneWidget);
  });

  testWidgets('main insights renders the advanced launcher tile key', (
    tester,
  ) async {
    InsightsService.instance.setWorkoutsProvider(
      () async => [
        _workout('one', DateTime(2026, 6, 10)),
        _workout('two', DateTime(2026, 6, 11)),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const InsightsScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('advanced_insights_launcher')), findsOneWidget);
  });

  testWidgets(
    'advanced launcher opens advanced insights with existing filters',
    (tester) async {
      InsightsService.instance.setWorkoutsProvider(
        () async => [
          _workout('one', DateTime(2026, 6, 10)),
          _workout('two', DateTime(2026, 6, 11)),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const InsightsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('Advanced Insights'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AdvancedInsightsScreen), findsOneWidget);
      expect(
        find.byKey(const Key('workout_filter_tag_button')),
        findsOneWidget,
      );
      expect(find.byType(InsightsGraphCardsGrid), findsOneWidget);
    },
  );

  testWidgets(
    'bottom overscroll does not open advanced insights before ready',
    (tester) async {
      InsightsService.instance.setWorkoutsProvider(
        () async => [
          _workout('one', DateTime(2026, 6, 10)),
          _workout('two', DateTime(2026, 6, 11)),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const InsightsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.maxScrollExtent, lessThanOrEqualTo(320));

      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AdvancedInsightsScreen), findsNothing);
    },
  );

  testWidgets('empty workout history keeps the existing empty state', (
    tester,
  ) async {
    InsightsService.instance.setWorkoutsProvider(() async => []);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const InsightsScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('No Activity Data'), findsOneWidget);
    expect(find.text('Advanced Insights'), findsNothing);
  });
}

Workout _workout(String id, DateTime completedAt) {
  return Workout(
    id: id,
    name: 'Workout $id',
    status: WorkoutStatus.completed,
    startedAt: completedAt.subtract(const Duration(minutes: 45)),
    completedAt: completedAt,
  );
}
