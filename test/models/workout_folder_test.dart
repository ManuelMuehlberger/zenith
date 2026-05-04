import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/workout_folder.dart';

void main() {
  group('WorkoutFolder', () {
    late WorkoutFolder workoutFolder;

    setUp(() {
      workoutFolder = WorkoutFolder(name: 'Test Folder', orderIndex: 1);
    });

    test('should create a workout folder with default values', () {
      expect(workoutFolder.id, isNotNull);
      expect(workoutFolder.name, 'Test Folder');
      expect(workoutFolder.parentFolderId, isNull);
      expect(workoutFolder.depth, 0);
      expect(workoutFolder.orderIndex, 1);
    });

    test('should create a workout folder without orderIndex', () {
      final folder = WorkoutFolder(name: 'Test Folder');
      expect(folder.id, isNotNull);
      expect(folder.name, 'Test Folder');
      expect(folder.orderIndex, isNull);
    });

    test('should create a workout folder with specified id', () {
      const id = 'test-id';
      final folder = WorkoutFolder(id: id, name: 'Test Folder', orderIndex: 1);

      expect(folder.id, id);
      expect(folder.name, 'Test Folder');
      expect(folder.parentFolderId, isNull);
      expect(folder.depth, 0);
      expect(folder.orderIndex, 1);
    });

    test('should create a nested workout folder', () {
      final folder = WorkoutFolder(
        id: 'child-id',
        name: 'Child Folder',
        parentFolderId: 'parent-id',
        depth: 1,
        orderIndex: 2,
      );

      expect(folder.parentFolderId, 'parent-id');
      expect(folder.depth, 1);
      expect(folder.orderIndex, 2);
    });

    test('should create a workout folder from map', () {
      final map = {
        'id': 'test-id',
        'name': 'Test Folder',
        'parentFolderId': 'parent-id',
        'depth': 1,
        'orderIndex': 1,
      };

      final folderFromMap = WorkoutFolder.fromMap(map);

      expect(folderFromMap.id, 'test-id');
      expect(folderFromMap.name, 'Test Folder');
      expect(folderFromMap.parentFolderId, 'parent-id');
      expect(folderFromMap.depth, 1);
      expect(folderFromMap.orderIndex, 1);
    });

    test('should create a workout folder from map without orderIndex', () {
      final map = {'id': 'test-id', 'name': 'Test Folder'};

      final folderFromMap = WorkoutFolder.fromMap(map);

      expect(folderFromMap.id, 'test-id');
      expect(folderFromMap.name, 'Test Folder');
      expect(folderFromMap.parentFolderId, isNull);
      expect(folderFromMap.depth, 0);
      expect(folderFromMap.orderIndex, isNull);
    });

    test('should convert workout folder to map', () {
      final map = workoutFolder.toMap();

      expect(map['id'], workoutFolder.id);
      expect(map['name'], 'Test Folder');
      expect(map['parentFolderId'], isNull);
      expect(map['depth'], 0);
      expect(map['orderIndex'], 1);
    });

    test('should convert workout folder to map without orderIndex', () {
      final folder = WorkoutFolder(name: 'Test Folder');
      final map = folder.toMap();

      expect(map['id'], folder.id);
      expect(map['name'], 'Test Folder');
      expect(map['parentFolderId'], isNull);
      expect(map['depth'], 0);
      expect(map['orderIndex'], isNull);
    });

    test('should copy with new values', () {
      final copiedFolder = workoutFolder.copyWith(
        name: 'Copied Folder',
        orderIndex: 2,
      );

      expect(copiedFolder.name, 'Copied Folder');
      expect(copiedFolder.parentFolderId, workoutFolder.parentFolderId);
      expect(copiedFolder.depth, workoutFolder.depth);
      expect(copiedFolder.orderIndex, 2);
      // Other values should remain the same
      expect(copiedFolder.id, workoutFolder.id);
    });

    test('should copy with new hierarchy values', () {
      final copiedFolder = workoutFolder.copyWith(
        parentFolderId: 'parent-id',
        depth: 1,
      );

      expect(copiedFolder.parentFolderId, 'parent-id');
      expect(copiedFolder.depth, 1);
      expect(copiedFolder.orderIndex, workoutFolder.orderIndex);
    });

    test('should copy with new id', () {
      const newId = 'new-id';
      final copiedFolder = workoutFolder.copyWith(
        id: newId,
        name: 'Copied Folder',
      );

      expect(copiedFolder.id, newId);
      expect(copiedFolder.name, 'Copied Folder');
      expect(copiedFolder.orderIndex, workoutFolder.orderIndex);
    });

    test('should copy with explicitly null orderIndex', () {
      final copiedFolder = workoutFolder.copyWith(orderIndex: null);

      expect(copiedFolder.name, workoutFolder.name);
      expect(copiedFolder.orderIndex, isNull);
      expect(copiedFolder.id, workoutFolder.id);
    });

    test('should copy with explicitly null parentFolderId', () {
      final nestedFolder = WorkoutFolder(
        name: 'Nested Folder',
        parentFolderId: 'parent-id',
        depth: 1,
      );

      final copiedFolder = nestedFolder.copyWith(
        parentFolderId: null,
        depth: 0,
      );

      expect(copiedFolder.parentFolderId, isNull);
      expect(copiedFolder.depth, 0);
    });
  });
}
