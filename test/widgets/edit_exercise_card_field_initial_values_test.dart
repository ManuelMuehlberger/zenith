import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/widgets/edit_exercise_card.dart';

void main() {
  Widget _wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  WorkoutExercise _exercise({
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

  WorkoutSet _set({
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
      _set(id: 's1', workoutExerciseId: exId, setIndex: 0, reps: 12, weight: 30.0),
      _set(id: 's2', workoutExerciseId: exId, setIndex: 1, reps: 10, weight: 32.5),
      _set(id: 's3', workoutExerciseId: exId, setIndex: 2, reps: 8,  weight: 35.0),
    ];
    final exercise = _exercise(id: exId, templateId: 'tpl', slug: 'bench-press', sets: sets);

    await tester.pumpWidget(_wrap(
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
      _set(id: 's1', workoutExerciseId: exId, setIndex: 0, reps: 5,  weight: 20.0),
      _set(id: 's2', workoutExerciseId: exId, setIndex: 1, reps: 5,  weight: 22.5),
      _set(id: 's3', workoutExerciseId: exId, setIndex: 2, reps: 5,  weight: 25.0),
    ];
    final exercise = _exercise(id: exId, templateId: 'tpl', slug: 'squat', sets: sets);

    await tester.pumpWidget(_wrap(
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
    final ex1 = _exercise(
      id: 'exA',
      templateId: 'tpl',
      slug: 'deadlift',
      sets: [
        _set(id: 'sA1', workoutExerciseId: 'exA', setIndex: 0, reps: 3, weight: 100.0),
        _set(id: 'sA2', workoutExerciseId: 'exA', setIndex: 1, reps: 3, weight: 110.0),
      ],
    );
    final ex2 = _exercise(
      id: 'exB',
      templateId: 'tpl',
      slug: 'pull-up',
      sets: [
        _set(id: 'sB1', workoutExerciseId: 'exB', setIndex: 0, reps: 10, weight: 0.0),
        _set(id: 'sB2', workoutExerciseId: 'exB', setIndex: 1, reps: 8,  weight: 0.0),
      ],
    );

    await tester.pumpWidget(_wrap(Column(
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
}
