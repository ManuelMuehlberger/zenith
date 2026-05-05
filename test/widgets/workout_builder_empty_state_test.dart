import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/widgets/workout_builder_empty_state.dart';

void main() {
  testWidgets('WorkoutBuilderEmptyState shows centered icon and title', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkoutBuilderEmptyState(
            icon: Icons.folder_open_rounded,
            title: 'No folders yet',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.folder_open_rounded), findsOneWidget);
    expect(find.text('No folders yet'), findsOneWidget);
  });
}