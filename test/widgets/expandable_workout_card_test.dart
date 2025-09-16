import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_template.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/widgets/expandable_workout_card.dart';

void main() {
  testWidgets('ExpandableWorkoutCard shows exercise slug when exerciseDetail is null', (WidgetTester tester) async {
    // Arrange: build a Workout with one WorkoutExercise lacking exerciseDetail
    const workoutId = 'workout_test_1';
    const workoutExerciseId = 'we_test_1';

    final workoutExercise = WorkoutExercise(
      id: workoutExerciseId,
      workoutId: workoutId, // satisfy assertion: exactly one of workoutId or workoutTemplateId must be set
      exerciseSlug: 'bench-press',
      // exerciseDetail is intentionally null to simulate DB-loaded data without in-memory detail
      sets: [
        WorkoutSet(
          workoutExerciseId: workoutExerciseId,
          setIndex: 0,
          targetReps: 10,
          targetWeight: 50.0,
        ),
      ],
    );

    final workout = Workout(
      id: workoutId,
      name: 'Sample Workout',
      exercises: [workoutExercise],
      status: WorkoutStatus.template,
    );

    // Act: pump the widget and expand the card
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: ExpandableWorkoutCard(
            workout: workout,
            index: 0,
            onEditPressed: () {},
            onMorePressed: () {},
          ),
        ),
      ),
    );

    // Initially collapsed; tap to expand
    // Tap on the InkWell area by tapping on the workout name text
    await tester.tap(find.text('Sample Workout'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400)); // allow animation to complete

    // Assert: the exercise slug is displayed when exerciseDetail is null
    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('bench-press'), findsOneWidget);

    // Also verify the sets count text renders as expected (may appear in summary and per-exercise)
    expect(find.text('1 set'), findsWidgets);
  });

  testWidgets('ExpandableWorkoutCard (template) loads exercises via injected loader and shows slug/counts', (WidgetTester tester) async {
    // Arrange: a template with lazy-loaded exercises
    const templateId = 'template_test_1';
    final template = WorkoutTemplate(
      id: templateId,
      name: 'Template Workout',
      description: 'Desc',
      iconCodePoint: 0xe1a3, // fitness_center
      colorValue: 0xFF2196F3,
    );

    final workoutExercise = WorkoutExercise(
      workoutTemplateId: templateId, // satisfy assertion
      exerciseSlug: 'squat',
      sets: [
        WorkoutSet(
          workoutExerciseId: 'ex1',
          setIndex: 0,
          targetReps: 5,
          targetWeight: 100.0,
        ),
        WorkoutSet(
          workoutExerciseId: 'ex1',
          setIndex: 1,
          targetReps: 5,
          targetWeight: 100.0,
        ),
      ],
    );

    // Loader that simulates DB fetch
    Future<List<WorkoutExercise>> loader(String id) async {
      expect(id, templateId);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return [workoutExercise];
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: ExpandableWorkoutCard(
            template: template,
            loadTemplateExercises: loader,
            index: 0,
            onEditPressed: () {},
            onMorePressed: () {},
          ),
        ),
      ),
    );

    // Let initState-triggered loader run
    await tester.pumpAndSettle();

    // Summary chips should reflect 1 exercise, 2 sets
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text('2 sets'), findsOneWidget);

    // Expand to see list
    await tester.tap(find.text('Template Workout'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('squat'), findsOneWidget);
    expect(find.text('2 sets'), findsWidgets);
  });

  testWidgets('ExpandableWorkoutCard (template) exposes template drag payload', (WidgetTester tester) async {
    const templateId = 'template_drag_1';
    final template = WorkoutTemplate(
      id: templateId,
      name: 'Drag Template',
      iconCodePoint: 0xe1a3,
      colorValue: 0xFF2196F3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: ExpandableWorkoutCard(
            template: template,
            index: 3,
            onEditPressed: () {},
            onMorePressed: () {},
            loadTemplateExercises: (id) async => const [],
          ),
        ),
      ),
    );

    // Access the underlying draggable to inspect its data payload
    final draggableFinder = find.byType(LongPressDraggable<Map<String, dynamic>>);
    expect(draggableFinder, findsOneWidget);

    final draggable = tester.widget<LongPressDraggable<Map<String, dynamic>>>(draggableFinder);
    final data = draggable.data!;
    expect(data['type'], 'template');
    expect(data['templateId'], templateId);
    expect(data['index'], 3);
  });
}
