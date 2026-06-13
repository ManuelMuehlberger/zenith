import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/workout_muscle_activation_service.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/workout_muscle_activation_radar_card.dart';

void main() {
  group('WorkoutMuscleActivationRadarCard', () {
    testWidgets('renders activation card content when points are present', (
      WidgetTester tester,
    ) async {
      const profile = WorkoutMuscleActivationProfile(
        points: [
          WorkoutMuscleActivationPoint(
            axisId: 'chest',
            label: 'Chest',
            planned: 1,
            actual: 0.8,
          ),
          WorkoutMuscleActivationPoint(
            axisId: 'back',
            label: 'Back',
            planned: 0.6,
            actual: 0.5,
          ),
          WorkoutMuscleActivationPoint(
            axisId: 'legs',
            label: 'Legs',
            planned: 0.4,
            actual: 0.2,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: WorkoutMuscleActivationRadarCard(profile: profile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('workout_muscle_activation_card')),
        findsOneWidget,
      );
      expect(find.text('Muscle activation'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);
    });

    testWidgets('hides itself when there are no active points', (
      WidgetTester tester,
    ) async {
      const profile = WorkoutMuscleActivationProfile(
        points: [
          WorkoutMuscleActivationPoint(
            axisId: 'chest',
            label: 'Chest',
            planned: 0,
            actual: 0,
          ),
          WorkoutMuscleActivationPoint(
            axisId: 'back',
            label: 'Back',
            planned: 0,
            actual: 0,
          ),
          WorkoutMuscleActivationPoint(
            axisId: 'legs',
            label: 'Legs',
            planned: 0,
            actual: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: WorkoutMuscleActivationRadarCard(profile: profile),
          ),
        ),
      );

      expect(find.byType(WorkoutMuscleActivationRadarCard), findsOneWidget);
      expect(
        find.byKey(const Key('workout_muscle_activation_card')),
        findsNothing,
      );
    });

    testWidgets('renders actual-only mode without planned legend', (
      WidgetTester tester,
    ) async {
      const profile = WorkoutMuscleActivationProfile(
        points: [
          WorkoutMuscleActivationPoint(
            axisId: 'chest',
            label: 'Chest',
            planned: 1,
            actual: 0.8,
          ),
          WorkoutMuscleActivationPoint(
            axisId: 'back',
            label: 'Back',
            planned: 0.6,
            actual: 0.5,
          ),
          WorkoutMuscleActivationPoint(
            axisId: 'legs',
            label: 'Legs',
            planned: 0.4,
            actual: 0.2,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: WorkoutMuscleActivationRadarCard(
              profile: profile,
              showPlanned: false,
              actualLabel: 'Intensity',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Planned'), findsNothing);
      expect(find.text('Intensity'), findsOneWidget);
      expect(find.text('Actual'), findsNothing);
    });
  });
}
