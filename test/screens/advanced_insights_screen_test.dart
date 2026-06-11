import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/screens/advanced_insights_screen.dart';
import 'package:zenith/services/insights_service.dart';
import 'package:zenith/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InsightsService.instance.reset();
  });

  tearDown(() {
    InsightsService.instance.reset();
  });

  testWidgets('renders filter header and advanced analytics content', (
    tester,
  ) async {
    InsightsService.instance.setWorkoutsProvider(
      () async => [
        Workout(
          id: 'workout-1',
          name: 'Push Day',
          status: WorkoutStatus.completed,
          startedAt: DateTime(2026, 6, 10, 10),
          completedAt: DateTime(2026, 6, 10, 11),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdvancedInsightsScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Advanced Insights'), findsOneWidget);
    expect(find.byKey(const Key('workout_filter_tag_button')), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
  });
}
