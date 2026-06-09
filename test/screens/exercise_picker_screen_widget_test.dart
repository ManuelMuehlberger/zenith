import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/screens/custom_exercise_creator_screen.dart';
import 'package:zenith/screens/exercise_picker_screen.dart';
import 'package:zenith/services/dao/exercise_dao.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';
import 'package:zenith/services/exercise_service.dart';

class _FakeExerciseDao extends ExerciseDao {
  final List<Exercise> seed;
  _FakeExerciseDao(this.seed);

  @override
  Future<List<Exercise>> getAllExercises() async => seed;

  @override
  Future<Exercise?> getExerciseBySlug(String slug) async {
    for (final exercise in seed) {
      if (exercise.slug == slug) return exercise;
    }
    return null;
  }

  @override
  Future<Exercise> createCustomExercise(Exercise exercise) async {
    seed.add(exercise);
    return exercise;
  }
}

class _FakeMuscleGroupDao extends MuscleGroupDao {
  final List<MuscleGroup> seed;
  _FakeMuscleGroupDao(this.seed);

  @override
  Future<List<MuscleGroup>> getAllMuscleGroups() async => seed;
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
    home: child,
  );
}

void main() {
  setUp(() {
    ExerciseService.instance.resetForTesting();
  });

  testWidgets(
    'ExercisePickerScreen integrates ExerciseListWidget with conditional Clear All and search at top',
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
        seedExercises: exercises,
        seedMuscleGroups: ['Chest', 'Triceps'],
      );

      await tester.pumpWidget(_wrap(const ExercisePickerScreen()));
      await tester.pumpAndSettle();

      // Clear All button should be hidden until a filter is selected
      final clearFinder = find.byKey(const Key('clear_all_button'));
      expect(clearFinder, findsNothing);

      // Search container visible at top initially
      final searchContainerFinder = find.byKey(
        const Key('exercise_search_container'),
      );
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

      // Clear All should now be visible and enabled
      expect(clearFinder, findsOneWidget);
      final enabledClearBtn = tester.widget<CupertinoButton>(clearFinder);
      expect(enabledClearBtn.onPressed, isNotNull);
    },
  );

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
      seedExercises: exercises,
      seedMuscleGroups: ['Chest'],
    );

    await tester.pumpWidget(_wrap(const ExercisePickerScreen()));
    await tester.pumpAndSettle();

    // Find the bodyweight tag button
    final bodyweightButton = find.byKey(const Key('bodyweight_tag_button'));
    expect(bodyweightButton, findsOneWidget);

    // Initially the tag should not be selected (check styling)
    final initialButton = tester.widget<CupertinoButton>(bodyweightButton);
    final initialContainer = initialButton.child as Container;
    final initialDecoration = initialContainer.decoration as BoxDecoration;
    expect(
      initialDecoration.color,
      isNot(equals(Colors.blue)),
    ); // Not selected color

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

  testWidgets(
    'ExercisePickerScreen in single-select mode returns single exercise',
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
      ];
      ExerciseService.instance.setDependenciesForTesting(
        exerciseDao: _FakeExerciseDao(exercises),
        muscleGroupDao: _FakeMuscleGroupDao([
          MuscleGroup.chest,
          MuscleGroup.triceps,
        ]),
        seedExercises: exercises,
        seedMuscleGroups: ['Chest', 'Triceps'],
      );

      Exercise? selectedExercise;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push<Exercise>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExercisePickerScreen(),
                    ),
                  );
                  selectedExercise = result;
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

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
    },
  );

  testWidgets(
    'ExercisePickerScreen in multi-select mode shows Done button and allows multiple selection',
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
      ];
      ExerciseService.instance.setDependenciesForTesting(
        exerciseDao: _FakeExerciseDao(exercises),
        muscleGroupDao: _FakeMuscleGroupDao([
          MuscleGroup.chest,
          MuscleGroup.triceps,
        ]),
        seedExercises: exercises,
        seedMuscleGroups: ['Chest', 'Triceps'],
      );

      List<Exercise>? selectedExercises;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push<List<Exercise>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ExercisePickerScreen(multiSelect: true),
                    ),
                  );
                  selectedExercises = result;
                },
                child: const Text('Open Multi Picker'),
              ),
            ),
          ),
        ),
      );

      // Open the picker
      await tester.tap(find.text('Open Multi Picker'));
      await tester.pumpAndSettle();

      // Verify multi-select mode (Done button present)
      expect(find.text('Done'), findsOneWidget);

      // Initially no exercises selected
      expect(
        find.byIcon(CupertinoIcons.check_mark_circled_solid),
        findsNothing,
      );

      // Tap first exercise
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Should show checkmark for selected exercise
      expect(
        find.byIcon(CupertinoIcons.check_mark_circled_solid),
        findsOneWidget,
      );

      // Tap second exercise
      await tester.tap(find.text('Push-Up'));
      await tester.pumpAndSettle();

      // Should show checkmarks for both selected exercises
      expect(
        find.byIcon(CupertinoIcons.check_mark_circled_solid),
        findsNWidgets(2),
      );

      // Tap Done button
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Should return list of selected exercises
      expect(selectedExercises, isNotNull);
      expect(selectedExercises!.length, equals(2));
      expect(
        selectedExercises!.map((e) => e.slug),
        containsAll(['bench-press', 'push-up']),
      );
    },
  );

  testWidgets(
    'ExercisePickerScreen multi-select mode allows deselecting exercises',
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
      ];
      ExerciseService.instance.setDependenciesForTesting(
        exerciseDao: _FakeExerciseDao(exercises),
        muscleGroupDao: _FakeMuscleGroupDao([
          MuscleGroup.chest,
          MuscleGroup.triceps,
        ]),
        seedExercises: exercises,
        seedMuscleGroups: ['Chest', 'Triceps'],
      );

      await tester.pumpWidget(
        _wrap(const ExercisePickerScreen(multiSelect: true)),
      );
      await tester.pumpAndSettle();

      // Tap exercise to select
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Should show checkmark
      expect(
        find.byIcon(CupertinoIcons.check_mark_circled_solid),
        findsOneWidget,
      );

      // Tap again to deselect
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Should not show checkmark
      expect(
        find.byIcon(CupertinoIcons.check_mark_circled_solid),
        findsNothing,
      );
    },
  );

  testWidgets('ExercisePickerScreen multi-select mode shows info buttons', (
    tester,
  ) async {
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
      muscleGroupDao: _FakeMuscleGroupDao([
        MuscleGroup.chest,
        MuscleGroup.triceps,
      ]),
      seedExercises: exercises,
      seedMuscleGroups: ['Chest', 'Triceps'],
    );

    await tester.pumpWidget(
      _wrap(const ExercisePickerScreen(multiSelect: true)),
    );
    await tester.pumpAndSettle();

    // Should show info button in multi-select mode
    expect(find.byIcon(CupertinoIcons.info_circle), findsOneWidget);
  });

  testWidgets(
    'ExercisePickerScreen single-select mode does not show info buttons',
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
      ];
      ExerciseService.instance.setDependenciesForTesting(
        exerciseDao: _FakeExerciseDao(exercises),
        muscleGroupDao: _FakeMuscleGroupDao([
          MuscleGroup.chest,
          MuscleGroup.triceps,
        ]),
        seedExercises: exercises,
        seedMuscleGroups: ['Chest', 'Triceps'],
      );

      await tester.pumpWidget(_wrap(const ExercisePickerScreen()));
      await tester.pumpAndSettle();

      // Should not show info button in single-select mode
      expect(find.byIcon(CupertinoIcons.info_circle), findsNothing);
      // Should show chevron instead
      expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
    },
  );

  testWidgets('plus button opens custom creator and returns saved exercise', (
    tester,
  ) async {
    final exercises = <Exercise>[];
    ExerciseService.instance.setDependenciesForTesting(
      exerciseDao: _FakeExerciseDao(exercises),
      muscleGroupDao: _FakeMuscleGroupDao([MuscleGroup.chest]),
      seedExercises: exercises,
      seedMuscleGroups: ['Chest'],
    );

    Exercise? selectedExercise;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                selectedExercise = await Navigator.push<Exercise>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExercisePickerScreen(),
                  ),
                );
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_custom_exercise_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('custom_exercise_name_field')),
      'Wall Sit',
    );
    await tester.tap(find.byKey(const Key('primary_muscle_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(selectedExercise, isNotNull);
    expect(selectedExercise!.slug, 'custom-wall-sit');
    expect(selectedExercise!.isCustom, isTrue);
    expect(selectedExercise!.isBodyWeightExercise, isTrue);
  });

  testWidgets('custom creator can save a cardio exercise', (tester) async {
    final exercises = <Exercise>[];
    ExerciseService.instance.setDependenciesForTesting(
      exerciseDao: _FakeExerciseDao(exercises),
      muscleGroupDao: _FakeMuscleGroupDao(MuscleGroup.values.toList()),
      seedExercises: exercises,
      seedMuscleGroups: MuscleGroup.values.map((group) => group.name).toList(),
    );

    Exercise? createdExercise;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                createdExercise = await Navigator.push<Exercise>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomExerciseCreatorScreen(),
                  ),
                );
              },
              child: const Text('Open Creator'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Creator'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomExerciseCreatorScreen), findsOneWidget);
    expect(find.byKey(const Key('custom_exercise_name_field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('custom_exercise_name_field')),
      'Tempo Run',
    );
    await tester.tap(find.byKey(const Key('primary_muscle_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cardio_type_label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(createdExercise, isNotNull);
    expect(createdExercise!.type, ExerciseType.cardio);
    expect(createdExercise!.primaryMuscleGroup, MuscleGroup.chest);
    expect(createdExercise!.isBodyWeightExercise, isTrue);
  });

  testWidgets('custom creator shows a single add-image icon when empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const Scaffold(body: CustomExerciseCreatorScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
  });

  testWidgets('custom creator limits cardio equipment to none and machine', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(body: CustomExerciseCreatorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('equipment_picker')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('equipment_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell'));
    await tester.pumpAndSettle();

    expect(find.text('Barbell'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cardio_type_label')));
    await tester.pumpAndSettle();

    expect(find.text('None'), findsOneWidget);

    await tester.tap(find.byKey(const Key('equipment_picker')));
    await tester.pumpAndSettle();

    expect(find.text('None'), findsWidgets);
    expect(find.text('Machine'), findsOneWidget);
    expect(find.text('Barbell'), findsNothing);
    expect(find.text('Dumbbell'), findsNothing);
    expect(find.text('Cable'), findsNothing);
  });

  testWidgets('custom creator integrates add-step action into the field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(body: CustomExerciseCreatorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final instructionField = find.byKey(
      const Key('custom_exercise_instruction_field'),
    );
    await tester.scrollUntilVisible(
      instructionField,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final addButton = find.byKey(
      const Key('custom_exercise_add_instruction_button'),
    );
    expect(addButton, findsOneWidget);

    var iconButton = tester.widget<IconButton>(addButton);
    expect(iconButton.onPressed, isNull);

    await tester.enterText(instructionField, 'Brace core first');
    await tester.pump();

    iconButton = tester.widget<IconButton>(addButton);
    expect(iconButton.onPressed, isNotNull);

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Brace core first'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(instructionField).controller!.text,
      isEmpty,
    );
  });

  testWidgets('custom creator picker icons light up when values are selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(body: CustomExerciseCreatorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final creatorContext = tester.element(
      find.byType(CustomExerciseCreatorScreen),
    );
    final primaryColor = Theme.of(creatorContext).colorScheme.primary;

    Icon primaryIcon = tester.widget(
      find.byKey(const Key('primary_muscle_picker_icon')),
    );
    Icon secondaryIcon = tester.widget(
      find.byKey(const Key('secondary_muscles_picker_icon')),
    );
    Icon equipmentIcon = tester.widget(
      find.byKey(const Key('equipment_picker_icon')),
    );

    expect(primaryIcon.color, isNot(primaryColor));
    expect(secondaryIcon.color, isNot(primaryColor));
    expect(equipmentIcon.color, isNot(primaryColor));

    await tester.tap(find.byKey(const Key('primary_muscle_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('secondary_muscles_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triceps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('equipment_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell'));
    await tester.pumpAndSettle();

    primaryIcon = tester.widget(
      find.byKey(const Key('primary_muscle_picker_icon')),
    );
    secondaryIcon = tester.widget(
      find.byKey(const Key('secondary_muscles_picker_icon')),
    );
    equipmentIcon = tester.widget(
      find.byKey(const Key('equipment_picker_icon')),
    );

    expect(primaryIcon.color, primaryColor);
    expect(secondaryIcon.color, primaryColor);
    expect(equipmentIcon.color, primaryColor);
  });
}
