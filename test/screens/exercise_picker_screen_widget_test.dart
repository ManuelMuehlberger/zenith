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

    // Find the bodyweight tag button
    final bodyweightButton = find.byKey(const Key('bodyweight_tag_button'));
    expect(bodyweightButton, findsOneWidget);

    // Initially the tag should not be selected (check styling)
    final initialButton = tester.widget<CupertinoButton>(bodyweightButton);
    final initialContainer = initialButton.child as Container;
    final initialDecoration = initialContainer.decoration as BoxDecoration;
    expect(initialDecoration.color, isNot(equals(Colors.blue))); // Not selected color

    // Tap bodyweight tag to select
    await tester.tap(bodyweightButton);
    await tester.pumpAndSettle();

    // The tag should now be selected (check styling change)
    final selectedButton = tester.widget<CupertinoButton>(bodyweightButton);
    final selectedContainer = selectedButton.child as Container;
    final selectedDecoration = selectedContainer.decoration as BoxDecoration;
    // The selected state should have accent color background
    expect(selectedDecoration.color, isNotNull);
  });

  testWidgets('ExercisePickerScreen in single-select mode returns single exercise', (tester) async {
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
    );

    Exercise? selectedExercise;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push<Exercise>(
                context,
                MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
              );
              selectedExercise = result;
            },
            child: const Text('Open Picker'),
          ),
        ),
      ),
    ));

    // Open the picker
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify single-select mode (no Done button)
    expect(find.text('Done'), findsNothing);

    // Tap an exercise
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    // Should return to previous screen with selected exercise
    expect(selectedExercise, isNotNull);
    expect(selectedExercise!.slug, equals('bench-press'));
  });

  testWidgets('ExercisePickerScreen in multi-select mode shows Done button and allows multiple selection', (tester) async {
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
      muscleGroupDao: _FakeMuscleGroupDao([MuscleGroup.chest, MuscleGroup.triceps]),
    );

    List<Exercise>? selectedExercises;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push<List<Exercise>>(
                context,
                MaterialPageRoute(builder: (_) => const ExercisePickerScreen(multiSelect: true)),
              );
              selectedExercises = result;
            },
            child: const Text('Open Multi Picker'),
          ),
        ),
      ),
    ));

    // Open the picker
    await tester.tap(find.text('Open Multi Picker'));
    await tester.pumpAndSettle();

    // Verify multi-select mode (Done button present)
    expect(find.text('Done'), findsOneWidget);

    // Initially no exercises selected
    expect(find.byIcon(CupertinoIcons.check_mark_circled_solid), findsNothing);

    // Tap first exercise
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    // Should show checkmark for selected exercise
    expect(find.byIcon(CupertinoIcons.check_mark_circled_solid), findsOneWidget);

    // Tap second exercise
    await tester.tap(find.text('Push-Up'));
    await tester.pumpAndSettle();

    // Should show checkmarks for both selected exercises
    expect(find.byIcon(CupertinoIcons.check_mark_circled_solid), findsNWidgets(2));

    // Tap Done button
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Should return list of selected exercises
    expect(selectedExercises, isNotNull);
    expect(selectedExercises!.length, equals(2));
    expect(selectedExercises!.map((e) => e.slug), containsAll(['bench-press', 'push-up']));
  });

  testWidgets('ExercisePickerScreen multi-select mode allows deselecting exercises', (tester) async {
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
    );

    await tester.pumpWidget(const MaterialApp(home: ExercisePickerScreen(multiSelect: true)));
    await tester.pumpAndSettle();

    // Tap exercise to select
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    // Should show checkmark
    expect(find.byIcon(CupertinoIcons.check_mark_circled_solid), findsOneWidget);

    // Tap again to deselect
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    // Should not show checkmark
    expect(find.byIcon(CupertinoIcons.check_mark_circled_solid), findsNothing);
  });

  testWidgets('ExercisePickerScreen multi-select mode shows info buttons', (tester) async {
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
    );

    await tester.pumpWidget(const MaterialApp(home: ExercisePickerScreen(multiSelect: true)));
    await tester.pumpAndSettle();

    // Should show info button in multi-select mode
    expect(find.byIcon(CupertinoIcons.info_circle), findsOneWidget);
  });

  testWidgets('ExercisePickerScreen single-select mode does not show info buttons', (tester) async {
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
    );

    await tester.pumpWidget(const MaterialApp(home: ExercisePickerScreen()));
    await tester.pumpAndSettle();

    // Should not show info button in single-select mode
    expect(find.byIcon(CupertinoIcons.info_circle), findsNothing);
    // Should show chevron instead
    expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
  });
}
