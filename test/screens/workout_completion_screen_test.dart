import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/screens/workout_completion_screen.dart';
import 'package:zenith/services/user_service.dart';
import 'package:zenith/services/workout_muscle_activation_service.dart';
import 'package:zenith/widgets/app_bottom_sheet.dart';
import 'package:zenith/widgets/weight_picker_wheel.dart';

class _FakeWorkoutMuscleActivationService
    extends WorkoutMuscleActivationService {
  _FakeWorkoutMuscleActivationService(this.profile);

  final WorkoutMuscleActivationProfile profile;

  @override
  Future<WorkoutMuscleActivationProfile> buildProfile(Workout workout) async {
    return profile;
  }
}

void main() {
  group('WorkoutCompletionScreen', () {
    setUp(() {
      UserService.instance.currentProfileForTesting = UserData(
        id: 'user-1',
        name: 'Tester',
        birthdate: DateTime(1990, 1, 1),
        units: Units.metric,
        weightHistory: [
          WeightEntry(timestamp: DateTime(2026, 5, 1), value: 74.2),
        ],
        createdAt: DateTime(2026, 1, 1),
        theme: 'system',
      );
    });

    tearDown(() {
      UserService.instance.resetForTesting();
    });

    testWidgets('shows elapsed duration when completedAt is null', (
      WidgetTester tester,
    ) async {
      final startedAt = DateTime.now().subtract(
        const Duration(minutes: 1, seconds: 10),
      );
      final session = Workout(
        name: 'Test Workout',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutCompletionScreen(session: session)),
      );
      await tester.pump();

      final durationFinder = find.descendant(
        of: find.byKey(const Key('duration_summary')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              RegExp(r'^\d+h \d+m$|^\d+m$').hasMatch(widget.data!),
        ),
      );

      expect(durationFinder, findsOneWidget);
    });

    testWidgets('uses completedAt when present to display duration', (
      WidgetTester tester,
    ) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 30));
      const duration = Duration(minutes: 12, seconds: 34);
      final completedAt = startedAt.add(duration);

      final session = Workout(
        name: 'Completed Workout',
        status: WorkoutStatus.completed,
        startedAt: startedAt,
        completedAt: completedAt,
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutCompletionScreen(session: session)),
      );
      await tester.pump();

      final durationFinder = find.descendant(
        of: find.byKey(const Key('duration_summary')),
        matching: find.text('12m'),
      );

      expect(durationFinder, findsOneWidget);
    });

    testWidgets('mood labels are not shown (only emojis)', (
      WidgetTester tester,
    ) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 1));
      final session = Workout(
        name: 'No Labels',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutCompletionScreen(session: session)),
      );

      // Ensure old mood labels are not present
      const labels = ['Very Sad', 'Sad', 'Neutral', 'Happy', 'Very Happy'];
      for (final label in labels) {
        expect(find.text(label), findsNothing);
      }
    });

    testWidgets('shows latest weight and opens weight picker wheel', (
      WidgetTester tester,
    ) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 1));
      final session = Workout(
        name: 'Weight Log',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutCompletionScreen(
            session: session,
            muscleActivationService: _FakeWorkoutMuscleActivationService(
              const WorkoutMuscleActivationProfile(
                points: [
                  WorkoutMuscleActivationPoint(
                    axisId: 'chest',
                    label: 'Chest',
                    planned: 1,
                    actual: 0.5,
                  ),
                  WorkoutMuscleActivationPoint(
                    axisId: 'arms',
                    label: 'Arms',
                    planned: 0.3,
                    actual: 0.2,
                  ),
                  WorkoutMuscleActivationPoint(
                    axisId: 'core',
                    label: 'Core',
                    planned: 0.2,
                    actual: 0.1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Latest: 74.2 kg'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('weight_summary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('weight_summary')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('post_workout_weight_picker')),
        findsOneWidget,
      );
      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBottomSheet),
          matching: find.text('Weight'),
        ),
        findsOneWidget,
      );
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBottomSheet),
          matching: find.byType(Divider),
        ),
        findsNothing,
      );

      final picker = tester.widget<WeightPickerWheel>(
        find.byType(WeightPickerWheel),
      );
      expect(
        picker.selectionOverlayRadius,
        PickerSelectionStyle.emphasizedRadius,
      );
    });

    testWidgets('shows both completion actions', (WidgetTester tester) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 1));
      final session = Workout(
        name: 'Action Check',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutCompletionScreen(session: session)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('back_to_workout_btn')), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('shows muscle activation radar when exercise details exist', (
      WidgetTester tester,
    ) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 1));
      final session = Workout(
        name: 'Activation Check',
        status: WorkoutStatus.inProgress,
        startedAt: startedAt,
        exercises: [
          WorkoutExercise(
            workoutId: 'workout-1',
            exerciseSlug: 'bench-press',
            exerciseDetail: Exercise(
              slug: 'bench-press',
              name: 'Bench Press',
              primaryMuscleGroup: MuscleGroup.chest,
              secondaryMuscleGroups: const [MuscleGroup.triceps],
              instructions: const [],
              image: '',
              animation: '',
            ),
            sets: [
              WorkoutSet(
                workoutExerciseId: 'exercise-1',
                setIndex: 0,
                isCompleted: true,
              ),
              WorkoutSet(workoutExerciseId: 'exercise-1', setIndex: 1),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutCompletionScreen(
            session: session,
            muscleActivationService: _FakeWorkoutMuscleActivationService(
              const WorkoutMuscleActivationProfile(
                points: [
                  WorkoutMuscleActivationPoint(
                    axisId: 'chest',
                    label: 'Chest',
                    planned: 1,
                    actual: 0.5,
                  ),
                  WorkoutMuscleActivationPoint(
                    axisId: 'arms',
                    label: 'Arms',
                    planned: 0.3,
                    actual: 0.2,
                  ),
                  WorkoutMuscleActivationPoint(
                    axisId: 'core',
                    label: 'Core',
                    planned: 0.2,
                    actual: 0.1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        find.byKey(const Key('workout_muscle_activation_card')),
        findsOneWidget,
      );
      expect(find.text('Muscle activation'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);
    });
  });
}
