import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/screens/insights/insights_view_data.dart';
import 'package:zenith/services/insights_service.dart';
import 'package:zenith/services/user_service.dart';
import 'package:zenith/theme/app_theme.dart';
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: InsightsTrendsSection(
                filters: const InsightsFilterSnapshot(timeframe: '6M'),
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
  });
}
