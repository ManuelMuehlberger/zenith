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

  testWidgets('FolderCard does not preview move hint for ambient template drags', (
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

    expect(find.text('Push Workouts'), findsOneWidget);
    expect(find.text('Drop here to move template'), findsNothing);
    expect(find.text('3 templates, 0 folders'), findsOneWidget);
  });

  testWidgets('FolderCard shows template move hint on direct hover', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        Column(
          children: [
            LongPressDraggable<WorkoutBuilderDragPayload>(
              data: const TemplateDragPayload(
                templateId: 'template-1',
                index: 0,
                parentFolderId: null,
              ),
              delay: const Duration(milliseconds: 300),
              feedback: const Material(
                color: Colors.transparent,
                child: SizedBox(width: 120, height: 40),
              ),
              child: const SizedBox(width: 120, height: 40, child: Text('Drag me')),
            ),
            const SizedBox(height: 24),
            FolderCard(
              folder: WorkoutFolder(id: 'folder-hover', name: 'Hover Folder'),
              itemCount: 2,
              canAcceptPayload: (_) => true,
              onPayloadDropped: (_) {},
              onTap: () {},
              onRenamePressed: () {},
              onDeletePressed: () {},
            ),
          ],
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('Drag me')));
    await tester.pump(const Duration(milliseconds: 400));

    await gesture.moveTo(tester.getCenter(find.text('Hover Folder')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Drop here to move template'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('FolderCard accepts direct template drop', (tester) async {
    WorkoutBuilderDragPayload? droppedPayload;

    await tester.pumpWidget(
      buildTestApp(
        Column(
          children: [
            LongPressDraggable<WorkoutBuilderDragPayload>(
              data: const TemplateDragPayload(
                templateId: 'template-drop',
                index: 0,
                parentFolderId: null,
              ),
              delay: const Duration(milliseconds: 300),
              feedback: const Material(
                color: Colors.transparent,
                child: SizedBox(width: 120, height: 40),
              ),
              child: const SizedBox(
                width: 120,
                height: 40,
                child: Text('Drop workout'),
              ),
            ),
            const SizedBox(height: 24),
            FolderCard(
              folder: WorkoutFolder(id: 'folder-drop', name: 'Drop Folder'),
              itemCount: 2,
              canAcceptPayload: (_) => true,
              onPayloadDropped: (payload) => droppedPayload = payload,
              onTap: () {},
              onRenamePressed: () {},
              onDeletePressed: () {},
            ),
          ],
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Drop workout')),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await gesture.moveTo(tester.getCenter(find.text('Drop Folder')));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(droppedPayload, isA<TemplateDragPayload>());
    expect(
      (droppedPayload as TemplateDragPayload).templateId,
      'template-drop',
    );
  });

  testWidgets('FolderCard hover hint does not overflow at compact width', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        SizedBox(
          width: 255,
          child: Column(
            children: [
              LongPressDraggable<WorkoutBuilderDragPayload>(
                data: const TemplateDragPayload(
                  templateId: 'template-compact',
                  index: 0,
                  parentFolderId: null,
                ),
                delay: const Duration(milliseconds: 300),
                feedback: const Material(
                  color: Colors.transparent,
                  child: SizedBox(width: 120, height: 40),
                ),
                child: const SizedBox(
                  width: 120,
                  height: 40,
                  child: Text('Drag compact'),
                ),
              ),
              const SizedBox(height: 24),
              FolderCard(
                folder: WorkoutFolder(
                  id: 'folder-compact',
                  name: 'Compact Folder',
                ),
                itemCount: 2,
                canAcceptPayload: (_) => true,
                onPayloadDropped: (_) {},
                onTap: () {},
                onRenamePressed: () {},
                onDeletePressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Drag compact')),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await gesture.moveTo(tester.getCenter(find.text('Compact Folder')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Drop here to move template'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('FolderCard shows compact template and subfolder summary', (
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

    expect(find.text('4 templates, 2 folders'), findsOneWidget);
  });

  testWidgets('FolderCard does not preview nesting for ambient folder drags', (
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

    expect(find.text('Upper Body'), findsOneWidget);
    expect(find.text('Drop here to nest folder'), findsNothing);
    expect(find.text('1 template, 0 folders'), findsOneWidget);
  });

  testWidgets('FolderCard resting surfaces use refreshed folder tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        FolderCard(
          folder: WorkoutFolder(id: 'folder-4', name: 'Surface Match'),
          itemCount: 2,
          subfolderCount: 1,
          onPayloadDropped: (_) {},
          onTap: () {},
          onRenamePressed: () {},
          onDeletePressed: () {},
        ),
      ),
    );

    final buildContext = tester.element(find.byType(FolderCard));
    final cardContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Surface Match'),
            matching: find.byType(Container),
          )
          .first,
    );
    final menuInk = tester.widget<Ink>(find.byType(Ink).last);

    expect(
      (cardContainer.decoration as BoxDecoration).color,
      Color.alphaBlend(
        buildContext.appScheme.primary.withValues(alpha: 0.025),
        buildContext.appColors.surfaceAlt,
      ),
    );
    expect(
      (menuInk.decoration as BoxDecoration).color,
      Color.alphaBlend(
        buildContext.appScheme.primary.withValues(alpha: 0.04),
        buildContext.appColors.surfaceAlt,
      ),
    );
  });

  testWidgets('FolderCard uses neutral surface in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: FolderCard(
            folder: WorkoutFolder(id: 'folder-dark', name: 'Dark Folder'),
            itemCount: 2,
            subfolderCount: 1,
            onPayloadDropped: (_) {},
            onTap: () {},
            onRenamePressed: () {},
            onDeletePressed: () {},
          ),
        ),
      ),
    );

    final buildContext = tester.element(find.byType(FolderCard));
    final cardContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Dark Folder'),
            matching: find.byType(Container),
          )
          .first,
    );

    expect(
      (cardContainer.decoration as BoxDecoration).color,
      buildContext.appScheme.surface,
    );
  });
}
