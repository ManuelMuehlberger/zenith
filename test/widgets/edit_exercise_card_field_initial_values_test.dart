import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/widgets/edit_exercise_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  WorkoutExercise exercise0({
    required String id,
    required String templateId,
    required String slug,
    required List<WorkoutSet> sets,
    String? notes,
    int? orderIndex,
  }) {
    return WorkoutExercise(
      id: id,
      workoutTemplateId: templateId,
      exerciseSlug: slug,
      notes: notes,
      orderIndex: orderIndex,
      sets: sets,
    );
  }

  WorkoutSet set({
    required String id,
    required String workoutExerciseId,
    required int setIndex,
    int? reps,
    double? weight,
    int? rest,
  }) {
    return WorkoutSet(
      id: id,
      workoutExerciseId: workoutExerciseId,
      setIndex: setIndex,
      targetReps: reps,
      targetWeight: weight,
      targetRestSeconds: rest,
    );
  }

  testWidgets('renders targetReps for multiple sets without missing values', (tester) async {
    final exId = 'ex1';
    final sets = <WorkoutSet>[
      set(id: 's1', workoutExerciseId: exId, setIndex: 0, reps: 12, weight: 30.0),
      set(id: 's2', workoutExerciseId: exId, setIndex: 1, reps: 10, weight: 32.5),
      set(id: 's3', workoutExerciseId: exId, setIndex: 2, reps: 8,  weight: 35.0),
    ];
    final exercise = exercise0(id: exId, templateId: 'tpl', slug: 'bench-press', sets: sets);

    await tester.pumpWidget(wrap(
      EditExerciseCard(
        key: ValueKey(exercise.id),
        exercise: exercise,
        exerciseIndex: 0,
        isNotesExpanded: false,
        onToggleNotes: (_) {},
        onRemoveExercise: (_) {},
        onAddSet: (_) {},
        onRemoveSet: (_, __) {},
        onUpdateSet: (_, __, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {},
        onUpdateNotes: (_, __) {},
        onToggleRepRange: (_, __) {},
        weightUnit: 'kg',
      ),
    ));
    await tester.pumpAndSettle();

    // Verify reps fields show initial values via TextEditingController text
    for (int i = 0; i < sets.length; i++) {
      final s = sets[i];
      final expectedReps = s.targetReps?.toString() ?? '';
      
      // Find the TextFormField in the correct row (by set index)
      final textFields = find.byType(TextFormField);
      // Each set has 2 TextFormFields (reps and weight), so we find them by index
      final repsField = tester.widget<TextFormField>(textFields.at(i * 2));
      
      expect(repsField.controller!.text, expectedReps);
    }
  });

  testWidgets('renders targetWeight for multiple sets without missing values', (tester) async {
    final exId = 'ex2';
    final sets = <WorkoutSet>[
      set(id: 's1', workoutExerciseId: exId, setIndex: 0, reps: 5,  weight: 20.0),
      set(id: 's2', workoutExerciseId: exId, setIndex: 1, reps: 5,  weight: 22.5),
      set(id: 's3', workoutExerciseId: exId, setIndex: 2, reps: 5,  weight: 25.0),
    ];
    final exercise = exercise0(id: exId, templateId: 'tpl', slug: 'squat', sets: sets);

    await tester.pumpWidget(wrap(
      EditExerciseCard(
        key: ValueKey(exercise.id),
        exercise: exercise,
        exerciseIndex: 0,
        isNotesExpanded: false,
        onToggleNotes: (_) {},
        onRemoveExercise: (_) {},
        onAddSet: (_) {},
        onRemoveSet: (_, __) {},
        onUpdateSet: (_, __, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {},
        onUpdateNotes: (_, __) {},
        onToggleRepRange: (_, __) {},
        weightUnit: 'kg',
      ),
    ));
    await tester.pumpAndSettle();

    // Verify weight fields show initial values
    for (int i = 0; i < sets.length; i++) {
      final s = sets[i];
      final expectedWeight = s.targetWeight?.toString() ?? '';
      
      final textFields = find.byType(TextFormField);
      // Reps field is at (i * 2), weight field is at (i * 2) + 1
      final weightField = tester.widget<TextFormField>(textFields.at(i * 2 + 1));
      
      expect(weightField.controller!.text, expectedWeight);
    }
  });

  testWidgets('unique field keys prevent TextFormField state reuse across exercises', (tester) async {
    final ex1 = exercise0(
      id: 'exA',
      templateId: 'tpl',
      slug: 'deadlift',
      sets: [
        set(id: 'sA1', workoutExerciseId: 'exA', setIndex: 0, reps: 3, weight: 100.0),
        set(id: 'sA2', workoutExerciseId: 'exA', setIndex: 1, reps: 3, weight: 110.0),
      ],
    );
    final ex2 = exercise0(
      id: 'exB',
      templateId: 'tpl',
      slug: 'pull-up',
      sets: [
        set(id: 'sB1', workoutExerciseId: 'exB', setIndex: 0, reps: 10, weight: 0.0),
        set(id: 'sB2', workoutExerciseId: 'exB', setIndex: 1, reps: 8,  weight: 0.0),
      ],
    );

    await tester.pumpWidget(wrap(Column(
      children: [
        EditExerciseCard(
          key: ValueKey(ex1.id),
          exercise: ex1,
          exerciseIndex: 0,
          isNotesExpanded: false,
          onToggleNotes: (_) {},
          onRemoveExercise: (_) {},
          onAddSet: (_) {},
          onRemoveSet: (_, __) {},
          onUpdateSet: (_, __, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {},
          onUpdateNotes: (_, __) {},
          onToggleRepRange: (_, __) {},
          weightUnit: 'kg',
        ),
        EditExerciseCard(
          key: ValueKey(ex2.id),
          exercise: ex2,
          exerciseIndex: 1,
          isNotesExpanded: false,
          onToggleNotes: (_) {},
          onRemoveExercise: (_) {},
          onAddSet: (_) {},
          onRemoveSet: (_, __) {},
          onUpdateSet: (_, __, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {},
          onUpdateNotes: (_, __) {},
          onToggleRepRange: (_, __) {},
          weightUnit: 'kg',
        ),
      ],
    )));
    await tester.pumpAndSettle();

    // Check one key from each card to ensure no cross-reuse occurred
    final allTextFields = find.byType(TextFormField).evaluate().toList();

    // Exercise 1, Set 1 Reps (index 0)
    final repsAController = (allTextFields[0].widget as TextFormField).controller;
    expect(repsAController!.text, '3');

    // Exercise 2, Set 2 Reps (index 6)
    final repsBController = (allTextFields[6].widget as TextFormField).controller;
    expect(repsBController!.text, '8');
  });

  testWidgets('tapping reps field selects all text', (tester) async {
    final exId = 'ex1';
    final sets = [set(id: 's1', workoutExerciseId: exId, setIndex: 0, reps: 12, weight: 30.0)];
    final exercise = exercise0(id: exId, templateId: 'tpl', slug: 'bench-press', sets: sets);

    await tester.pumpWidget(wrap(
      EditExerciseCard(
        exercise: exercise,
        exerciseIndex: 0,
        isNotesExpanded: false,
        onToggleNotes: (_) {},
        onRemoveExercise: (_) {},
        onAddSet: (_) {},
        onRemoveSet: (_, __) {},
        onUpdateSet: (_, __, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {},
        onUpdateNotes: (_, __) {},
        onToggleRepRange: (_, __) {},
        weightUnit: 'kg',
      ),
    ));
    await tester.pumpAndSettle();

    final repsFieldFinder = find.byWidgetPredicate((widget) =>
        widget is TextFormField && widget.controller?.text == '12');
    expect(repsFieldFinder, findsOneWidget);

    final repsField = tester.widget<TextFormField>(repsFieldFinder);
    await tester.tap(repsFieldFinder);
    await tester.pump();

    expect(repsField.controller!.selection.baseOffset, 0);
    expect(repsField.controller!.selection.extentOffset, 2);
  });

  testWidgets('tapping weight field selects all text', (tester) async {
    final exId = 'ex1';
    final sets = [set(id: 's1', workoutExerciseId: exId, setIndex: 0, reps: 12, weight: 30.5)];
    final exercise = exercise0(id: exId, templateId: 'tpl', slug: 'bench-press', sets: sets);

    await tester.pumpWidget(wrap(
      EditExerciseCard(
        exercise: exercise,
        exerciseIndex: 0,
        isNotesExpanded: false,
        onToggleNotes: (_) {},
        onRemoveExercise: (_) {},
        onAddSet: (_) {},
        onRemoveSet: (_, __) {},
        onUpdateSet: (_, __, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {},
        onUpdateNotes: (_, __) {},
        onToggleRepRange: (_, __) {},
        weightUnit: 'kg',
      ),
    ));
    await tester.pumpAndSettle();

    final weightFieldFinder = find.byWidgetPredicate((widget) =>
        widget is TextFormField && widget.controller?.text == '30.5');
    expect(weightFieldFinder, findsOneWidget);

    final weightField = tester.widget<TextFormField>(weightFieldFinder);
    await tester.tap(weightFieldFinder);
    await tester.pump();

    expect(weightField.controller!.selection.baseOffset, 0);
    expect(weightField.controller!.selection.extentOffset, 4);
  });

  testWidgets('weight field allows multi-digit numbers and up to two decimal places', (tester) async {
    final exId = 'ex1';
    final sets = [set(id: 's1', workoutExerciseId: exId, setIndex: 0, reps: 12, weight: 0)];
    final exercise = exercise0(id: exId, templateId: 'tpl', slug: 'bench-press', sets: sets);

    await tester.pumpWidget(wrap(
      EditExerciseCard(
        exercise: exercise,
        exerciseIndex: 0,
        isNotesExpanded: false,
        onToggleNotes: (_) {},
        onRemoveExercise: (_) {},
        onAddSet: (_) {},
        onRemoveSet: (_, __) {},
        onUpdateSet: (_, __, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {},
        onUpdateNotes: (_, __) {},
        onToggleRepRange: (_, __) {},
        weightUnit: 'kg',
      ),
    ));
    await tester.pumpAndSettle();

    // Find field by position, not by text, as text will change
    final weightFieldFinder = find.byType(TextFormField).at(1);

    // Check initial value
    var weightField = tester.widget<TextFormField>(weightFieldFinder);
    expect(weightField.controller!.text, '0.0');

    // Enter a valid value
    await tester.enterText(weightFieldFinder, '123.45');
    await tester.pump();

    // Check the updated value
    weightField = tester.widget<TextFormField>(weightFieldFinder);
    expect(weightField.controller!.text, '123.45');

    // Enter an invalid value (too many decimal places)
    await tester.enterText(weightFieldFinder, '123.456');
    await tester.pump();

    // Check that the value was truncated by the formatter
    weightField = tester.widget<TextFormField>(weightFieldFinder);
    expect(weightField.controller!.text, '123.45');
  });

  testWidgets('typing weight from empty: 1 -> 10 -> 100 does not auto-format mid-typing', (tester) async {
    final exId = 'ex3';
    final sets = [set(id: 's1', workoutExerciseId: exId, setIndex: 0, reps: 8, weight: null)];
    final exercise = exercise0(id: exId, templateId: 'tpl', slug: 'ohp', sets: sets);

    await tester.pumpWidget(wrap(
      EditExerciseCard(
        exercise: exercise,
        exerciseIndex: 0,
        isNotesExpanded: false,
        onToggleNotes: (_) {},
        onRemoveExercise: (_) {},
        onAddSet: (_) {},
        onRemoveSet: (_, __) {},
        onUpdateSet: (_, __, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {},
        onUpdateNotes: (_, __) {},
        onToggleRepRange: (_, __) {},
        weightUnit: 'kg',
      ),
    ));
    await tester.pumpAndSettle();

    final weightFieldFinder = find.byType(TextFormField).at(1);

    await tester.enterText(weightFieldFinder, '1');
    await tester.pump();
    var field = tester.widget<TextFormField>(weightFieldFinder);
    expect(field.controller!.text, '1');

    await tester.enterText(weightFieldFinder, '10');
    await tester.pump();
    field = tester.widget<TextFormField>(weightFieldFinder);
    expect(field.controller!.text, '10');

    await tester.enterText(weightFieldFinder, '100');
    await tester.pump();
    field = tester.widget<TextFormField>(weightFieldFinder);
    expect(field.controller!.text, '100');
  });

  testWidgets('select-all then delete weight keeps empty after blur', (tester) async {
    final exId = 'ex4';
    final sets = [set(id: 's1', workoutExerciseId: exId, setIndex: 0, reps: 8, weight: 1.0)];
    final exercise = exercise0(id: exId, templateId: 'tpl', slug: 'row', sets: sets);

    await tester.pumpWidget(wrap(
      EditExerciseCard(
        exercise: exercise,
        exerciseIndex: 0,
        isNotesExpanded: false,
        onToggleNotes: (_) {},
        onRemoveExercise: (_) {},
        onAddSet: (_) {},
        onRemoveSet: (_, __) {},
        onUpdateSet: (_, __, {int? targetReps, double? targetWeight, String? type, int? targetRestSeconds}) {},
        onUpdateNotes: (_, __) {},
        onToggleRepRange: (_, __) {},
        weightUnit: 'kg',
      ),
    ));
    await tester.pumpAndSettle();

    final repsFieldFinder = find.byType(TextFormField).at(0);
    final weightFieldFinder = find.byType(TextFormField).at(1);

    // Ensure initial
    var weightField = tester.widget<TextFormField>(weightFieldFinder);
    expect(weightField.controller!.text, '1.0');

    // Tap to select all (handled by onTap), then clear
    await tester.tap(weightFieldFinder);
    await tester.pump();
    await tester.enterText(weightFieldFinder, '');
    await tester.pump();

    weightField = tester.widget<TextFormField>(weightFieldFinder);
    expect(weightField.controller!.text, '');

    // Blur by focusing reps field
    await tester.tap(repsFieldFinder);
    await tester.pump();

    // Still empty after blur
    weightField = tester.widget<TextFormField>(weightFieldFinder);
    expect(weightField.controller!.text, '');
  });
}
