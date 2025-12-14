import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/dao/exercise_dao.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';
import 'package:zenith/services/exercise_service.dart';
import 'package:zenith/widgets/exercise_list_widget.dart';
import 'package:zenith/screens/exercise_info_screen.dart';
import 'package:mockito/mockito.dart' as mockito;

// A mock class for NavigatorObserver
class MockNavigatorObserver extends mockito.Mock implements NavigatorObserver {}

class _FakeExerciseDao extends ExerciseDao {
  final List<Exercise> seed;
  _FakeExerciseDao(this.seed);

  @override
  Future<List<Exercise>> getAllExercises() async => seed;
}

class _FakeMuscleGroupDao extends MuscleGroupDao {
  final List<MuscleGroup> seed;
  _FakeMuscleGroupDao(this.seed);

  @override
  Future<List<MuscleGroup>> getAllMuscleGroups() async => seed;
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() {
    ExerciseService.instance.resetForTesting();
  });

  testWidgets('ExerciseListWidget - Clear All button is always visible and disabled with no filters',
      (tester) async {
    // Seed 3 exercises
    final exercises = [
      Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: const ['Press'],
        equipment: 'Barbell',
        image: '',
        animation: '',
        isBodyWeightExercise: false,
      ),
      Exercise(
        slug: 'push-up',
        name: 'Push-Up',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: const [],
        instructions: const ['Push'],
        equipment: 'None',
        image: '',
        animation: '',
        isBodyWeightExercise: true,
      ),
      Exercise(
        slug: 'plank',
        name: 'Plank',
        primaryMuscleGroup: MuscleGroup.abs,
        secondaryMuscleGroups: const [],
        instructions: const ['Hold'],
        equipment: 'None',
        image: '',
        animation: '',
        isBodyWeightExercise: true,
      ),
    ];
    ExerciseService.instance.setDependenciesForTesting(
      exerciseDao: _FakeExerciseDao(exercises),
      muscleGroupDao: _FakeMuscleGroupDao([
        MuscleGroup.chest,
        MuscleGroup.triceps,
        MuscleGroup.abs,
      ]),
      seedExercises: exercises,
    );

    await tester.pumpWidget(_wrap(ExerciseListWidget(
      onExerciseSelected: (_) {},
    )));
    // Allow loadExercises future and initial layout/animations to settle
    await tester.pumpAndSettle();

    final clearFinder = find.byKey(const Key('clear_all_button'));
    expect(clearFinder, findsOneWidget);

    final CupertinoButton clearBtn = tester.widget(clearFinder);
    // Disabled when no filters selected
    expect(clearBtn.onPressed, isNull);
  });

  testWidgets('ExerciseListWidget - Bodyweight tag toggles filter and Clear All enables/clears',
      (tester) async {
    final exercises = [
      Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: const ['Press'],
        equipment: 'Barbell',
        image: '',
        animation: '',
        isBodyWeightExercise: false,
      ),
      Exercise(
        slug: 'push-up',
        name: 'Push-Up',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: const [],
        instructions: const ['Push'],
        equipment: 'None',
        image: '',
        animation: '',
        isBodyWeightExercise: true,
      ),
      Exercise(
        slug: 'plank',
        name: 'Plank',
        primaryMuscleGroup: MuscleGroup.abs,
        secondaryMuscleGroups: const [],
        instructions: const ['Hold'],
        equipment: 'None',
        image: '',
        animation: '',
        isBodyWeightExercise: true,
      ),
    ];
    ExerciseService.instance.setDependenciesForTesting(
      exerciseDao: _FakeExerciseDao(exercises),
      muscleGroupDao: _FakeMuscleGroupDao([
        MuscleGroup.chest,
        MuscleGroup.triceps,
        MuscleGroup.abs,
      ]),
      seedExercises: exercises,
    );

    await tester.pumpWidget(_wrap(ExerciseListWidget(
      onExerciseSelected: (_) {},
    )));
    await tester.pumpAndSettle();

    // Initially all are visible
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Push-Up'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);

    // Toggle bodyweight filter
    await tester.tap(find.byKey(const Key('bodyweight_tag_button')));
    await tester.pumpAndSettle();

    // Non-bodyweight should be filtered out
    expect(find.text('Bench Press'), findsNothing);
    expect(find.text('Push-Up'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);

    // Clear All should now be enabled
    final clearFinder = find.byKey(const Key('clear_all_button'));
    CupertinoButton clearBtn = tester.widget(clearFinder);
    expect(clearBtn.onPressed, isNotNull);

    // Tap Clear All
    await tester.tap(clearFinder);
    await tester.pumpAndSettle();

    // All items visible again
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Push-Up'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);

    // Clear All disabled again
    clearBtn = tester.widget(clearFinder);
    expect(clearBtn.onPressed, isNull);
  });


  testWidgets('ExerciseListWidget - Multi-select mode calls onExerciseSelected when exercise tapped', (tester) async {
    final exercises = [
      Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: const ['Press'],
        equipment: 'Barbell',
        image: '',
        animation: '',
        isBodyWeightExercise: false,
      ),
    ];
    ExerciseService.instance.setDependenciesForTesting(
      exerciseDao: _FakeExerciseDao(exercises),
      muscleGroupDao: _FakeMuscleGroupDao([MuscleGroup.chest, MuscleGroup.triceps]),
      seedExercises: exercises,
    );

    Exercise? selectedExercise;
    await tester.pumpWidget(_wrap(ExerciseListWidget(
      onExerciseSelected: (exercise) {
        selectedExercise = exercise;
      },
      selectedExercises: [], // Multi-select mode
    )));
    await tester.pumpAndSettle();

    // Tap the exercise
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    // Should call onExerciseSelected with the tapped exercise
    expect(selectedExercise, isNotNull);
    expect(selectedExercise!.slug, equals('bench-press'));
  });

  testWidgets('ExerciseListWidget - Info button navigation works', (tester) async {
    final exercises = [
      Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: const ['Press'],
        equipment: 'Barbell',
        image: '',
        animation: '',
        isBodyWeightExercise: false,
      ),
    ];
    ExerciseService.instance.setDependenciesForTesting(
      exerciseDao: _FakeExerciseDao(exercises),
      muscleGroupDao: _FakeMuscleGroupDao([MuscleGroup.chest, MuscleGroup.triceps]),
      seedExercises: exercises,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExerciseListWidget(
          onExerciseSelected: (_) {},
          selectedExercises: [], // Multi-select mode
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Tap the info button
    await tester.tap(find.byIcon(CupertinoIcons.info_circle));
    // Use pump() instead of pumpAndSettle() to avoid waiting for navigation animation
    await tester.pump();

    // Verify that no exceptions were thrown during navigation
    expect(tester.takeException(), isNull);
  });
}
