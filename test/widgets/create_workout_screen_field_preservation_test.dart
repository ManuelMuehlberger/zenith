import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/screens/create_workout_screen.dart';

void main() {
  group('CreateWorkoutScreen - Field Preservation Tests', () {
    testWidgets('entering reps does not clear weight field', (WidgetTester tester) async {
      // Build the screen directly
      await tester.pumpWidget(const MaterialApp(
        home: CreateWorkoutScreen(),
      ));
      await tester.pumpAndSettle();

      // Add an exercise for testing
      final state = tester.state<State<CreateWorkoutScreen>>(find.byType(CreateWorkoutScreen));
      (state as dynamic).addExerciseForTest(
        Exercise(
          slug: 'push-ups',
          name: 'Push-ups',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [],
          instructions: [],
          image: '',
          animation: '',
        ),
      );
      await tester.pumpAndSettle();

      // Find the text fields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2)); // Should have reps and weight fields

      final repsField = textFields.at(0);
      final weightField = textFields.at(1);

      // Set initial values using the test helper
      (state as dynamic).updateSetForTest(0, 0, targetReps: 12, targetWeight: 15.5);
      await tester.pumpAndSettle();

      // Verify both fields have the expected values
      var repsWidget = tester.widget<TextFormField>(repsField);
      var weightWidget = tester.widget<TextFormField>(weightField);
      expect(repsWidget.controller?.text, '12');
      expect(weightWidget.controller?.text, '15.5');

      // Update only the reps field
      (state as dynamic).updateSetForTest(0, 0, targetReps: 20);
      await tester.pumpAndSettle();

      // Verify reps changed but weight was preserved
      repsWidget = tester.widget<TextFormField>(repsField);
      weightWidget = tester.widget<TextFormField>(weightField);
      expect(repsWidget.controller?.text, '20');
      expect(weightWidget.controller?.text, '15.5'); // Should be preserved
    });

    testWidgets('entering weight does not clear reps field', (WidgetTester tester) async {
      // Build the screen directly
      await tester.pumpWidget(const MaterialApp(
        home: CreateWorkoutScreen(),
      ));
      await tester.pumpAndSettle();

      // Add an exercise for testing
      final state = tester.state<State<CreateWorkoutScreen>>(find.byType(CreateWorkoutScreen));
      (state as dynamic).addExerciseForTest(
        Exercise(
          slug: 'squats',
          name: 'Squats',
          primaryMuscleGroup: MuscleGroup.legs,
          secondaryMuscleGroups: [],
          instructions: [],
          image: '',
          animation: '',
        ),
      );
      await tester.pumpAndSettle();

      // Find the text fields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2)); // Should have reps and weight fields

      final repsField = textFields.at(0);
      final weightField = textFields.at(1);

      // Set initial values using the test helper
      (state as dynamic).updateSetForTest(0, 0, targetReps: 8, targetWeight: 50.0);
      await tester.pumpAndSettle();

      // Verify both fields have the expected values
      var repsWidget = tester.widget<TextFormField>(repsField);
      var weightWidget = tester.widget<TextFormField>(weightField);
      expect(repsWidget.controller?.text, '8');
      expect(weightWidget.controller?.text, '50.0');

      // Update only the weight field
      (state as dynamic).updateSetForTest(0, 0, targetWeight: 75.5);
      await tester.pumpAndSettle();

      // Verify weight changed but reps was preserved
      repsWidget = tester.widget<TextFormField>(repsField);
      weightWidget = tester.widget<TextFormField>(weightField);
      expect(repsWidget.controller?.text, '8'); // Should be preserved
      expect(weightWidget.controller?.text, '75.5');
    });

    testWidgets('updating both fields simultaneously works correctly', (WidgetTester tester) async {
      // Build the screen directly
      await tester.pumpWidget(const MaterialApp(
        home: CreateWorkoutScreen(),
      ));
      await tester.pumpAndSettle();

      // Add an exercise for testing
      final state = tester.state<State<CreateWorkoutScreen>>(find.byType(CreateWorkoutScreen));
      (state as dynamic).addExerciseForTest(
        Exercise(
          slug: 'deadlifts',
          name: 'Deadlifts',
          primaryMuscleGroup: MuscleGroup.back,
          secondaryMuscleGroups: [],
          instructions: [],
          image: '',
          animation: '',
        ),
      );
      await tester.pumpAndSettle();

      // Find the text fields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2)); // Should have reps and weight fields

      final repsField = textFields.at(0);
      final weightField = textFields.at(1);

      // Set initial values
      (state as dynamic).updateSetForTest(0, 0, targetReps: 5, targetWeight: 100.0);
      await tester.pumpAndSettle();

      // Verify initial values
      var repsWidget = tester.widget<TextFormField>(repsField);
      var weightWidget = tester.widget<TextFormField>(weightField);
      expect(repsWidget.controller?.text, '5');
      expect(weightWidget.controller?.text, '100.0');

      // Update both fields simultaneously
      (state as dynamic).updateSetForTest(0, 0, targetReps: 3, targetWeight: 120.0);
      await tester.pumpAndSettle();

      // Verify both fields were updated
      repsWidget = tester.widget<TextFormField>(repsField);
      weightWidget = tester.widget<TextFormField>(weightField);
      expect(repsWidget.controller?.text, '3');
      expect(weightWidget.controller?.text, '120.0');
    });

    testWidgets('multiple sets preserve values independently', (WidgetTester tester) async {
      // Build the screen directly
      await tester.pumpWidget(const MaterialApp(
        home: CreateWorkoutScreen(),
      ));
      await tester.pumpAndSettle();

      // Add an exercise for testing
      final state = tester.state<State<CreateWorkoutScreen>>(find.byType(CreateWorkoutScreen));
      (state as dynamic).addExerciseForTest(
        Exercise(
          slug: 'bench-press',
          name: 'Bench Press',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [],
          instructions: [],
          image: '',
          animation: '',
        ),
      );
      await tester.pumpAndSettle();

      // Set values for the first set
      (state as dynamic).updateSetForTest(0, 0, targetReps: 10, targetWeight: 80.0);
      await tester.pumpAndSettle();

      // Add a second set
      await tester.tap(find.text('Add Set'));
      await tester.pumpAndSettle();

      // Now we should have 4 TextFormField widgets (2 sets × 2 fields each)
      final allTextFields = find.byType(TextFormField);
      expect(allTextFields, findsNWidgets(4));

      // Set different values for the second set
      (state as dynamic).updateSetForTest(0, 1, targetReps: 8, targetWeight: 85.0);
      await tester.pumpAndSettle();

      // Update only reps for the first set
      (state as dynamic).updateSetForTest(0, 0, targetReps: 12);
      await tester.pumpAndSettle();

      // Verify first set: reps changed, weight preserved
      final firstRepsWidget = tester.widget<TextFormField>(allTextFields.at(0));
      final firstWeightWidget = tester.widget<TextFormField>(allTextFields.at(1));
      expect(firstRepsWidget.controller?.text, '12');
      expect(firstWeightWidget.controller?.text, '80.0'); // Should be preserved

      // Verify second set: values unchanged
      final secondRepsWidget = tester.widget<TextFormField>(allTextFields.at(2));
      final secondWeightWidget = tester.widget<TextFormField>(allTextFields.at(3));
      expect(secondRepsWidget.controller?.text, '8');
      expect(secondWeightWidget.controller?.text, '85.0');
    });

    testWidgets('null values are handled correctly', (WidgetTester tester) async {
      // Build the screen directly
      await tester.pumpWidget(const MaterialApp(
        home: CreateWorkoutScreen(),
      ));
      await tester.pumpAndSettle();

      // Add an exercise for testing
      final state = tester.state<State<CreateWorkoutScreen>>(find.byType(CreateWorkoutScreen));
      (state as dynamic).addExerciseForTest(
        Exercise(
          slug: 'pull-ups',
          name: 'Pull-ups',
          primaryMuscleGroup: MuscleGroup.back,
          secondaryMuscleGroups: [],
          instructions: [],
          image: '',
          animation: '',
        ),
      );
      await tester.pumpAndSettle();

      // Find the text fields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      final repsField = textFields.at(0);
      final weightField = textFields.at(1);

      // Verify initial default values
      var repsWidget = tester.widget<TextFormField>(repsField);
      var weightWidget = tester.widget<TextFormField>(weightField);
      expect(repsWidget.controller?.text, '10'); // Default from addExerciseForTest
      expect(weightWidget.controller?.text, '0.0'); // Default from addExerciseForTest

      // Update with null values (should preserve existing)
      (state as dynamic).updateSetForTest(0, 0, targetReps: null, targetWeight: null);
      await tester.pumpAndSettle();

      // Values should remain the same since nulls should preserve existing values
      repsWidget = tester.widget<TextFormField>(repsField);
      weightWidget = tester.widget<TextFormField>(weightField);
      expect(repsWidget.controller?.text, '10');
      expect(repsWidget.controller?.text, '10');
    });
  });
}
