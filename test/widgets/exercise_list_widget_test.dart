import 'dart:convert';

import 'package:flutter/cupertino.dart';

// Test file reviewed for WorkoutSet field additions
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/screens/exercise_image_gallery_screen.dart';
import 'package:zenith/services/dao/exercise_dao.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';
import 'package:zenith/services/exercise_service.dart';
import 'package:zenith/widgets/exercise_list_widget.dart';

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
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() {
    ExerciseService.instance.resetForTesting();
  });

  testWidgets(
    'ExerciseListWidget - Clear All button is hidden with no filters',
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

      await tester.pumpWidget(
        _wrap(ExerciseListWidget(onExerciseSelected: (_) {})),
      );
      // Allow loadExercises future and initial layout/animations to settle
      await tester.pumpAndSettle();

      final clearFinder = find.byKey(const Key('clear_all_button'));
      expect(clearFinder, findsNothing);
    },
  );

  testWidgets(
    'ExerciseListWidget - Bodyweight tag toggles filter and Clear All enables/clears',
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

      await tester.pumpWidget(
        _wrap(ExerciseListWidget(onExerciseSelected: (_) {})),
      );
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

      // Clear All should now be visible and enabled
      final clearFinder = find.byKey(const Key('clear_all_button'));
      expect(clearFinder, findsOneWidget);
      final CupertinoButton clearBtn = tester.widget(clearFinder);
      expect(clearBtn.onPressed, isNotNull);
      final Icon clearIcon = tester.widget(
        find.descendant(
          of: clearFinder,
          matching: find.byIcon(CupertinoIcons.xmark_circle_fill),
        ),
      );
      expect(clearIcon.icon, CupertinoIcons.xmark_circle_fill);

      // Tap Clear All
      await tester.tap(clearFinder);
      await tester.pumpAndSettle();

      // All items visible again
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Push-Up'), findsOneWidget);
      expect(find.text('Plank'), findsOneWidget);

      // Clear All disappears again
      expect(clearFinder, findsNothing);
    },
  );

  testWidgets(
    'ExerciseListWidget - Multi-select mode calls onExerciseSelected when exercise tapped',
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
      );

      Exercise? selectedExercise;
      await tester.pumpWidget(
        _wrap(
          ExerciseListWidget(
            onExerciseSelected: (exercise) {
              selectedExercise = exercise;
            },
            selectedExercises: const [], // Multi-select mode
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the exercise
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Should call onExerciseSelected with the tapped exercise
      expect(selectedExercise, isNotNull);
      expect(selectedExercise!.slug, equals('bench-press'));
    },
  );

  testWidgets('ExerciseListWidget - Info button navigation works', (
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
    );

    await tester.pumpWidget(
      _wrap(
        ExerciseListWidget(
          onExerciseSelected: (_) {},
          selectedExercises: const [], // Multi-select mode
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the info button
    await tester.tap(find.byIcon(CupertinoIcons.info_circle));
    // Use pump() instead of pumpAndSettle() to avoid waiting for navigation animation
    await tester.pump();

    // Verify that no exceptions were thrown during navigation
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ExerciseListWidget - preview placeholder matches detail page icon treatment',
    (tester) async {
      final exercises = [
        Exercise(
          slug: 'air-bike',
          name: 'Air Bike',
          primaryMuscleGroup: MuscleGroup.cardio,
          secondaryMuscleGroups: const [],
          instructions: const ['Pedal hard'],
          equipment: 'Machine',
          image: '',
          animation: 'assets/animations/air_bike.gif',
          isBodyWeightExercise: true,
          type: ExerciseType.cardio,
        ),
      ];
      ExerciseService.instance.setDependenciesForTesting(
        exerciseDao: _FakeExerciseDao(exercises),
        muscleGroupDao: _FakeMuscleGroupDao([MuscleGroup.cardio]),
        seedExercises: exercises,
      );

      await tester.pumpWidget(
        _wrap(ExerciseListWidget(onExerciseSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      final preview = find.byKey(const Key('exercise_card_image_air-bike'));
      final playIcon = find.descendant(
        of: preview,
        matching: find.byIcon(Icons.play_circle_outline),
      );

      expect(playIcon, findsOneWidget);
      expect(
        find.descendant(
          of: preview,
          matching: find.byIcon(Icons.directions_run_rounded),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'ExerciseListWidget - muscle filter sheet dismisses when tapping above it',
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
      );

      await tester.pumpWidget(
        _wrap(ExerciseListWidget(onExerciseSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('muscle_filter_tag_button')));
      await tester.pumpAndSettle();

      expect(find.text('MUSCLE GROUP'), findsOneWidget);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('MUSCLE GROUP'), findsNothing);
    },
  );

  testWidgets(
    'ExerciseListWidget - muscle filter sheet shows flush-bottom options',
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
      );

      await tester.pumpWidget(
        _wrap(ExerciseListWidget(onExerciseSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('muscle_filter_tag_button')));
      await tester.pumpAndSettle();

      expect(find.text('MUSCLE GROUP'), findsOneWidget);
      expect(
        find.text('Choose the muscle you want to focus on.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('muscles_filter_option_chest')),
        findsOneWidget,
      );
    },
  );

  testWidgets('ExerciseListWidget - search bar is rounded without an outline', (
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
    );

    await tester.pumpWidget(
      _wrap(ExerciseListWidget(onExerciseSelected: (_) {})),
    );
    await tester.pumpAndSettle();

    final searchField = tester.widget<CupertinoSearchTextField>(
      find.byType(CupertinoSearchTextField),
    );
    final decoration = searchField.decoration as BoxDecoration;
    final borderRadius = decoration.borderRadius! as BorderRadius;
    final border = decoration.border as Border;

    expect(borderRadius.topLeft.x, 22);
    expect(border.top.color, Colors.transparent);
    expect(border.top.width, 0);
  });

  testWidgets(
    'ExerciseListWidget - result card shows image thumb and plain action icons',
    (tester) async {
      final exercise = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: const ['Press'],
        equipment: 'Barbell',
        image: jsonEncode(['assets/images/bench_press.png']),
        animation: '',
        isBodyWeightExercise: false,
      );

      ExerciseService.instance.setDependenciesForTesting(
        exerciseDao: _FakeExerciseDao([exercise]),
        muscleGroupDao: _FakeMuscleGroupDao([
          MuscleGroup.chest,
          MuscleGroup.triceps,
        ]),
        seedExercises: [exercise],
      );

      await tester.pumpWidget(
        _wrap(ExerciseListWidget(onExerciseSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('exercise_card_image_bench-press')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('exercise_card_image_bench-press')),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('exercise_card_chevron_bench-press')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Icon>(
              find.byKey(const Key('exercise_card_chevron_bench-press')),
            )
            .icon,
        CupertinoIcons.chevron_right,
      );

      await tester.pumpWidget(
        _wrap(
          ExerciseListWidget(
            onExerciseSelected: (_) {},
            selectedExercises: const [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final infoButton = tester.widget<IconButton>(
        find.byKey(const Key('exercise_card_info_bench-press')),
      );
      expect(infoButton.padding, EdgeInsets.zero);
      expect(infoButton.iconSize, isNull);
    },
  );

  testWidgets(
    'ExerciseListWidget - tapping the preview opens the fullscreen gallery',
    (tester) async {
      final exercise = Exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps],
        instructions: const ['Press'],
        equipment: 'Barbell',
        image: jsonEncode(['assets/images/bench_press.png']),
        animation: '',
        isBodyWeightExercise: false,
      );

      ExerciseService.instance.setDependenciesForTesting(
        exerciseDao: _FakeExerciseDao([exercise]),
        muscleGroupDao: _FakeMuscleGroupDao([
          MuscleGroup.chest,
          MuscleGroup.triceps,
        ]),
        seedExercises: [exercise],
      );

      var selectedExerciseCount = 0;

      await tester.pumpWidget(
        _wrap(
          ExerciseListWidget(
            onExerciseSelected: (_) {
              selectedExerciseCount += 1;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('exercise_card_image_bench-press')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseImageGalleryScreen), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      expect(selectedExerciseCount, 0);
    },
  );
}
