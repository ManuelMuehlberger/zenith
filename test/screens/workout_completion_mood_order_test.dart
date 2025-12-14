import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/screens/workout_completion_screen.dart';

void main() {
  testWidgets('Mood order is Happy (left) to Sad (right)', (WidgetTester tester) async {
    final start = DateTime(2025, 1, 1, 12, 0, 0);
    final session = Workout(
      name: 'Mood Order Test',
      status: WorkoutStatus.inProgress,
      startedAt: start,
      completedAt: start.add(const Duration(minutes: 10)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutCompletionScreen(session: session),
      ),
    );

    // Ensure the mood row is visible
    await tester.ensureVisible(find.text('How are you feeling?'));
    await tester.pumpAndSettle();

    // Verify all mood tiles exist by key
    final mood5 = find.byKey(const Key('mood_5')); // Very Happy 😄
    final mood4 = find.byKey(const Key('mood_4')); // Happy 😊
    final mood3 = find.byKey(const Key('mood_3')); // Neutral 😐
    final mood2 = find.byKey(const Key('mood_2')); // Sad 😔
    final mood1 = find.byKey(const Key('mood_1')); // Very Sad 😢

    expect(mood5, findsOneWidget);
    expect(mood4, findsOneWidget);
    expect(mood3, findsOneWidget);
    expect(mood2, findsOneWidget);
    expect(mood1, findsOneWidget);

    // Verify left-to-right x positions increase from happy -> sad
    final dx5 = tester.getTopLeft(mood5).dx;
    final dx4 = tester.getTopLeft(mood4).dx;
    final dx3 = tester.getTopLeft(mood3).dx;
    final dx2 = tester.getTopLeft(mood2).dx;
    final dx1 = tester.getTopLeft(mood1).dx;

    expect(dx5 < dx4, isTrue, reason: 'mood_5 should be to the left of mood_4');
    expect(dx4 < dx3, isTrue, reason: 'mood_4 should be to the left of mood_3');
    expect(dx3 < dx2, isTrue, reason: 'mood_3 should be to the left of mood_2');
    expect(dx2 < dx1, isTrue, reason: 'mood_2 should be to the left of mood_1');
  });
}
