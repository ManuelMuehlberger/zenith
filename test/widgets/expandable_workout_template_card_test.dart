import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_template.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/expandable_workout_template_card.dart';

void main() {
  testWidgets('ExpandableWorkoutTemplateCard falls back to the default icon', (
    WidgetTester tester,
  ) async {
    final template = WorkoutTemplate(
      name: 'Leg Day',
      description: 'Template for the biggest lifts',
      iconCodePoint: null,
      colorValue: 0xFF2196F3,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ExpandableWorkoutTemplateCard(
            template: template,
            index: 0,
            onEditPressed: () {},
            onMorePressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
  });
}
