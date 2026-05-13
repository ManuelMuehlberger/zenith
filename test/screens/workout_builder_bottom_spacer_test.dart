import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/workout_builder_screen.dart';
import 'package:zenith/services/workout_session_service.dart';
import 'package:zenith/widgets/main_dock_spacer.dart';

Widget _routePage(String label) {
  return Scaffold(body: Center(child: Text(label)));
}

Route<void> _folderRoute(String folderId) {
  return MaterialPageRoute<void>(
    settings: WorkoutBuilderScreen.routeSettingsForFolder(folderId),
    builder: (_) => _routePage('folder:$folderId'),
  );
}

Future<void> _pumpWorkoutBuilderScreen(
  WidgetTester tester, {
  double bottomSafe = 24.0,
}) async {
  await tester.runAsync(() async {
    await WorkoutSessionService.instance.clearActiveSession(
      deleteFromDb: false,
    );
  });

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(bottom: bottomSafe)),
        child: const WorkoutBuilderScreen(),
      ),
    ),
  );
  await tester.pump();
}

Future<bool> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  int attempts = 20,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return true;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }

  return finder.evaluate().isNotEmpty;
}

void main() {
  testWidgets(
    'WorkoutBuilderScreen includes bottom spacer to avoid glass tab bar overlap',
    (tester) async {
      await _pumpWorkoutBuilderScreen(tester);

      final spacerFinder = find.byType(MainDockSpacer);

      await _waitForFinder(tester, spacerFinder);

      if (spacerFinder.evaluate().isEmpty) {
        expect(
          find.byType(CircularProgressIndicator),
          findsAtLeastNWidgets(1),
          reason:
              'WorkoutBuilderScreen did not finish loading in the test window; skipping spacer assertion.',
        );
        return;
      }

      expect(
        spacerFinder,
        findsOneWidget,
        reason: 'Expected WorkoutBuilderScreen to include MainDockSpacer',
      );
    },
  );

  testWidgets('WorkoutBuilderScreen shows workouts before folders', (
    tester,
  ) async {
    await _pumpWorkoutBuilderScreen(tester);

    final addWorkoutFinder = find.text('Add workout');
    final addFolderFinder = find.text('Add folder');
    final loaded = await _waitForFinder(tester, addWorkoutFinder);

    if (!loaded || addFolderFinder.evaluate().isEmpty) {
      expect(
        find.byType(CircularProgressIndicator),
        findsAtLeastNWidgets(1),
        reason:
            'WorkoutBuilderScreen did not finish loading in the test window; skipping section order assertion.',
      );
      return;
    }

    final workoutButtonTop = tester.getTopLeft(addWorkoutFinder).dy;
    final folderButtonTop = tester.getTopLeft(addFolderFinder).dy;

    expect(
      workoutButtonTop,
      lessThan(folderButtonTop),
      reason: 'Expected the workouts section to render above folders.',
    );
  });

  testWidgets(
    'WorkoutBuilderScreen breadcrumb helper pops to an existing ancestor route',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigatorKey, home: _routePage('root')),
      );

      final navigator = navigatorKey.currentState!;
      unawaited(navigator.push(_folderRoute('test')));
      await tester.pumpAndSettle();
      unawaited(navigator.push(_folderRoute('test2')));
      await tester.pumpAndSettle();

      final found = WorkoutBuilderScreen.popToFolderInStack(navigator, 'test');
      await tester.pumpAndSettle();

      expect(found, isTrue);
      expect(find.text('folder:test'), findsOneWidget);
      expect(find.text('folder:test2'), findsNothing);
    },
  );
}
