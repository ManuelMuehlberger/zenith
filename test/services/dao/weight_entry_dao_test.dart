import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/services/dao/weight_entry_dao.dart';

class TestWeightEntryDao extends WeightEntryDao {
  TestWeightEntryDao(this._database);

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
          CREATE TABLE UserData (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            birthdate TEXT NOT NULL,
            units TEXT NOT NULL DEFAULT 'metric',
            createdAt TEXT NOT NULL,
            theme TEXT NOT NULL DEFAULT 'dark'
          )
        ''');

        await db.execute('''
          CREATE TABLE WeightEntry (
            id TEXT PRIMARY KEY,
            userDataId TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            value REAL NOT NULL,
            FOREIGN KEY (userDataId) REFERENCES UserData (id) ON DELETE CASCADE
          )
        ''');
      },
    ),
  );
}

WeightEntry _weightEntry({
  required String id,
  required DateTime timestamp,
  required double value,
}) {
  return WeightEntry(id: id, timestamp: timestamp, value: value);
}

Map<String, dynamic> _userDataRow(String id) {
  return {
    'id': id,
    'name': 'Test User $id',
    'birthdate': DateTime.utc(1990, 1, 1).toIso8601String(),
    'units': Units.metric.name,
    'createdAt': DateTime.utc(2024, 1, 1).toIso8601String(),
    'theme': 'dark',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  group('WeightEntryDao', () {
    late Database database;
    late TestWeightEntryDao dao;

    setUp(() async {
      database = await _openTestDatabase();
      dao = TestWeightEntryDao(database);
      await database.insert('UserData', _userDataRow('user-1'));
      await database.insert('UserData', _userDataRow('user-2'));
    });

    tearDown(() async {
      await database.close();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'WeightEntry');
    });

    test('serializes and deserializes weight entries', () {
      final timestamp = DateTime.utc(2024, 3, 4, 5, 6, 7);
      final weightEntry = _weightEntry(
        id: 'weight-123',
        timestamp: timestamp,
        value: 75.5,
      );

      final map = dao.toMap(weightEntry);
      final restored = dao.fromMap(map);

      expect(map, {
        'id': 'weight-123',
        'timestamp': timestamp.toIso8601String(),
        'value': 75.5,
      });
      expect(restored.id, 'weight-123');
      expect(restored.timestamp, timestamp);
      expect(restored.value, 75.5);
    });

    test(
      'adds entries for a user and returns only that users entries sorted by timestamp',
      () async {
        await dao.addWeightEntryForUser(
          'user-1',
          _weightEntry(
            id: 'entry-late',
            timestamp: DateTime.utc(2024, 2, 1),
            value: 81.2,
          ),
        );
        await dao.addWeightEntryForUser(
          'user-2',
          _weightEntry(
            id: 'other-user-entry',
            timestamp: DateTime.utc(2024, 1, 15),
            value: 90.0,
          ),
        );
        await dao.addWeightEntryForUser(
          'user-1',
          _weightEntry(
            id: 'entry-early',
            timestamp: DateTime.utc(2024, 1, 1),
            value: 80.0,
          ),
        );

        final entries = await dao.getWeightEntriesByUserId('user-1');

        expect(entries.map((entry) => entry.id), ['entry-early', 'entry-late']);
        expect(entries.map((entry) => entry.value), [80.0, 81.2]);
      },
    );

    test('returns an empty list when a user has no weight entries', () async {
      final entries = await dao.getWeightEntriesByUserId('missing-user');

      expect(entries, isEmpty);
    });

    test(
      'updates an existing entry and can move it to a different user filter',
      () async {
        await dao.addWeightEntryForUser(
          'user-1',
          _weightEntry(
            id: 'entry-1',
            timestamp: DateTime.utc(2024, 1, 10),
            value: 82.0,
          ),
        );

        final updatedCount = await dao.updateWeightEntry(
          'user-2',
          _weightEntry(
            id: 'entry-1',
            timestamp: DateTime.utc(2024, 1, 11),
            value: 79.4,
          ),
        );

        final originalUserEntries = await dao.getWeightEntriesByUserId(
          'user-1',
        );
        final newUserEntries = await dao.getWeightEntriesByUserId('user-2');

        expect(updatedCount, 1);
        expect(originalUserEntries, isEmpty);
        expect(newUserEntries, hasLength(1));
        expect(newUserEntries.single.id, 'entry-1');
        expect(newUserEntries.single.timestamp, DateTime.utc(2024, 1, 11));
        expect(newUserEntries.single.value, 79.4);
      },
    );

    test('returns zero when updating a missing entry', () async {
      final updatedCount = await dao.updateWeightEntry(
        'user-1',
        _weightEntry(
          id: 'missing-entry',
          timestamp: DateTime.utc(2024, 1, 1),
          value: 75.0,
        ),
      );

      expect(updatedCount, 0);
    });

    test('throws when inserting a duplicate weight entry id', () async {
      final entry = _weightEntry(
        id: 'duplicate-entry',
        timestamp: DateTime.utc(2024, 2, 2),
        value: 83.0,
      );

      await dao.addWeightEntryForUser('user-1', entry);

      expect(
        () => dao.addWeightEntryForUser('user-1', entry),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
