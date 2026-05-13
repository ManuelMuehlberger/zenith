import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/services/dao/base_dao.dart';

class TestRecord {
  const TestRecord({
    required this.id,
    required this.alternateId,
    required this.name,
  });

  final String id;
  final String alternateId;
  final String name;
}

class TestDao extends BaseDao<TestRecord> {
  TestDao(this._database, {this.throwOnStoredName}) : super('TestDao');

  final Database _database;
  final String? throwOnStoredName;
  int toMapCallCount = 0;
  int fromMapCallCount = 0;

  @override
  String get tableName => 'test_table';

  @override
  Future<Database> get database async => _database;

  @override
  TestRecord fromMap(Map<String, dynamic> map) {
    fromMapCallCount++;
    final storedName = map['name'] as String;
    if (storedName == throwOnStoredName) {
      throw FormatException('Unable to map row for $storedName');
    }

    return TestRecord(
      id: map['id'] as String,
      alternateId: map['alt_id'] as String,
      name: storedName.toLowerCase(),
    );
  }

  @override
  Map<String, dynamic> toMap(TestRecord model) {
    toMapCallCount++;
    return {
      'id': model.id,
      'alt_id': model.alternateId,
      'name': model.name.toUpperCase(),
    };
  }
}

Future<Database> _openTestDatabase() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE test_table (
            id TEXT PRIMARY KEY,
            alt_id TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL
          )
        ''');
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  group('BaseDao', () {
    late Database database;
    late TestDao dao;

    setUp(() async {
      database = await _openTestDatabase();
      dao = TestDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('has the configured table name', () {
      expect(dao.tableName, 'test_table');
    });

    test(
      'insert stores mapped data and getById returns mapped model',
      () async {
        final insertedId = await dao.insert(
          const TestRecord(id: 'id-1', alternateId: 'alt-1', name: 'Alpha'),
        );

        expect(insertedId, greaterThan(0));
        expect(dao.toMapCallCount, 1);

        final storedRows = await database.query(
          dao.tableName,
          where: 'id = ?',
          whereArgs: ['id-1'],
        );
        expect(storedRows.single['name'], 'ALPHA');

        final record = await dao.getById('id-1');

        expect(record, isNotNull);
        expect(record!.id, 'id-1');
        expect(record.alternateId, 'alt-1');
        expect(record.name, 'alpha');
        expect(dao.fromMapCallCount, 1);
      },
    );

    test('insertAll and getAll map every record', () async {
      final ids = await dao.insertAll(const [
        TestRecord(id: 'id-1', alternateId: 'alt-1', name: 'Alpha'),
        TestRecord(id: 'id-2', alternateId: 'alt-2', name: 'Beta'),
      ]);

      expect(ids, hasLength(2));
      expect(ids.every((id) => id > 0), isTrue);
      expect(dao.toMapCallCount, 2);

      final records = await dao.getAll();

      expect(records.map((record) => record.id), ['id-1', 'id-2']);
      expect(records.map((record) => record.name), ['alpha', 'beta']);
      expect(dao.fromMapCallCount, 2);
    });

    test('getById returns null when the record is missing', () async {
      expect(await dao.getById('missing-id'), isNull);
      expect(dao.fromMapCallCount, 0);
    });

    test('update and delete support custom id columns', () async {
      await dao.insert(
        const TestRecord(id: 'id-1', alternateId: 'alt-1', name: 'Alpha'),
      );

      final updatedCount = await dao.update(
        const TestRecord(id: 'id-1', alternateId: 'alt-1', name: 'Updated'),
        idColumn: 'alt_id',
      );

      expect(updatedCount, 1);

      final updatedRows = await database.query(
        dao.tableName,
        where: 'id = ?',
        whereArgs: ['id-1'],
      );
      expect(updatedRows.single['alt_id'], 'alt-1');
      expect(updatedRows.single['name'], 'UPDATED');

      final deletedCount = await dao.delete('alt-1', idColumn: 'alt_id');

      expect(deletedCount, 1);
      expect(await dao.getAll(), isEmpty);
    });

    test('deleteAll removes every record from the table', () async {
      await dao.insertAll(const [
        TestRecord(id: 'id-1', alternateId: 'alt-1', name: 'Alpha'),
        TestRecord(id: 'id-2', alternateId: 'alt-2', name: 'Beta'),
      ]);

      final deletedCount = await dao.deleteAll();

      expect(deletedCount, 2);
      expect(await dao.getAll(), isEmpty);
    });

    test('raw query helpers execute SQL and map returned rows', () async {
      await dao.insert(
        const TestRecord(id: 'id-1', alternateId: 'alt-1', name: 'Alpha'),
      );

      final updatedCount = await dao.rawUpdate(
        'UPDATE test_table SET name = ? WHERE id = ?',
        ['CHANGED', 'id-1'],
      );
      final records = await dao.rawQuery(
        'SELECT * FROM test_table WHERE id = ?',
        ['id-1'],
      );
      final deletedCount = await dao.rawDelete(
        'DELETE FROM test_table WHERE id = ?',
        ['id-1'],
      );

      expect(updatedCount, 1);
      expect(records, hasLength(1));
      expect(records.single.name, 'changed');
      expect(dao.fromMapCallCount, 1);
      expect(deletedCount, 1);
      expect(await dao.getAll(), isEmpty);
    });

    test('rethrows database errors from CRUD helpers', () async {
      await dao.insert(
        const TestRecord(id: 'id-1', alternateId: 'alt-1', name: 'Alpha'),
      );

      await expectLater(
        () => dao.insert(
          const TestRecord(id: 'id-1', alternateId: 'alt-2', name: 'Beta'),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rethrows mapping errors from rawQuery', () async {
      await database.insert(dao.tableName, {
        'id': 'id-1',
        'alt_id': 'alt-1',
        'name': 'BAD',
      });

      final throwingDao = TestDao(database, throwOnStoredName: 'BAD');

      await expectLater(
        () => throwingDao.rawQuery('SELECT * FROM test_table'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rethrows mapping errors from getAll', () async {
      await database.insert(dao.tableName, {
        'id': 'id-1',
        'alt_id': 'alt-1',
        'name': 'BAD',
      });

      final throwingDao = TestDao(database, throwOnStoredName: 'BAD');

      await expectLater(
        () => throwingDao.getAll(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
