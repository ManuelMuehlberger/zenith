import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/services/dao/user_dao.dart';

class TestUserDao extends UserDao {
  TestUserDao(this._database);

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
            units TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            theme TEXT NOT NULL
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

  group('UserDao', () {
    late Database database;
    late UserDao dao;

    setUp(() async {
      database = await _openTestDatabase();
      dao = TestUserDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'UserData');
    });

    test('should convert user data to map', () {
      final now = DateTime.now();
      final userData = UserData(
        id: 'user123',
        name: 'John Doe',
        birthdate: DateTime(1990, 1, 1),
        units: Units.metric,
        weightHistory: [],
        createdAt: now,
        theme: 'dark',
      );

      final map = dao.toMap(userData);

      expect(map['id'], 'user123');
      expect(map['name'], 'John Doe');
      expect(map['birthdate'], '1990-01-01T00:00:00.000');
      expect(map['units'], 'metric');
      expect(map['createdAt'], now.toIso8601String());
      expect(map['theme'], 'dark');
    });

    test('should convert map to user data', () {
      final now = DateTime.now();
      final map = {
        'id': 'user456',
        'name': 'Jane Smith',
        'birthdate': '1995-05-15T00:00:00.000',
        'units': 'imperial',
        'createdAt': now.toIso8601String(),
        'theme': 'light',
      };

      final userData = dao.fromMap(map);

      expect(userData.id, 'user456');
      expect(userData.name, 'Jane Smith');
      expect(userData.birthdate, DateTime(1995, 5, 15));
      expect(userData.units, Units.imperial);
      expect(userData.weightHistory, isEmpty);
      expect(userData.createdAt, now);
      expect(userData.theme, 'light');
    });

    test(
      'getUserDataById returns the stored user and null for missing ids',
      () async {
        final userData = UserData(
          id: 'user789',
          name: 'Jordan Lee',
          birthdate: DateTime(1988, 7, 4),
          units: Units.metric,
          weightHistory: const [],
          createdAt: DateTime(2024, 1, 2, 3, 4, 5),
          theme: 'dark',
        );

        final insertedId = await dao.insert(userData);
        final retrieved = await dao.getUserDataById('user789');

        expect(insertedId, greaterThan(0));
        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'user789');
        expect(retrieved.name, 'Jordan Lee');
        expect(retrieved.birthdate, DateTime(1988, 7, 4));
        expect(retrieved.units, Units.metric);
        expect(retrieved.weightHistory, isEmpty);
        expect(retrieved.createdAt, DateTime(2024, 1, 2, 3, 4, 5));
        expect(retrieved.theme, 'dark');
        expect(await dao.getUserDataById('missing-user'), isNull);
      },
    );

    test('updateUserData updates only the matching stored row', () async {
      final original = UserData(
        id: 'user123',
        name: 'John Doe',
        birthdate: DateTime(1990, 1, 1),
        units: Units.metric,
        weightHistory: const [],
        createdAt: DateTime(2024, 5, 1, 10),
        theme: 'dark',
      );
      final untouched = UserData(
        id: 'user456',
        name: 'Jane Smith',
        birthdate: DateTime(1995, 5, 15),
        units: Units.imperial,
        weightHistory: const [],
        createdAt: DateTime(2024, 5, 2, 11),
        theme: 'light',
      );

      await dao.insertAll([original, untouched]);

      final updatedCount = await dao.updateUserData(
        original.copyWith(
          name: 'John Updated',
          units: Units.imperial,
          theme: 'system',
        ),
      );
      final updatedRow = await database.query(
        dao.tableName,
        where: 'id = ?',
        whereArgs: ['user123'],
      );

      expect(updatedCount, 1);
      expect(updatedRow.single, {
        'id': 'user123',
        'name': 'John Updated',
        'birthdate': '1990-01-01T00:00:00.000',
        'units': 'imperial',
        'createdAt': '2024-05-01T10:00:00.000',
        'theme': 'system',
      });
      expect((await dao.getUserDataById('user456'))!.name, 'Jane Smith');
      expect(
        await dao.updateUserData(
          original.copyWith(id: 'missing-user', name: 'Missing'),
        ),
        0,
      );
    });
  });
}
