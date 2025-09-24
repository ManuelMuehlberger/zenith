import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/screens/exercise_picker_screen.dart';
import 'package:zenith/services/dao/exercise_dao.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';
import 'package:zenith/services/exercise_service.dart';

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

void main() {
  setUp(() {
    ExerciseService.instance.resetForTesting();
  });

  testWidgets('ExercisePickerScreen integrates ExerciseListWidget with always-visible Clear All and search at top',
      (tester) async {
    // Seed exercises and muscle groups
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
    ];
    ExerciseService.instance.setDependenciesForTesting(
      exerciseDao: _FakeExerciseDao(exercises),
      muscleGroupDao: _FakeMuscleGroupDao([
        MuscleGroup.chest,
        MuscleGroup.triceps,
      ]),
    );

    await tester.pumpWidget(const MaterialApp(home: ExercisePickerScreen()));
    await tester.pumpAndSettle();

    // Clear All button should be present and initially disabled
    final clearFinder = find.byKey(const Key('clear_all_button'));
    expect(clearFinder, findsOneWidget);
    final clearBtn = tester.widget<CupertinoButton>(clearFinder);
    expect(clearBtn.onPressed, isNull);

    // Search container visible at top initially
    final searchContainerFinder = find.byKey(const Key('exercise_search_container'));
    expect(searchContainerFinder, findsOneWidget);
    final Size searchSize = tester.getSize(searchContainerFinder);
    expect(searchSize.height, greaterThan(0));

    // Toggle bodyweight filter to ensure filtering works in picker integration too
    final bodyweightBtn = find.byKey(const Key('bodyweight_tag_button'));
    expect(bodyweightBtn, findsOneWidget);
    await tester.tap(bodyweightBtn);
    await tester.pumpAndSettle();

    // Non-bodyweight should be filtered out
    expect(find.text('Bench Press'), findsNothing);
    expect(find.text('Push-Up'), findsOneWidget);

    // Clear All should now be enabled and visible
    final enabledClearBtn = tester.widget<CupertinoButton>(clearFinder);
    expect(enabledClearBtn.onPressed, isNotNull);
  });

  testWidgets('Bodyweight tag shows check mark when selected', (tester) async {
    final exercises = [
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
    ];
    ExerciseService.instance.setDependenciesForTesting(
      exerciseDao: _FakeExerciseDao(exercises),
      muscleGroupDao: _FakeMuscleGroupDao([MuscleGroup.chest]),
    );

    await tester.pumpWidget(const MaterialApp(home: ExercisePickerScreen()));
    await tester.pumpAndSettle();

    // Initially no check mark
    expect(find.byIcon(CupertinoIcons.check_mark), findsNothing);

    // Tap bodyweight tag to select
    await tester.tap(find.byKey(const Key('bodyweight_tag_button')));
    await tester.pumpAndSettle();

    // Check mark should be visible now
    expect(find.byIcon(CupertinoIcons.check_mark), findsWidgets);
  });
}
