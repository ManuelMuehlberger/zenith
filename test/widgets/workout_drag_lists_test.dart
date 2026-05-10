import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_folder.dart';
import 'package:zenith/models/workout_template.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/folder_card.dart';
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

  Widget buildScrollableTestApp(
    Widget child, {
    required ScrollController controller,
    double height = 320,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          height: height,
          child: ListView(controller: controller, children: [child]),
        ),
      ),
    );
  }

  List<WorkoutTemplate> buildTemplates(int count) {
    return List.generate(
      count,
      (index) => WorkoutTemplate(
        id: 'template-$index',
        name: 'Workout $index',
        orderIndex: index,
      ),
    );
  }

  List<WorkoutFolder> buildFolders(int count) {
    return List.generate(
      count,
      (index) => WorkoutFolder(
        id: 'folder-$index',
        name: 'Folder ${String.fromCharCode(65 + index)}',
        orderIndex: index,
      ),
    );
  }

  Finder gapIndicatorFinder() {
    final gapColor = AppTheme.light.colorScheme.primary.withValues(alpha: 0.12);

    return find.byWidgetPredicate((widget) {
      Decoration? decoration;
      double? height;

      if (widget is AnimatedContainer) {
        decoration = widget.decoration;
        height = widget.constraints?.maxHeight;
      } else if (widget is Container) {
        decoration = widget.decoration;
        height = widget.constraints?.maxHeight;
      } else {
        return false;
      }

      return height == 18 &&
          decoration is BoxDecoration &&
          decoration.color == gapColor;
    });
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

  testWidgets('drag list items are wrapped in repaint boundaries', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        Column(
          children: [
            ReorderableFolderList(
              folders: [
                WorkoutFolder(id: 'folder-a', name: 'Folder A', orderIndex: 0),
              ],
              currentParentFolderId: null,
              itemCountByFolder: const {'folder-a': 1},
              subfolderCountByFolder: const {'folder-a': 0},
              activeDragPayload: null,
              onFolderTap: (_) {},
              onRenamePressed: (_) {},
              onDeletePressed: (_) {},
              onFolderReordered: (_, __) {},
              onPayloadDroppedIntoFolder: (_, __) {},
              canDropIntoFolder: (_, __) => true,
              onDragStarted: (_) {},
              onDragEnded: () {},
            ),
            ReorderableWorkoutTemplateList(
              templates: [
                WorkoutTemplate(
                  id: 'template-a',
                  name: 'Workout A',
                  orderIndex: 0,
                ),
              ],
              folderId: null,
              onTemplateTap: (_) {},
              onTemplateDeletePressed: (_) {},
              onTemplateReordered: (_, __) {},
              onAddWorkoutPressed: null,
              onDragStarted: (_) {},
              onDragEnded: () {},
            ),
          ],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('reorderable-folder-card-repaint-folder-a')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('reorderable-template-card-repaint-template-a'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ReorderableWorkoutTemplateList reorders to end on drop', (
    tester,
  ) async {
    int? oldIndex;
    int? newIndex;
    final scrollController = ScrollController();

    await tester.pumpWidget(
      buildScrollableTestApp(
        ReorderableWorkoutTemplateList(
          templates: buildTemplates(2),
          folderId: null,
          onTemplateTap: (_) {},
          onTemplateDeletePressed: (_) {},
          onTemplateReordered: (from, to) {
            oldIndex = from;
            newIndex = to;
          },
          onAddWorkoutPressed: null,
          onDragStarted: (_) {},
          onDragEnded: () {},
        ),
        controller: scrollController,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Workout 0')),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await gesture.moveBy(const Offset(0, 220));
    await tester.pump(const Duration(milliseconds: 50));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(oldIndex, 0);
    expect(newIndex, 1);
  });

  testWidgets('ReorderableFolderList reorders to end on drop', (tester) async {
    int? oldIndex;
    int? newIndex;
    final scrollController = ScrollController();

    await tester.pumpWidget(
      buildScrollableTestApp(
        ReorderableFolderList(
          folders: buildFolders(3),
          currentParentFolderId: null,
          itemCountByFolder: const {
            'folder-0': 1,
            'folder-1': 2,
            'folder-2': 3,
          },
          subfolderCountByFolder: const {
            'folder-0': 0,
            'folder-1': 0,
            'folder-2': 0,
          },
          activeDragPayload: null,
          onFolderTap: (_) {},
          onRenamePressed: (_) {},
          onDeletePressed: (_) {},
          onFolderReordered: (from, to) {
            oldIndex = from;
            newIndex = to;
          },
          onPayloadDroppedIntoFolder: (_, __) {},
          canDropIntoFolder: (_, __) => true,
          onDragStarted: (_) {},
          onDragEnded: () {},
        ),
        controller: scrollController,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Folder A')),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final scrollRect = tester.getRect(find.byType(ListView));
    await gesture.moveTo(Offset(scrollRect.center.dx, scrollRect.bottom - 8));
    await tester.pump(const Duration(milliseconds: 50));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(oldIndex, 0);
    expect(newIndex, 2);
  });

  testWidgets(
    'ReorderableFolderList shows nesting hint without gap when hovering a folder',
    (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildScrollableTestApp(
          ReorderableFolderList(
            folders: buildFolders(3),
            currentParentFolderId: null,
            itemCountByFolder: const {
              'folder-0': 1,
              'folder-1': 2,
              'folder-2': 3,
            },
            subfolderCountByFolder: const {
              'folder-0': 0,
              'folder-1': 0,
              'folder-2': 0,
            },
            activeDragPayload: null,
            onFolderTap: (_) {},
            onRenamePressed: (_) {},
            onDeletePressed: (_) {},
            onFolderReordered: (_, __) {},
            onPayloadDroppedIntoFolder: (_, __) {},
            canDropIntoFolder: (_, __) => true,
            onDragStarted: (_) {},
            onDragEnded: () {},
          ),
          controller: scrollController,
        ),
      );

      final folderBCardRect = tester.getRect(find.byType(FolderCard).at(1));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Folder A')),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.moveTo(folderBCardRect.center);
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Drop here to nest folder'), findsOneWidget);
      expect(gapIndicatorFinder(), findsNothing);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'ReorderableFolderList shows only a gap when not hovering a folder',
    (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildScrollableTestApp(
          ReorderableFolderList(
            folders: buildFolders(3),
            currentParentFolderId: null,
            itemCountByFolder: const {
              'folder-0': 1,
              'folder-1': 2,
              'folder-2': 3,
            },
            subfolderCountByFolder: const {
              'folder-0': 0,
              'folder-1': 0,
              'folder-2': 0,
            },
            activeDragPayload: null,
            onFolderTap: (_) {},
            onRenamePressed: (_) {},
            onDeletePressed: (_) {},
            onFolderReordered: (_, __) {},
            onPayloadDroppedIntoFolder: (_, __) {},
            canDropIntoFolder: (_, __) => true,
            onDragStarted: (_) {},
            onDragEnded: () {},
          ),
          controller: scrollController,
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Folder A')),
      );
      await tester.pump(const Duration(milliseconds: 400));

      final scrollRect = tester.getRect(find.byType(ListView));
      await gesture.moveTo(Offset(scrollRect.center.dx, scrollRect.bottom - 8));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Drop here to nest folder'), findsNothing);
      expect(gapIndicatorFinder(), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'ReorderableFolderList reorders between folders instead of nesting near card edges',
    (tester) async {
      int? oldIndex;
      int? newIndex;
      var nestedDropCount = 0;
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildScrollableTestApp(
          ReorderableFolderList(
            folders: buildFolders(3),
            currentParentFolderId: null,
            itemCountByFolder: const {
              'folder-0': 1,
              'folder-1': 2,
              'folder-2': 3,
            },
            subfolderCountByFolder: const {
              'folder-0': 0,
              'folder-1': 0,
              'folder-2': 0,
            },
            activeDragPayload: null,
            onFolderTap: (_) {},
            onRenamePressed: (_) {},
            onDeletePressed: (_) {},
            onFolderReordered: (from, to) {
              oldIndex = from;
              newIndex = to;
            },
            onPayloadDroppedIntoFolder: (_, __) {
              nestedDropCount++;
            },
            canDropIntoFolder: (_, __) => true,
            onDragStarted: (_) {},
            onDragEnded: () {},
          ),
          controller: scrollController,
        ),
      );

      final folderBRect = tester.getRect(find.byType(FolderCard).at(1));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Folder C')),
      );
      await tester.pump(const Duration(milliseconds: 400));

      await gesture.moveTo(Offset(folderBRect.center.dx, folderBRect.top + 6));
      await tester.pump(const Duration(milliseconds: 50));

      expect(gapIndicatorFinder(), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      expect(nestedDropCount, 0);
      expect(oldIndex, 2);
      expect(newIndex, 1);
    },
  );

  testWidgets('ReorderableFolderList drops folders into folders on release', (
    tester,
  ) async {
    WorkoutBuilderDragPayload? droppedPayload;
    WorkoutFolder? droppedFolder;
    final scrollController = ScrollController();

    await tester.pumpWidget(
      buildScrollableTestApp(
        ReorderableFolderList(
          folders: buildFolders(3),
          currentParentFolderId: null,
          itemCountByFolder: const {
            'folder-0': 1,
            'folder-1': 2,
            'folder-2': 3,
          },
          subfolderCountByFolder: const {
            'folder-0': 0,
            'folder-1': 0,
            'folder-2': 0,
          },
          activeDragPayload: null,
          onFolderTap: (_) {},
          onRenamePressed: (_) {},
          onDeletePressed: (_) {},
          onFolderReordered: (_, __) {},
          onPayloadDroppedIntoFolder: (payload, folder) {
            droppedPayload = payload;
            droppedFolder = folder;
          },
          canDropIntoFolder: (_, __) => true,
          onDragStarted: (_) {},
          onDragEnded: () {},
        ),
        controller: scrollController,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Folder A')),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final folderBCardFinder = find.ancestor(
      of: find.text('Folder B'),
      matching: find.byType(FolderCard),
    );
    final folderBCardRect = tester.getRect(folderBCardFinder.first);
    await gesture.moveTo(folderBCardRect.center);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Drop here to nest folder'), findsOneWidget);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(droppedPayload, isA<FolderDragPayload>());
    expect((droppedPayload as FolderDragPayload).folderId, 'folder-0');
    expect(droppedFolder?.id, 'folder-1');
  });

  testWidgets('ReorderableWorkoutTemplateList shows one original-slot gap', (
    tester,
  ) async {
    final scrollController = ScrollController();

    await tester.pumpWidget(
      buildScrollableTestApp(
        ReorderableWorkoutTemplateList(
          templates: buildTemplates(3),
          folderId: null,
          onTemplateTap: (_) {},
          onTemplateDeletePressed: (_) {},
          onTemplateReordered: (_, __) {},
          onAddWorkoutPressed: null,
          onDragStarted: (_) {},
          onDragEnded: () {},
        ),
        controller: scrollController,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Workout 0')),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await gesture.moveBy(const Offset(0, 1));
    await tester.pump(const Duration(milliseconds: 50));

    expect(gapIndicatorFinder(), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets(
    'ReorderableWorkoutTemplateList shows one end gap below the last item',
    (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildScrollableTestApp(
          ReorderableWorkoutTemplateList(
            templates: buildTemplates(3),
            folderId: null,
            onTemplateTap: (_) {},
            onTemplateDeletePressed: (_) {},
            onTemplateReordered: (_, __) {},
            onAddWorkoutPressed: null,
            onDragStarted: (_) {},
            onDragEnded: () {},
          ),
          controller: scrollController,
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Workout 0')),
      );
      await tester.pump(const Duration(milliseconds: 400));

      await gesture.moveBy(const Offset(0, 260));
      await tester.pump(const Duration(milliseconds: 50));

      expect(gapIndicatorFinder(), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'ReorderableFolderList clears nested hover and reorders after subsequent drag updates',
    (tester) async {
      int? oldIndex;
      int? newIndex;
      WorkoutFolder? nestedDropFolder;
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildScrollableTestApp(
          ReorderableFolderList(
            folders: buildFolders(3),
            currentParentFolderId: null,
            itemCountByFolder: const {
              'folder-0': 1,
              'folder-1': 2,
              'folder-2': 3,
            },
            subfolderCountByFolder: const {
              'folder-0': 0,
              'folder-1': 0,
              'folder-2': 0,
            },
            activeDragPayload: null,
            onFolderTap: (_) {},
            onRenamePressed: (_) {},
            onDeletePressed: (_) {},
            onFolderReordered: (from, to) {
              oldIndex = from;
              newIndex = to;
            },
            onPayloadDroppedIntoFolder: (_, folder) {
              nestedDropFolder = folder;
            },
            canDropIntoFolder: (_, __) => true,
            onDragStarted: (_) {},
            onDragEnded: () {},
          ),
          controller: scrollController,
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Folder A')),
      );
      await tester.pump(const Duration(milliseconds: 400));

      final folderBRect = tester.getRect(find.byType(FolderCard).at(1));
      final listRect = tester.getRect(find.byType(ListView));

      await gesture.moveTo(folderBRect.center);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Drop here to nest folder'), findsOneWidget);

      await gesture.moveTo(Offset(listRect.center.dx, listRect.bottom - 8));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Drop here to nest folder'), findsNothing);
      expect(gapIndicatorFinder(), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      expect(nestedDropFolder, isNull);
      expect(oldIndex, 0);
      expect(newIndex, 2);
    },
  );
}
