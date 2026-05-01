import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/models/workout_template.dart';
import 'package:zenith/services/dao/workout_template_dao.dart';

class TestWorkoutTemplateDao extends WorkoutTemplateDao {
  TestWorkoutTemplateDao(this._database);

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
          CREATE TABLE WorkoutTemplate (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            iconCodePoint INTEGER,
            colorValue INTEGER,
            folderId TEXT,
            notes TEXT,
            lastUsed TEXT,
            orderIndex INTEGER
          )
        ''');
      },
    ),
  );
}

WorkoutTemplate _template({
  required String id,
  required String name,
  String? description,
  int? iconCodePoint,
  int? colorValue,
  String? folderId,
  String? notes,
  String? lastUsed,
  int? orderIndex,
}) {
  return WorkoutTemplate(
    id: id,
    name: name,
    description: description,
    iconCodePoint: iconCodePoint,
    colorValue: colorValue,
    folderId: folderId,
    notes: notes,
    lastUsed: lastUsed,
    orderIndex: orderIndex,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  group('WorkoutTemplateDao', () {
    late Database database;
    late TestWorkoutTemplateDao dao;

    setUp(() async {
      database = await _openTestDatabase();
      dao = TestWorkoutTemplateDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('has the configured table name', () {
      expect(dao.tableName, 'WorkoutTemplate');
    });

    test('serializes every workout template field to database values', () {
      final lastUsed = DateTime.utc(2024, 1, 2, 3, 4, 5).toIso8601String();
      final template = _template(
        id: 'template-1',
        name: 'Push Day 💪',
        description: 'Focus on chest + shoulders',
        iconCodePoint: 0xe1a3,
        colorValue: 0xFF2196F3,
        folderId: 'folder-a',
        notes: 'Use controlled tempo @ top set',
        lastUsed: lastUsed,
        orderIndex: 7,
      );

      expect(dao.toMap(template), {
        'id': 'template-1',
        'name': 'Push Day 💪',
        'description': 'Focus on chest + shoulders',
        'iconCodePoint': 0xe1a3,
        'colorValue': 0xFF2196F3,
        'folderId': 'folder-a',
        'notes': 'Use controlled tempo @ top set',
        'lastUsed': lastUsed,
        'orderIndex': 7,
      });
    });

    test('deserializes nullable fields without inventing defaults', () {
      final template = dao.fromMap({
        'id': 'template-2',
        'name': 'Minimal template',
        'description': null,
        'iconCodePoint': null,
        'colorValue': null,
        'folderId': null,
        'notes': null,
        'lastUsed': null,
        'orderIndex': null,
      });

      expect(template.id, 'template-2');
      expect(template.name, 'Minimal template');
      expect(template.description, isNull);
      expect(template.iconCodePoint, isNull);
      expect(template.colorValue, isNull);
      expect(template.folderId, isNull);
      expect(template.notes, isNull);
      expect(template.lastUsed, isNull);
      expect(template.orderIndex, isNull);
    });

    test('persists and retrieves a template by id', () async {
      final template = _template(
        id: 'template-1',
        name: 'Leg Day',
        folderId: 'folder-a',
        orderIndex: 2,
      );

      final insertedId = await dao.insert(template);
      final retrieved = await dao.getWorkoutTemplateById('template-1');

      expect(insertedId, greaterThan(0));
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'template-1');
      expect(retrieved.name, 'Leg Day');
      expect(retrieved.folderId, 'folder-a');
      expect(retrieved.orderIndex, 2);
      expect(await dao.getWorkoutTemplateById('missing-template'), isNull);
    });

    test('filters templates by folder id and sorts by order index', () async {
      await dao.insertAll([
        _template(
          id: 'folder-a-third',
          name: 'Third',
          folderId: 'folder-a',
          orderIndex: 3,
        ),
        _template(
          id: 'folder-b-only',
          name: 'Other folder',
          folderId: 'folder-b',
          orderIndex: 1,
        ),
        _template(
          id: 'folder-a-first',
          name: 'First',
          folderId: 'folder-a',
          orderIndex: 1,
        ),
        _template(
          id: 'folder-a-null-order',
          name: 'Null order',
          folderId: 'folder-a',
        ),
      ]);

      final templates = await dao.getWorkoutTemplatesByFolderId('folder-a');

      expect(
        templates.map((template) => template.id),
        orderedEquals([
          'folder-a-null-order',
          'folder-a-first',
          'folder-a-third',
        ]),
      );
      expect(
        await dao.getWorkoutTemplatesByFolderId('missing-folder'),
        isEmpty,
      );
    });

    test('returns only orphaned templates ordered by order index', () async {
      await dao.insertAll([
        _template(id: 'foldered', name: 'Foldered', folderId: 'folder-a'),
        _template(id: 'orphan-second', name: 'Second', orderIndex: 2),
        _template(id: 'orphan-first', name: 'First', orderIndex: 1),
        _template(id: 'orphan-null-order', name: 'Null order'),
      ]);

      final templates = await dao.getWorkoutTemplatesWithoutFolder();

      expect(
        templates.map((template) => template.id),
        orderedEquals(['orphan-null-order', 'orphan-first', 'orphan-second']),
      );
    });

    test('orders all templates by folder id and order index', () async {
      await dao.insertAll([
        _template(id: 'orphan', name: 'Orphan', orderIndex: 5),
        _template(
          id: 'folder-b-first',
          name: 'Folder B',
          folderId: 'folder-b',
          orderIndex: 1,
        ),
        _template(
          id: 'folder-a-second',
          name: 'Folder A second',
          folderId: 'folder-a',
          orderIndex: 2,
        ),
        _template(
          id: 'folder-a-null-order',
          name: 'Folder A null order',
          folderId: 'folder-a',
        ),
      ]);

      final templates = await dao.getAllWorkoutTemplatesOrdered();

      expect(
        templates.map((template) => template.id),
        orderedEquals([
          'orphan',
          'folder-a-null-order',
          'folder-a-second',
          'folder-b-first',
        ]),
      );
    });

    test(
      'updates a template and reports when the target does not exist',
      () async {
        await dao.insertAll([
          _template(
            id: 'template-1',
            name: 'Original',
            description: 'Before update',
            folderId: 'folder-a',
            orderIndex: 1,
          ),
          _template(id: 'template-2', name: 'Keep me'),
        ]);

        final updatedCount = await dao.updateWorkoutTemplate(
          _template(
            id: 'template-1',
            name: 'Updated',
            description: 'After update',
            iconCodePoint: 0xe531,
            colorValue: 0xFF4CAF50,
            folderId: null,
            notes: 'Fresh notes',
            lastUsed: DateTime.utc(2024, 4, 1, 8).toIso8601String(),
            orderIndex: 9,
          ),
        );
        final updatedRow = await database.query(
          dao.tableName,
          where: 'id = ?',
          whereArgs: ['template-1'],
        );

        expect(updatedCount, 1);
        expect(updatedRow.single, {
          'id': 'template-1',
          'name': 'Updated',
          'description': 'After update',
          'iconCodePoint': 0xe531,
          'colorValue': 0xFF4CAF50,
          'folderId': null,
          'notes': 'Fresh notes',
          'lastUsed': DateTime.utc(2024, 4, 1, 8).toIso8601String(),
          'orderIndex': 9,
        });
        expect(
          await dao.updateWorkoutTemplate(
            _template(id: 'missing', name: 'Missing'),
          ),
          0,
        );
        expect(await dao.getWorkoutTemplateById('template-2'), isNotNull);
      },
    );

    test('deletes only the requested template', () async {
      await dao.insertAll([
        _template(id: 'template-1', name: 'Delete me'),
        _template(id: 'template-2', name: 'Keep me'),
      ]);

      final deletedCount = await dao.deleteWorkoutTemplate('template-1');

      expect(deletedCount, 1);
      expect(await dao.getWorkoutTemplateById('template-1'), isNull);
      expect(await dao.getWorkoutTemplateById('template-2'), isNotNull);
      expect(await dao.deleteWorkoutTemplate('missing-template'), 0);
    });

    test('updates lastUsed without changing other persisted fields', () async {
      const originalDescription = 'Original description';
      final newTimestamp = DateTime.utc(2024, 5, 6, 7, 8, 9).toIso8601String();

      await dao.insert(
        _template(
          id: 'template-1',
          name: 'Recently used',
          description: originalDescription,
          lastUsed: DateTime.utc(2024, 1, 1).toIso8601String(),
          orderIndex: 4,
        ),
      );

      final updatedCount = await dao.updateLastUsed('template-1', newTimestamp);
      final updatedRow = await database.query(
        dao.tableName,
        where: 'id = ?',
        whereArgs: ['template-1'],
      );

      expect(updatedCount, 1);
      expect(updatedRow.single['lastUsed'], newTimestamp);
      expect(updatedRow.single['description'], originalDescription);
      expect(updatedRow.single['orderIndex'], 4);
      expect(await dao.updateLastUsed('missing-template', newTimestamp), 0);
    });

    test(
      'returns recently used templates in descending order and honors limit',
      () async {
        await dao.insertAll([
          _template(
            id: 'oldest',
            name: 'Oldest',
            lastUsed: DateTime.utc(2024, 1, 1).toIso8601String(),
          ),
          _template(
            id: 'newest',
            name: 'Newest',
            lastUsed: DateTime.utc(2024, 3, 1).toIso8601String(),
          ),
          _template(
            id: 'middle',
            name: 'Middle',
            lastUsed: DateTime.utc(2024, 2, 1).toIso8601String(),
          ),
          _template(id: 'never-used', name: 'Never used'),
        ]);

        final limitedTemplates = await dao.getWorkoutTemplatesByLastUsed(
          limit: 2,
        );
        final allTemplates = await dao.getWorkoutTemplatesByLastUsed();

        expect(
          limitedTemplates.map((template) => template.id),
          orderedEquals(['newest', 'middle']),
        );
        expect(
          allTemplates.map((template) => template.id),
          orderedEquals(['newest', 'middle', 'oldest']),
        );
      },
    );

    test('rethrows persistence errors for duplicate ids', () async {
      await dao.insert(_template(id: 'template-1', name: 'First'));

      await expectLater(
        () => dao.insert(_template(id: 'template-1', name: 'Duplicate')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test(
      'rethrows mapping errors when persisted template data is invalid',
      () async {
        await database.insert(dao.tableName, {
          'id': 'broken-template',
          'name': 'Broken',
          'iconCodePoint': 'not-an-int',
        });

        await expectLater(
          () => dao.getAllWorkoutTemplatesOrdered(),
          throwsA(isA<TypeError>()),
        );
      },
    );
  });
}
