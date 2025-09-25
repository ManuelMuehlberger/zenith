import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/screens/create_workout_screen.dart';

void main() {
  testWidgets('CreateWorkoutScreen - adding a set copies previous set values (direct model update)', (WidgetTester tester) async {
    // Build the screen directly
    await tester.pumpWidget(const MaterialApp(
      home: CreateWorkoutScreen(),
    ));
    await tester.pumpAndSettle();

    // At this point, the exercise picker would be open. We'll simulate the
    // result of picking an exercise by manually adding it to the state.
    final state = tester.state<State<CreateWorkoutScreen>>(find.byType(CreateWorkoutScreen));
    
    // Manually add an exercise
    (state as dynamic).addExerciseForTest(
      Exercise(
        slug: 'crunches',
        name: 'Crunches',
        primaryMuscleGroup: MuscleGroup.abs,
        secondaryMuscleGroups: [],
        instructions: [],
        image: '',
        animation: '',
      ),
    );
    await tester.pumpAndSettle();

    // Find all TextFormField widgets
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2)); // Should have reps and weight fields

    // Get the TextFormField widgets
    final repsField = textFields.at(0);
    final weightField = textFields.at(1);

    // Verify initial values by checking the controller text
    final repsWidget = tester.widget<TextFormField>(repsField);
    final weightWidget = tester.widget<TextFormField>(weightField);
    
    expect(repsWidget.controller?.text, '10');
    expect(weightWidget.controller?.text, '0.0');

    // Update the model directly to simulate what happens when user types
    (state as dynamic).updateSetForTest(0, 0, targetReps: 15, targetWeight: 25.5);
    await tester.pumpAndSettle();

    // Verify the UI was updated to reflect the model changes
    final updatedTextFields = find.byType(TextFormField);
    final updatedRepsWidget = tester.widget<TextFormField>(updatedTextFields.at(0));
    final updatedWeightWidget = tester.widget<TextFormField>(updatedTextFields.at(1));
    expect(updatedRepsWidget.controller?.text, '15');
    expect(updatedWeightWidget.controller?.text, '25.5');

    // Add a new set
    await tester.tap(find.text('Add Set'));
    await tester.pumpAndSettle();

    // Now we should have 4 TextFormField widgets (2 sets × 2 fields each)
    final allTextFields = find.byType(TextFormField);
    expect(allTextFields, findsNWidgets(4));

    // Check that the new set (3rd and 4th fields) have the copied values
    final newRepsField = allTextFields.at(2);
    final newWeightField = allTextFields.at(3);
    
    final newRepsWidget = tester.widget<TextFormField>(newRepsField);
    final newWeightWidget = tester.widget<TextFormField>(newWeightField);
    
    // This is the key test - the new set should have the values from the previous set
    expect(newRepsWidget.controller?.text, '15');
    expect(newWeightWidget.controller?.text, '25.5');
  });
}
