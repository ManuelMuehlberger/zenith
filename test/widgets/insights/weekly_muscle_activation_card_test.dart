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

  testWidgets('renders recent 7-day workout activation', (tester) async {
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
        _workout('recent', now.subtract(const Duration(days: 2))),
        _workout('old', now.subtract(const Duration(days: 9))),
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

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Muscle activation from recent workouts'), findsOneWidget);
    expect(activationService.workoutIds, ['recent']);
    expect(activationService.exerciseDetails, everyElement(isNotNull));
    expect(find.text('Planned'), findsNothing);
    expect(find.text('Intensity'), findsOneWidget);
  });

  testWidgets('hides when no recent activation exists', (tester) async {
    final now = DateTime(2026, 6, 11, 12);
    InsightsService.instance.setWorkoutsProvider(
      () async => [_workout('old', now.subtract(const Duration(days: 9)))],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: WeeklyMuscleActivationCard(now: now)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last 7 days'), findsNothing);
  });
}

class _FakeWorkoutMuscleActivationService
    extends WorkoutMuscleActivationService {
  List<String> workoutIds = const [];
  List<Exercise?> exerciseDetails = const [];

  @override
  Future<WorkoutMuscleActivationProfile> buildProfileForWorkouts(
    Iterable<Workout> workouts,
  ) async {
    workoutIds = workouts.map((workout) => workout.id).toList();
    exerciseDetails = workouts
        .expand((workout) => workout.exercises)
        .map((exercise) => exercise.exerciseDetail)
        .toList();
    return const WorkoutMuscleActivationProfile(
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
