import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_folder.dart';
import 'package:zenith/models/workout_template.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/reorderable_folder_list.dart';
import 'package:zenith/widgets/reorderable_workout_template_list.dart';
import 'package:zenith/widgets/workout_builder_drag_payload.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  testWidgets('ReorderableFolderList emits typed folder drag payload', (
    tester,
  ) async {
    WorkoutBuilderDragPayload? startedPayload;

    await tester.pumpWidget(
      buildTestApp(
        ReorderableFolderList(
          folders: [
            WorkoutFolder(id: 'folder-a', name: 'Folder A', orderIndex: 0),
            WorkoutFolder(id: 'folder-b', name: 'Folder B', orderIndex: 1),
          ],
          currentParentFolderId: null,
          itemCountByFolder: const {'folder-a': 1, 'folder-b': 2},
          subfolderCountByFolder: const {'folder-a': 0, 'folder-b': 1},
          activeDragPayload: null,
          onFolderTap: (_) {},
          onRenamePressed: (_) {},
          onDeletePressed: (_) {},
          onFolderReordered: (_, __) {},
          onPayloadDroppedIntoFolder: (_, __) {},
          canDropIntoFolder: (_, __) => true,
          onDragStarted: (payload) => startedPayload = payload,
          onDragEnded: () {},
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Folder A')),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(startedPayload, isA<FolderDragPayload>());
    expect((startedPayload as FolderDragPayload).folderId, 'folder-a');

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'ReorderableWorkoutTemplateList emits typed template drag payload',
    (tester) async {
      WorkoutBuilderDragPayload? startedPayload;

      await tester.pumpWidget(
        buildTestApp(
          ReorderableWorkoutTemplateList(
            templates: [
              WorkoutTemplate(
                id: 'template-a',
                name: 'Workout A',
                orderIndex: 0,
              ),
              WorkoutTemplate(
                id: 'template-b',
                name: 'Workout B',
                orderIndex: 1,
              ),
            ],
            folderId: null,
            onTemplateTap: (_) {},
            onTemplateDeletePressed: (_) {},
            onTemplateReordered: (_, __) {},
            onAddWorkoutPressed: null,
            onDragStarted: (payload) => startedPayload = payload,
            onDragEnded: () {},
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Workout A')),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(startedPayload, isA<TemplateDragPayload>());
      expect((startedPayload as TemplateDragPayload).templateId, 'template-a');

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
}
