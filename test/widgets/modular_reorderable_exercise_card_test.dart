import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/modular_reorderable_exercise_card.dart';

void main() {
  testWidgets(
    'ModularReorderableExerciseCard renders exercise details and empty state',
    (WidgetTester tester) async {
      final exercise = WorkoutExercise(
        workoutTemplateId: 'template-1',
        exerciseSlug: 'bench-press',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ModularReorderableExerciseCard(
              exercise: exercise,
              itemIndex: 0,
              onAddSet: (_) {},
              onRemoveSet: (exerciseId, setId) {},
              weightUnit: 'kg',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('bench-press'), findsOneWidget);
      expect(find.text('N/A'), findsOneWidget);
      expect(find.text('No sets added yet.'), findsOneWidget);
      expect(find.text('Add Set'), findsOneWidget);
    },
  );
}
