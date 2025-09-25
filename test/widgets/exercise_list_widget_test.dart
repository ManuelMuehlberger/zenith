import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/dao/exercise_dao.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';
import 'package:zenith/services/exercise_service.dart';
import 'package:zenith/widgets/exercise_list_widget.dart';

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

  testWidgets('ExerciseListWidget - Search bar is visible at top and hides on downward scroll',
      (tester) async {
    // Create a larger dataset to allow scrolling
    final List<Exercise> exercises = List.generate(30, (i) {
      return Exercise(
        slug: 'ex-$i',
        name: 'Exercise $i',
        primaryMuscleGroup: MuscleGroup.back,
        secondaryMuscleGroups: const [],
        instructions: const ['Do it'],
        equipment: i % 2 == 0 ? 'None' : 'Barbell',
        image: '',
        animation: '',
        isBodyWeightExercise: i % 3 == 0,
      );
    });

    ExerciseService.instance.setDependenciesForTesting(
      exerciseDao: _FakeExerciseDao(exercises),
      muscleGroupDao: _FakeMuscleGroupDao([MuscleGroup.back]),
    );

    await tester.pumpWidget(_wrap(ExerciseListWidget(
      onExerciseSelected: (_) {},
    )));
    await tester.pumpAndSettle();

    // Search bar visible at top
    final searchContainerFinder = find.byKey(const Key('exercise_search_container'));
    expect(searchContainerFinder, findsOneWidget);
    final Size searchSize = tester.getSize(searchContainerFinder);
    // height > 0 implies visible
    expect(searchSize.height, greaterThan(0));

    // Scroll down to hide search bar
    final listFinder = find.byType(ListView);
    expect(listFinder, findsOneWidget);
    await tester.fling(listFinder, const Offset(0, -600), 1000); // fling to ensure sufficient scroll
    await tester.pumpAndSettle(); // allow animation to complete

    final Size searchAfterSize = tester.getSize(searchContainerFinder);
    expect(searchAfterSize.height, lessThanOrEqualTo(1));
  });

  testWidgets('ExerciseListWidget - Clear All remains visible after horizontal tag scroll',
      (tester) async {
    final exercises = [
      Exercise(
        slug: 'squat',
        name: 'Squat',
        primaryMuscleGroup: MuscleGroup.quads,
        secondaryMuscleGroups: const [],
        instructions: const ['Squat'],
        equipment: 'Barbell',
        image: '',
        animation: '',
        isBodyWeightExercise: false,
      ),
    ];
    ExerciseService.instance.setDependenciesForTesting(
      exerciseDao: _FakeExerciseDao(exercises),
      muscleGroupDao: _FakeMuscleGroupDao([MuscleGroup.quads]),
    );

    await tester.pumpWidget(_wrap(ExerciseListWidget(
      onExerciseSelected: (_) {},
    )));
    await tester.pumpAndSettle();

    // Ensure Clear All button is present initially
    final clearFinder = find.byKey(const Key('clear_all_button'));
    expect(clearFinder, findsOneWidget);

    // Attempt to horizontally scroll the tags area (inside the filter row)
    final tagsScroll = find.byKey(const Key('tags_scroll'));
    expect(tagsScroll, findsOneWidget);
    await tester.drag(tagsScroll, const Offset(-200, 0));
    await tester.pump();

    // Clear All should still be visible
    expect(clearFinder, findsOneWidget);
  });

  testWidgets('ExerciseListWidget - Multi-select mode shows info buttons', (tester) async {
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

    await tester.pumpWidget(_wrap(ExerciseListWidget(
      onExerciseSelected: (_) {},
      selectedExercises: [], // Multi-select mode
    )));
    await tester.pumpAndSettle();

    // Should show info buttons for all exercises in multi-select mode
    expect(find.byIcon(CupertinoIcons.info_circle), findsNWidgets(2));
  });

  testWidgets('ExerciseListWidget - Single-select mode shows chevron icons', (tester) async {
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

    await tester.pumpWidget(_wrap(ExerciseListWidget(
      onExerciseSelected: (_) {},
      // No selectedExercises parameter = single-select mode
    )));
    await tester.pumpAndSettle();

    // Should show chevron icon in single-select mode
    expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
    // Should not show info button
    expect(find.byIcon(CupertinoIcons.info_circle), findsNothing);
  });

  testWidgets('ExerciseListWidget - Multi-select mode highlights selected exercises', (tester) async {
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

    await tester.pumpWidget(_wrap(ExerciseListWidget(
      onExerciseSelected: (_) {},
      selectedExercises: [exercises[0]], // First exercise selected
    )));
    await tester.pumpAndSettle();

    // Should show checkmark for selected exercise
    expect(find.byIcon(CupertinoIcons.check_mark_circled_solid), findsOneWidget);
    
    // Should not show chevron for selected exercise
    expect(find.byIcon(CupertinoIcons.chevron_right), findsNothing);
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
    await tester.pumpAndSettle();

    // Should navigate to ExerciseInfoScreen (we can't test the actual screen without more setup,
    // but we can verify the tap doesn't cause errors)
    expect(tester.takeException(), isNull);
  });
}
