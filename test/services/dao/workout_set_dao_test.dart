import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';

class TestWorkoutSetDao extends WorkoutSetDao {
  TestWorkoutSetDao(this._database);

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
          CREATE TABLE WorkoutSet (
            id TEXT PRIMARY KEY,
            workoutExerciseId TEXT NOT NULL,
            setIndex INTEGER NOT NULL,
            targetReps INTEGER,
            targetWeight REAL,
            targetRestSeconds INTEGER,
            actualReps INTEGER,
            actualWeight REAL,
            isCompleted INTEGER DEFAULT 0
          )
        ''');
      },
    ),
  );
}

WorkoutSet _workoutSet({
  required String id,
  required String workoutExerciseId,
  required int setIndex,
  int? targetReps,
  double? targetWeight,
  int? targetRestSeconds,
  int? actualReps,
  double? actualWeight,
  bool isCompleted = false,
}) {
  return WorkoutSet(
    id: id,
    workoutExerciseId: workoutExerciseId,
    setIndex: setIndex,
    targetReps: targetReps,
    targetWeight: targetWeight,
    targetRestSeconds: targetRestSeconds,
    actualReps: actualReps,
    actualWeight: actualWeight,
    isCompleted: isCompleted,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  group('WorkoutSetDao', () {
    late Database database;
    late TestWorkoutSetDao dao;

    setUp(() async {
      database = await _openTestDatabase();
      dao = TestWorkoutSetDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'WorkoutSet');
    });

    test('should convert workout set to map', () {
      final workoutSet = _workoutSet(
        id: 'set123',
        workoutExerciseId: 'exercise123',
        setIndex: 1,
        targetReps: 10,
        targetWeight: 50.0,
        targetRestSeconds: 60,
        actualReps: 8,
        actualWeight: 50.0,
        isCompleted: true,
      );

      final map = dao.toMap(workoutSet);

      expect(map['id'], 'set123');
      expect(map['workoutExerciseId'], 'exercise123');
      expect(map['setIndex'], 1);
      expect(map['targetReps'], 10);
      expect(map['targetWeight'], 50.0);
      expect(map['targetRestSeconds'], 60);
      expect(map['actualReps'], 8);
      expect(map['actualWeight'], 50.0);
      expect(map['isCompleted'], 1);
    });

    test('should convert map to workout set', () {
      final map = {
        'id': 'set456',
        'workoutExerciseId': 'exercise456',
        'setIndex': 2,
        'targetReps': 12,
        'targetWeight': 40.0,
        'targetRestSeconds': 90,
        'actualReps': 12,
        'actualWeight': 40.0,
        'isCompleted': 1,
      };

      final workoutSet = dao.fromMap(map);

      expect(workoutSet.id, 'set456');
      expect(workoutSet.workoutExerciseId, 'exercise456');
      expect(workoutSet.setIndex, 2);
      expect(workoutSet.targetReps, 12);
      expect(workoutSet.targetWeight, 40.0);
      expect(workoutSet.targetRestSeconds, 90);
      expect(workoutSet.actualReps, 12);
      expect(workoutSet.actualWeight, 40.0);
      expect(workoutSet.isCompleted, true);
    });

    test('should handle null values', () {
      final map = {
        'id': 'set789',
        'workoutExerciseId': 'exercise789',
        'setIndex': 3,
        'targetReps': null,
        'targetWeight': null,
        'targetRestSeconds': null,
        'actualReps': null,
        'actualWeight': null,
        'isCompleted': 0,
      };

      final workoutSet = dao.fromMap(map);

      expect(workoutSet.id, 'set789');
      expect(workoutSet.workoutExerciseId, 'exercise789');
      expect(workoutSet.setIndex, 3);
      expect(workoutSet.targetReps, isNull);
      expect(workoutSet.targetWeight, isNull);
      expect(workoutSet.targetRestSeconds, isNull);
      expect(workoutSet.actualReps, isNull);
      expect(workoutSet.actualWeight, isNull);
      expect(workoutSet.isCompleted, false);
    });

    test('should handle incomplete set', () {
      final map = {
        'id': 'set999',
        'workoutExerciseId': 'exercise999',
        'setIndex': 1,
        'isCompleted': 0,
      };

      final workoutSet = dao.fromMap(map);
      expect(workoutSet.isCompleted, false);
    });

    test('persists and retrieves a workout set by id', () async {
      final workoutSet = _workoutSet(
        id: 'set-1',
        workoutExerciseId: 'exercise-1',
        setIndex: 3,
        targetReps: 8,
        targetWeight: 72.5,
        targetRestSeconds: 90,
        actualReps: 7,
        actualWeight: 70.0,
        isCompleted: true,
      );

      await dao.insert(workoutSet);

      final retrieved = await dao.getWorkoutSetById('set-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'set-1');
      expect(retrieved.workoutExerciseId, 'exercise-1');
      expect(retrieved.setIndex, 3);
      expect(retrieved.targetReps, 8);
      expect(retrieved.targetWeight, 72.5);
      expect(retrieved.targetRestSeconds, 90);
      expect(retrieved.actualReps, 7);
      expect(retrieved.actualWeight, 70.0);
      expect(retrieved.isCompleted, isTrue);
    });

    test('returns null when a workout set id does not exist', () async {
      expect(await dao.getWorkoutSetById('missing-id'), isNull);
    });

    test('returns sets sorted by set index for a workout exercise', () async {
      await dao.insertAll([
        _workoutSet(id: 'set-3', workoutExerciseId: 'exercise-1', setIndex: 3),
        _workoutSet(id: 'set-1', workoutExerciseId: 'exercise-1', setIndex: 1),
        _workoutSet(id: 'set-2', workoutExerciseId: 'exercise-1', setIndex: 2),
        _workoutSet(id: 'other', workoutExerciseId: 'exercise-2', setIndex: 1),
      ]);

      final sets = await dao.getWorkoutSetsByWorkoutExerciseId('exercise-1');

      expect(sets.map((set) => set.id), ['set-1', 'set-2', 'set-3']);
      expect(
        sets.every((set) => set.workoutExerciseId == 'exercise-1'),
        isTrue,
      );
    });

    test('returns completed sets only and keeps them sorted', () async {
      await dao.insertAll([
        _workoutSet(
          id: 'set-3',
          workoutExerciseId: 'exercise-1',
          setIndex: 3,
          isCompleted: true,
        ),
        _workoutSet(
          id: 'set-1',
          workoutExerciseId: 'exercise-1',
          setIndex: 1,
          isCompleted: true,
        ),
        _workoutSet(
          id: 'set-2',
          workoutExerciseId: 'exercise-1',
          setIndex: 2,
          isCompleted: false,
        ),
        _workoutSet(
          id: 'other',
          workoutExerciseId: 'exercise-2',
          setIndex: 1,
          isCompleted: true,
        ),
      ]);

      final sets = await dao.getCompletedWorkoutSetsByWorkoutExerciseId(
        'exercise-1',
      );

      expect(sets.map((set) => set.id), ['set-1', 'set-3']);
      expect(sets.every((set) => set.isCompleted), isTrue);
    });

    test('returns sets ordered by workout exercise id and set index', () async {
      await dao.insertAll([
        _workoutSet(id: 'b-2', workoutExerciseId: 'exercise-b', setIndex: 2),
        _workoutSet(id: 'a-3', workoutExerciseId: 'exercise-a', setIndex: 3),
        _workoutSet(id: 'a-1', workoutExerciseId: 'exercise-a', setIndex: 1),
        _workoutSet(id: 'b-1', workoutExerciseId: 'exercise-b', setIndex: 1),
        _workoutSet(id: 'c-1', workoutExerciseId: 'exercise-c', setIndex: 1),
      ]);

      final sets = await dao.getWorkoutSetsByWorkoutExerciseIds([
        'exercise-b',
        'exercise-a',
      ]);

      expect(sets.map((set) => '${set.workoutExerciseId}:${set.setIndex}'), [
        'exercise-a:1',
        'exercise-a:3',
        'exercise-b:1',
        'exercise-b:2',
      ]);
    });

    test(
      'returns an empty list when no workout exercise ids are provided',
      () async {
        await dao.insert(
          _workoutSet(
            id: 'set-1',
            workoutExerciseId: 'exercise-1',
            setIndex: 1,
          ),
        );

        final sets = await dao.getWorkoutSetsByWorkoutExerciseIds([]);

        expect(sets, isEmpty);
      },
    );

    test(
      'updates an existing workout set and leaves its id unchanged',
      () async {
        await dao.insert(
          _workoutSet(
            id: 'set-1',
            workoutExerciseId: 'exercise-1',
            setIndex: 1,
            targetReps: 8,
            actualReps: 6,
            isCompleted: false,
          ),
        );

        final updatedCount = await dao.updateWorkoutSet(
          _workoutSet(
            id: 'set-1',
            workoutExerciseId: 'exercise-1',
            setIndex: 4,
            targetReps: 10,
            targetWeight: 80.0,
            targetRestSeconds: 120,
            actualReps: 10,
            actualWeight: 80.0,
            isCompleted: true,
          ),
        );

        final rows = await database.query(
          dao.tableName,
          where: 'id = ?',
          whereArgs: ['set-1'],
        );

        expect(updatedCount, 1);
        expect(rows.single['id'], 'set-1');
        expect(rows.single['setIndex'], 4);
        expect(rows.single['targetReps'], 10);
        expect(rows.single['targetWeight'], 80.0);
        expect(rows.single['targetRestSeconds'], 120);
        expect(rows.single['actualReps'], 10);
        expect(rows.single['actualWeight'], 80.0);
        expect(rows.single['isCompleted'], 1);
      },
    );

    test('returns 0 when updating a workout set that does not exist', () async {
      final updatedCount = await dao.updateWorkoutSet(
        _workoutSet(
          id: 'missing',
          workoutExerciseId: 'exercise-1',
          setIndex: 1,
        ),
      );

      expect(updatedCount, 0);
    });

    test('deletes a single workout set by id', () async {
      await dao.insertAll([
        _workoutSet(id: 'set-1', workoutExerciseId: 'exercise-1', setIndex: 1),
        _workoutSet(id: 'set-2', workoutExerciseId: 'exercise-1', setIndex: 2),
      ]);

      final deletedCount = await dao.deleteWorkoutSet('set-1');

      expect(deletedCount, 1);
      expect(await dao.getWorkoutSetById('set-1'), isNull);
      expect(await dao.getWorkoutSetById('set-2'), isNotNull);
    });

    test('returns 0 when deleting a workout set by a missing id', () async {
      expect(await dao.deleteWorkoutSet('missing-id'), 0);
    });

    test('deletes all workout sets for a workout exercise only', () async {
      await dao.insertAll([
        _workoutSet(id: 'set-1', workoutExerciseId: 'exercise-1', setIndex: 1),
        _workoutSet(id: 'set-2', workoutExerciseId: 'exercise-1', setIndex: 2),
        _workoutSet(id: 'set-3', workoutExerciseId: 'exercise-2', setIndex: 1),
      ]);

      final deletedCount = await dao.deleteWorkoutSetsByWorkoutExerciseId(
        'exercise-1',
      );

      expect(deletedCount, 2);
      expect(
        await dao.getWorkoutSetsByWorkoutExerciseId('exercise-1'),
        isEmpty,
      );
      expect(
        (await dao.getWorkoutSetsByWorkoutExerciseId(
          'exercise-2',
        )).map((set) => set.id),
        ['set-3'],
      );
    });

    test(
      'returns 0 when deleting workout sets for a missing exercise id',
      () async {
        expect(await dao.deleteWorkoutSetsByWorkoutExerciseId('missing'), 0);
      },
    );

    test('rethrows persistence errors for duplicate ids', () async {
      await dao.insert(
        _workoutSet(id: 'set-1', workoutExerciseId: 'exercise-1', setIndex: 1),
      );

      await expectLater(
        () => dao.insert(
          _workoutSet(
            id: 'set-1',
            workoutExerciseId: 'exercise-2',
            setIndex: 2,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rethrows mapping errors when persisted data is invalid', () async {
      await database.insert(dao.tableName, {
        'id': 'set-1',
        'workoutExerciseId': 'exercise-1',
        'setIndex': 'invalid',
        'isCompleted': 0,
      });

      await expectLater(
        () => dao.getWorkoutSetsByWorkoutExerciseId('exercise-1'),
        throwsA(isA<FormatException>()),
      );
    });

    test('should preserve explicit false completion on copyWith', () {
      final workoutSet = WorkoutSet(
        workoutExerciseId: 'exercise999',
        setIndex: 1,
        isCompleted: true,
      );

      final copied = workoutSet.copyWith(isCompleted: false);

      expect(copied.isCompleted, isFalse);
      expect(workoutSet.isCompleted, isTrue);
    });
  });
}
