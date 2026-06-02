import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/workout_builder_screen.dart';

void main() {
  group('WorkoutBuilderScreen route helpers', () {
    test('routeNameForFolder distinguishes root and nested folders', () {
      expect(
        WorkoutBuilderScreen.routeNameForFolder(null),
        'workout-builder/root',
      );
      expect(
        WorkoutBuilderScreen.routeNameForFolder('folder-1'),
        'workout-builder/folder/folder-1',
      );
    });

    test('routeSettingsForFolder stores the folder id as an argument', () {
      final settings = WorkoutBuilderScreen.routeSettingsForFolder('folder-2');

      expect(settings.name, 'workout-builder/folder/folder-2');
      expect(settings.arguments, 'folder-2');
    });

    testWidgets(
      'popToFolderInStack returns false when the folder route is absent',
      (tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('root')),
          ),
        );

        final found = WorkoutBuilderScreen.popToFolderInStack(
          navigatorKey.currentState!,
          'missing-folder',
        );

        expect(found, isFalse);
      },
    );

    testWidgets(
      'popToFolderInStack returns to the first route for the root folder',
      (tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('root')),
          ),
        );

        unawaited(
          navigatorKey.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('detail')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final found = WorkoutBuilderScreen.popToFolderInStack(
          navigatorKey.currentState!,
          null,
        );

        expect(found, isTrue);
        await tester.pumpAndSettle();
        expect(find.text('root'), findsOneWidget);
      },
    );
  });
}
