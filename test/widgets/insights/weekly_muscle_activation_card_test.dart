import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/insights_service.dart';
import 'package:zenith/services/workout_muscle_activation_service.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/insights/weekly_muscle_activation_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InsightsService.instance.reset();
  });

  tearDown(() {
    InsightsService.instance.reset();
  });

  testWidgets('renders last-month activation with latest workout overlay', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 11, 12);
    final activationService = _FakeWorkoutMuscleActivationService();
    final benchPress = Exercise(
      slug: 'bench-press',
      name: 'Bench Press',
      primaryMuscleGroup: MuscleGroup.chest,
      secondaryMuscleGroups: [],
      instructions: [],
      image: '',
      animation: '',
      muscleActivation: {MuscleGroup.chest: 1},
    );
    InsightsService.instance.setWorkoutsProvider(
      () async => [
        _workout('latest', now.subtract(const Duration(days: 2))),
        _workout('recent', now.subtract(const Duration(days: 12))),
        _workout('old', now.subtract(const Duration(days: 16))),
        _workout(
          'in-progress',
          now.subtract(const Duration(days: 1)),
          status: WorkoutStatus.inProgress,
        ),
        _workout('future', now.add(const Duration(hours: 1))),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WeeklyMuscleActivationCard(
            activationService: activationService,
            exerciseCatalog: {'bench-press': benchPress},
            now: now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Last month activation with your latest workout overlay'),
      findsOneWidget,
    );
    expect(activationService.loadedConfigCount, 1);
    expect(find.text('Last month'), findsNWidgets(2));
    expect(find.text('Last workout'), findsOneWidget);
  });

  testWidgets('hides when no recent activation exists', (tester) async {
    final now = DateTime(2026, 6, 11, 12);
    InsightsService.instance.setWorkoutsProvider(
      () async => [_workout('old', now.subtract(const Duration(days: 16)))],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: WeeklyMuscleActivationCard(now: now)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last month'), findsNothing);
  });
}

class _FakeWorkoutMuscleActivationService
    extends WorkoutMuscleActivationService {
  int loadedConfigCount = 0;

  @override
  Future<WorkoutMuscleActivationConfig> loadConfig() async {
    loadedConfigCount += 1;
    return const WorkoutMuscleActivationConfig(
      primaryWeight: 1,
      secondaryWeight: 0.35,
      axes: [
        WorkoutMuscleActivationAxis(id: 'chest', label: 'Chest'),
        WorkoutMuscleActivationAxis(id: 'back', label: 'Back'),
        WorkoutMuscleActivationAxis(id: 'legs', label: 'Legs'),
      ],
      muscleContributions: {
        MuscleGroup.chest: {'chest': 1},
        MuscleGroup.back: {'back': 1},
        MuscleGroup.quads: {'legs': 1},
      },
    );
  }
}

Workout _workout(
  String id,
  DateTime completedAt, {
  WorkoutStatus status = WorkoutStatus.completed,
}) {
  return Workout(
    id: id,
    name: 'Workout $id',
    status: status,
    startedAt: completedAt.subtract(const Duration(minutes: 45)),
    completedAt: completedAt,
    exercises: [
      WorkoutExercise(
        workoutId: id,
        exerciseSlug: 'bench-press',
        sets: [
          WorkoutSet(
            workoutExerciseId: '$id-exercise',
            setIndex: 0,
            isCompleted: true,
          ),
        ],
      ),
    ],
  );
}
