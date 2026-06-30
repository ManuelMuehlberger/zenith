import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/widgets/active_workout_app_bar.dart';

void main() {
  testWidgets('renders workout header without backdrop blur', (tester) async {
    final workout = Workout(
      id: 'session-1',
      name: 'Push Day',
      status: WorkoutStatus.inProgress,
      startedAt: DateTime(2026, 6, 30, 12),
      exercises: [
        WorkoutExercise(
          workoutId: 'session-1',
          exerciseSlug: 'bench-press',
          sets: [
            WorkoutSet(
              workoutExerciseId: 'exercise-1',
              setIndex: 0,
              actualReps: 8,
              actualWeight: 80,
              isCompleted: true,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: ActiveWorkoutAppBar(
            session: workout,
            isReorderMode: false,
            weightUnit: 'kg',
            onReorderToggle: () {},
            onFinishWorkout: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
