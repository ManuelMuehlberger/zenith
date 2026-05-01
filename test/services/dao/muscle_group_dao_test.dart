import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';

class TestMuscleGroupDao extends MuscleGroupDao {
  TestMuscleGroupDao(this._database);

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
          CREATE TABLE MuscleGroup (
            name TEXT PRIMARY KEY
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

  group('MuscleGroupDao', () {
    late Database database;
    late MuscleGroupDao dao;

    setUp(() async {
      database = await _openTestDatabase();
      dao = TestMuscleGroupDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'MuscleGroup');
    });

    test('should convert muscle group to map', () {
      const muscleGroup = MuscleGroup.chest;
      final map = dao.toMap(muscleGroup);
      expect(map['name'], 'Chest');
    });

    test('should convert map to muscle group', () {
      final map = {'name': 'Quads'};
      final muscleGroup = dao.fromMap(map);
      expect(muscleGroup.name, 'Quads');
    });

    test('getAllMuscleGroups returns mapped muscle groups', () async {
      await database.insert('MuscleGroup', {'name': 'Chest'});
      await database.insert('MuscleGroup', {'name': 'Back'});

      final muscleGroups = await dao.getAllMuscleGroups();

      expect(muscleGroups, [MuscleGroup.chest, MuscleGroup.back]);
    });

    test(
      'getMuscleGroupByName returns a group when found and null when missing',
      () async {
        await database.insert('MuscleGroup', {'name': 'Abs'});

        expect(await dao.getMuscleGroupByName('Abs'), MuscleGroup.abs);
        expect(await dao.getMuscleGroupByName('Missing'), isNull);
      },
    );

    test(
      'getMuscleGroupByName rethrows mapping errors for invalid persisted data',
      () async {
        await database.insert('MuscleGroup', {'name': 'Invalid Muscle'});

        await expectLater(
          () => dao.getMuscleGroupByName('Invalid Muscle'),
          throwsA(isA<Exception>()),
        );
      },
    );
  });
}
