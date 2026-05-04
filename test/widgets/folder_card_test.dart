import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_folder.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/folder_card.dart';
import 'package:zenith/widgets/workout_builder_drag_payload.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  testWidgets('FolderCard shows workout drop hint for template payload', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        FolderCard(
          folder: WorkoutFolder(id: 'folder-1', name: 'Push Workouts'),
          itemCount: 3,
          activeDragPayload: const TemplateDragPayload(
            templateId: 'template-1',
            index: 0,
            parentFolderId: null,
          ),
          canAcceptPayload: (_) => true,
          onPayloadDropped: (_) {},
          onTap: () {},
          onRenamePressed: () {},
          onDeletePressed: () {},
        ),
      ),
    );

    expect(find.text('Folder'), findsOneWidget);
    expect(find.text('Push Workouts'), findsOneWidget);
    expect(find.text('Release to move workout'), findsOneWidget);
  });

  testWidgets('FolderCard shows symbolic workout and subfolder counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        FolderCard(
          folder: WorkoutFolder(id: 'folder-3', name: 'Mixed Folder'),
          itemCount: 4,
          subfolderCount: 2,
          onPayloadDropped: (_) {},
          onTap: () {},
          onRenamePressed: () {},
          onDeletePressed: () {},
        ),
      ),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('workout'), findsNothing);
  });

  testWidgets('FolderCard shows folder nesting hint for folder payload', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        FolderCard(
          folder: WorkoutFolder(id: 'folder-2', name: 'Upper Body'),
          itemCount: 1,
          activeDragPayload: const FolderDragPayload(
            folderId: 'folder-1',
            index: 0,
            parentFolderId: null,
            depth: 0,
          ),
          canAcceptPayload: (_) => true,
          onPayloadDropped: (_) {},
          onTap: () {},
          onRenamePressed: () {},
          onDeletePressed: () {},
        ),
      ),
    );

    expect(find.text('Folder'), findsOneWidget);
    expect(find.text('Upper Body'), findsOneWidget);
    expect(find.text('Release to nest folder'), findsOneWidget);
  });
}
