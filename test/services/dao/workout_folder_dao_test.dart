import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/models/workout_folder.dart';
import 'package:zenith/services/dao/workout_folder_dao.dart';

class TestWorkoutFolderDao extends WorkoutFolderDao {
  TestWorkoutFolderDao(this._database);

  final Database _database;

  @override
  Future<Database> get database async => _database;
}

Future<Database> _openTestDatabase() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE WorkoutFolder (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            parentFolderId TEXT,
            depth INTEGER NOT NULL DEFAULT 0,
            orderIndex INTEGER
          )
        ''');
      },
    ),
  );
}

WorkoutFolder _folder({
  required String id,
  required String name,
  String? parentFolderId,
  int depth = 0,
  int? orderIndex,
}) {
  return WorkoutFolder(
    id: id,
    name: name,
    parentFolderId: parentFolderId,
    depth: depth,
    orderIndex: orderIndex,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  group('WorkoutFolderDao', () {
    late Database database;
    late TestWorkoutFolderDao dao;

    setUp(() async {
      database = await _openTestDatabase();
      dao = TestWorkoutFolderDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('has the configured table name', () {
      expect(dao.tableName, 'WorkoutFolder');
    });

    test('serializes workout folder fields to database values', () {
      final folder = _folder(
        id: 'folder-1',
        name: 'Chest Workouts',
        orderIndex: 7,
      );

      expect(dao.toMap(folder), {
        'id': 'folder-1',
        'name': 'Chest Workouts',
        'parentFolderId': null,
        'depth': 0,
        'orderIndex': 7,
      });
    });

    test('deserializes nullable order index without inventing defaults', () {
      final folder = dao.fromMap({
        'id': 'folder-2',
        'name': 'Arm Workouts',
        'orderIndex': null,
      });

      expect(folder.id, 'folder-2');
      expect(folder.name, 'Arm Workouts');
      expect(folder.parentFolderId, isNull);
      expect(folder.depth, 0);
      expect(folder.orderIndex, isNull);
    });

    test('persists and retrieves a folder by id', () async {
      final insertedId = await dao.insert(
        _folder(id: 'folder-1', name: 'Push', orderIndex: 2),
      );
      final retrieved = await dao.getWorkoutFolderById('folder-1');

      expect(insertedId, greaterThan(0));
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'folder-1');
      expect(retrieved.name, 'Push');
      expect(retrieved.parentFolderId, isNull);
      expect(retrieved.depth, 0);
      expect(retrieved.orderIndex, 2);
      expect(await dao.getWorkoutFolderById('missing-folder'), isNull);
    });

    test('returns all workout folders ordered by order index', () async {
      await dao.insertAll([
        _folder(id: 'folder-third', name: 'Third', orderIndex: 3),
        _folder(id: 'folder-null', name: 'No Order'),
        _folder(id: 'folder-first', name: 'First', orderIndex: 1),
      ]);

      final folders = await dao.getAllWorkoutFoldersOrdered();

      expect(
        folders.map((folder) => folder.id),
        orderedEquals(['folder-null', 'folder-first', 'folder-third']),
      );
    });

    test(
      'updates a folder and reports when the target does not exist',
      () async {
        await dao.insertAll([
          _folder(id: 'folder-1', name: 'Original', orderIndex: 1),
          _folder(id: 'folder-2', name: 'Keep me', orderIndex: 2),
        ]);

        final updatedCount = await dao.updateWorkoutFolder(
          _folder(id: 'folder-1', name: 'Updated', orderIndex: null),
        );
        final updatedRow = await database.query(
          dao.tableName,
          where: 'id = ?',
          whereArgs: ['folder-1'],
        );

        expect(updatedCount, 1);
        expect(updatedRow.single, {
          'id': 'folder-1',
          'name': 'Updated',
          'parentFolderId': null,
          'depth': 0,
          'orderIndex': null,
        });
        expect(
          await dao.updateWorkoutFolder(
            _folder(id: 'missing-folder', name: 'Missing'),
          ),
          0,
        );
        expect(await dao.getWorkoutFolderById('folder-2'), isNotNull);
      },
    );

    test('deletes only the requested folder', () async {
      await dao.insertAll([
        _folder(id: 'folder-1', name: 'Delete me'),
        _folder(id: 'folder-2', name: 'Keep me'),
      ]);

      final deletedCount = await dao.deleteWorkoutFolder('folder-1');

      expect(deletedCount, 1);
      expect(await dao.getWorkoutFolderById('folder-1'), isNull);
      expect(await dao.getWorkoutFolderById('folder-2'), isNotNull);
      expect(await dao.deleteWorkoutFolder('missing-folder'), 0);
    });

    test('rethrows persistence errors for duplicate ids', () async {
      await dao.insert(_folder(id: 'folder-1', name: 'First'));

      await expectLater(
        () => dao.insert(_folder(id: 'folder-1', name: 'Duplicate')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test(
      'rethrows mapping errors when persisted folder data is invalid',
      () async {
        await database.insert(dao.tableName, {
          'id': 'broken-folder',
          'name': 'Broken',
          'parentFolderId': null,
          'depth': 0,
          'orderIndex': 'not-an-int',
        });

        await expectLater(
          () => dao.getAllWorkoutFoldersOrdered(),
          throwsA(isA<TypeError>()),
        );
      },
    );
  });
}
