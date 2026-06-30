import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/screens/insights/insights_view_data.dart';
import 'package:zenith/services/insights_service.dart';
import 'package:zenith/services/user_service.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/app_bottom_sheet.dart';
import 'package:zenith/widgets/insights/insights_screen_sections.dart';

void main() {
  group('InsightsTrendsSection', () {
    setUp(() {
      InsightsService.instance.reset();
      InsightsService.instance.setWorkoutsProvider(() async => []);
      UserService.instance.currentProfileForTesting = UserData(
        id: 'user-1',
        name: 'Taylor',
        birthdate: DateTime(1994, 5, 1),
        units: Units.metric,
        weightHistory: [
          WeightEntry(timestamp: DateTime(2026, 5, 1), value: 61.4),
        ],
        createdAt: DateTime(2026, 1, 1),
        theme: 'system',
      );
    });

    tearDown(() {
      UserService.instance.resetForTesting();
      InsightsService.instance.reset();
    });

    testWidgets('renders the body weight trend entry', (tester) async {
      tester.view.physicalSize = const Size(1400, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: InsightsTrendsSection(
                filters: InsightsFilterSnapshot(timeframe: '6M'),
                weightUnitLabel: 'kg',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trends'), findsOneWidget);
      expect(find.text('Body Weight'), findsOneWidget);
    });

    testWidgets('renders the empty state copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                InsightsEmptyStateSliver(
                  fadeAnimation: AlwaysStoppedAnimation<double>(1.0),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('No Activity Data'), findsOneWidget);
      expect(
        find.text('Complete workouts to see your insights'),
        findsOneWidget,
      );
    });

    testWidgets('filter tags open bottom-sheet selectors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  delegate: InsightsFilterHeaderDelegate(
                    timeframeOptions: insightsTimeframeOptions,
                    selectedTimeframe: '6M',
                    selectedWorkoutName: 'Push Day',
                    selectedMuscleGroup: null,
                    selectedEquipment: null,
                    selectedBodyWeight: null,
                    availableWorkoutNames: const ['Push Day', 'Pull Day'],
                    onWorkoutChanged: (_) {},
                    onMuscleChanged: (_) {},
                    onEquipmentChanged: (_) {},
                    onBodyWeightChanged: () {},
                    onClearAll: () {},
                    onTimeframeChanged: (_, unusedMonths) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('workout_filter_tag_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(
        find.byKey(const Key('workout_filter_option_push_day')),
        findsOneWidget,
      );
    });

    testWidgets('app bar renders without a backdrop blur', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                InsightsAppBar(
                  showCalendar: false,
                  onShowCalendar: () {},
                  onHideCalendar: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Insights'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });
}
