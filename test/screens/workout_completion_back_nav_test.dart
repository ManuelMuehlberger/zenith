import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/screens/workout_completion_screen.dart';

class _LauncherPage extends StatelessWidget {
  const _LauncherPage({required this.session});
  final Workout session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Active placeholder', key: const Key('active_placeholder'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WorkoutCompletionScreen(session: session)),
          );
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}

void main() {
  testWidgets('Back to Workout returns to previous screen (no black page)', (WidgetTester tester) async {
    final session = Workout(
      name: 'Test Workout',
      status: WorkoutStatus.inProgress,
      startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      exercises: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: _LauncherPage(session: session),
      ),
    );

    // Ensure initial page is visible
    expect(find.byKey(const Key('active_placeholder')), findsOneWidget);

    // Navigate to completion screen
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // We should now be on the completion screen
    expect(find.text('Complete Workout'), findsOneWidget);

    // Tap Back to Workout (ensure visible first due to scrollable content)
    await tester.ensureVisible(find.byKey(const Key('back_to_workout_btn')));
    await tester.tap(find.byKey(const Key('back_to_workout_btn')));
    await tester.pumpAndSettle();

    // We should be back on the previous page (not a black page)
    expect(find.byKey(const Key('active_placeholder')), findsOneWidget);
  });
}
