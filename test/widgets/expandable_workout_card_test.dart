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
            onDeletePressed: () {},
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
            onDeletePressed: () {},
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


  testWidgets('ExpandableWorkoutCard (template) refreshes counts when template instance changes (same id)', (WidgetTester tester) async {
    // Arrange
    const templateId = 'template_update_1';
    WorkoutTemplate templateV1 = WorkoutTemplate(
      id: templateId,
      name: 'Template V1',
      iconCodePoint: 0xe1a3,
      colorValue: 0xFF2196F3,
    );

    // Two datasets to simulate "before edit" and "after edit"
    List<WorkoutExercise> dataSet = [
      WorkoutExercise(
        workoutTemplateId: templateId,
        exerciseSlug: 'push-up',
        sets: [
          WorkoutSet(workoutExerciseId: 'exA', setIndex: 0, targetReps: 10, targetWeight: 0.0),
          WorkoutSet(workoutExerciseId: 'exA', setIndex: 1, targetReps: 10, targetWeight: 0.0),
        ],
      ),
    ]; // 1 exercise, 2 sets

    Future<List<WorkoutExercise>> loader(String id) async {
      expect(id, templateId);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return dataSet;
    }

    // Pump initial
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: ExpandableWorkoutCard(
            template: templateV1,
            loadTemplateExercises: loader,
            index: 0,
            onEditPressed: () {},
            onDeletePressed: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text('2 sets'), findsOneWidget);

    // Simulate "edited" template: same id, new instance, different data
    dataSet = [
      WorkoutExercise(
        workoutTemplateId: templateId,
        exerciseSlug: 'push-up',
        sets: [
          WorkoutSet(workoutExerciseId: 'exA', setIndex: 0, targetReps: 12, targetWeight: 0.0),
          WorkoutSet(workoutExerciseId: 'exA', setIndex: 1, targetReps: 12, targetWeight: 0.0),
        ],
      ),
      WorkoutExercise(
        workoutTemplateId: templateId,
        exerciseSlug: 'pull-up',
        sets: [
          WorkoutSet(workoutExerciseId: 'exB', setIndex: 0, targetReps: 6, targetWeight: 0.0),
        ],
      ),
    ]; // 2 exercises, 3 sets

    final templateV2 = WorkoutTemplate(
      id: templateId, // same id
      name: 'Template V2',
      iconCodePoint: 0xe1a3,
      colorValue: 0xFF2196F3,
    );

    // Rebuild with new template instance
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: ExpandableWorkoutCard(
            template: templateV2,
            loadTemplateExercises: loader,
            index: 0,
            onEditPressed: () {},
            onDeletePressed: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Expect updated counts after didUpdateWidget-triggered reload
    expect(find.text('2 exercises'), findsOneWidget);
    expect(find.text('3 sets'), findsOneWidget);
  });

  testWidgets('ExpandableWorkoutCard switching from template to workout uses workout data (no stale template cache)', (WidgetTester tester) async {
    // Arrange template with some data
    const templateId = 'template_switch_1';
    final template = WorkoutTemplate(
      id: templateId,
      name: 'Switch Template',
      iconCodePoint: 0xe1a3,
      colorValue: 0xFF2196F3,
    );

    final templateData = [
      WorkoutExercise(
        workoutTemplateId: templateId,
        exerciseSlug: 'lunges',
        sets: [
          WorkoutSet(workoutExerciseId: 'exT', setIndex: 0, targetReps: 8, targetWeight: 0.0),
          WorkoutSet(workoutExerciseId: 'exT', setIndex: 1, targetReps: 8, targetWeight: 0.0),
        ],
      ),
    ]; // 1 exercise, 2 sets

    Future<List<WorkoutExercise>> loader(String id) async {
      expect(id, templateId);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return templateData;
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
            onDeletePressed: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text('2 sets'), findsOneWidget);

    // Now switch to a concrete workout with different counts
    const workoutId = 'workout_switch_1';
    final workoutExercise = WorkoutExercise(
      id: 'we_ws1',
      workoutId: workoutId,
      exerciseSlug: 'deadlift',
      sets: [
        WorkoutSet(workoutExerciseId: 'we_ws1', setIndex: 0, targetReps: 5, targetWeight: 120.0),
        WorkoutSet(workoutExerciseId: 'we_ws1', setIndex: 1, targetReps: 5, targetWeight: 120.0),
        WorkoutSet(workoutExerciseId: 'we_ws1', setIndex: 2, targetReps: 5, targetWeight: 120.0),
      ],
    );
    final workout = Workout(
      id: workoutId,
      name: 'WS Workout',
      exercises: [workoutExercise],
      status: WorkoutStatus.template,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: ExpandableWorkoutCard(
            workout: workout,
            index: 0,
            onEditPressed: () {},
            onDeletePressed: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Expect the workout's counts (1 exercise, 3 sets), not stale template data
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text('3 sets'), findsOneWidget);
    expect(find.text('WS Workout'), findsOneWidget);
  });
}
