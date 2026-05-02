import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/services/dao/workout_dao.dart';

class TestWorkoutDao extends WorkoutDao {
  TestWorkoutDao(this._database);

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
          CREATE TABLE Workout (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            iconCodePoint INTEGER,
            colorValue INTEGER,
            folderId TEXT,
            notes TEXT,
            lastUsed TEXT,
            orderIndex INTEGER,
            status INTEGER NOT NULL DEFAULT 0,
            templateId TEXT,
            startedAt TEXT,
            completedAt TEXT,
            mood INTEGER
          )
        ''');
      },
    ),
  );
}

Workout _workout({
  required String id,
  required String name,
  String? description,
  int? iconCodePoint,
  int? colorValue,
  String? folderId,
  String? notes,
  String? lastUsed,
  int? orderIndex,
  WorkoutStatus status = WorkoutStatus.template,
  String? templateId,
  DateTime? startedAt,
  DateTime? completedAt,
  int? mood,
}) {
  return Workout(
    id: id,
    name: name,
    description: description,
    iconCodePoint: iconCodePoint,
    colorValue: colorValue,
    folderId: folderId,
    notes: notes,
    lastUsed: lastUsed,
    orderIndex: orderIndex,
    status: status,
    templateId: templateId,
    startedAt: startedAt,
    completedAt: completedAt,
    mood: mood,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  group('WorkoutDao', () {
    late Database database;
    late TestWorkoutDao dao;

    setUp(() async {
      database = await _openTestDatabase();
      dao = TestWorkoutDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'Workout');
    });

    test('serializes workout fields to database values', () {
      final startedAt = DateTime.utc(2024, 1, 2, 3, 4, 5);
      final completedAt = DateTime.utc(2024, 1, 2, 4, 4, 5);
      final workout = _workout(
        id: 'workout-1',
        name: 'Chest Day',
        description: 'Focus on chest exercises',
        iconCodePoint: 0xe1a3,
        colorValue: 0xFF2196F3,
        folderId: 'folder-1',
        notes: 'Warm up properly',
        lastUsed: startedAt.toIso8601String(),
        orderIndex: 1,
        status: WorkoutStatus.completed,
        templateId: 'template-1',
        startedAt: startedAt,
        completedAt: completedAt,
        mood: 5,
      );

      final map = dao.toMap(workout);

      expect(map, {
        'id': 'workout-1',
        'name': 'Chest Day',
        'description': 'Focus on chest exercises',
        'iconCodePoint': 0xe1a3,
        'colorValue': 0xFF2196F3,
        'folderId': 'folder-1',
        'notes': 'Warm up properly',
        'lastUsed': startedAt.toIso8601String(),
        'orderIndex': 1,
        'status': WorkoutStatus.completed.index,
        'templateId': 'template-1',
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'mood': 5,
      });
    });

    test('deserializes persisted values into an immutable workout model', () {
      final startedAt = DateTime.utc(2024, 2, 3, 4, 5, 6);
      final completedAt = DateTime.utc(2024, 2, 3, 5, 5, 6);

      final workout = dao.fromMap({
        'id': 'workout-2',
        'name': 'Leg Day',
        'description': 'Focus on leg exercises',
        'iconCodePoint': 0xe531,
        'colorValue': 0xFF4CAF50,
        'folderId': 'folder-2',
        'notes': 'Stretch well',
        'lastUsed': startedAt.toIso8601String(),
        'orderIndex': 2,
        'status': WorkoutStatus.inProgress.index,
        'templateId': 'template-2',
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'mood': 1,
      });

      expect(workout.id, 'workout-2');
      expect(workout.name, 'Leg Day');
      expect(workout.description, 'Focus on leg exercises');
      expect(workout.iconCodePoint, 0xe531);
      expect(workout.colorValue, 0xFF4CAF50);
      expect(workout.folderId, 'folder-2');
      expect(workout.notes, 'Stretch well');
      expect(workout.lastUsed, startedAt.toIso8601String());
      expect(workout.orderIndex, 2);
      expect(workout.status, WorkoutStatus.inProgress);
      expect(workout.templateId, 'template-2');
      expect(workout.startedAt, startedAt);
      expect(workout.completedAt, completedAt);
      expect(workout.mood, 1);
      expect(workout.exercises, isEmpty);
      expect(
        () => workout.exercises.add(
          WorkoutExercise(workoutId: workout.id, exerciseSlug: 'bench-press'),
        ),
        throwsUnsupportedError,
      );
    });

    test('persists and retrieves workouts by id', () async {
      final workout = _workout(
        id: 'workout-1',
        name: 'Push',
        folderId: 'folder-a',
        orderIndex: 2,
        status: WorkoutStatus.template,
      );

      final insertedId = await dao.insert(workout);
      final retrieved = await dao.getWorkoutById('workout-1');

      expect(insertedId, greaterThan(0));
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'workout-1');
      expect(retrieved.name, 'Push');
      expect(retrieved.folderId, 'folder-a');
      expect(retrieved.orderIndex, 2);
      expect(retrieved.status, WorkoutStatus.template);
      expect(await dao.getWorkoutById('missing-workout'), isNull);
    });

    test('filters workouts by folder id and sorts by order index', () async {
      await dao.insertAll([
        _workout(
          id: 'folder-a-third',
          name: 'Third',
          folderId: 'folder-a',
          orderIndex: 3,
        ),
        _workout(
          id: 'folder-b-only',
          name: 'Other folder',
          folderId: 'folder-b',
          orderIndex: 1,
        ),
        _workout(
          id: 'folder-a-first',
          name: 'First',
          folderId: 'folder-a',
          orderIndex: 1,
        ),
        _workout(
          id: 'folder-a-null-order',
          name: 'Null order',
          folderId: 'folder-a',
        ),
      ]);

      final workouts = await dao.getWorkoutsByFolderId('folder-a');

      expect(
        workouts.map((workout) => workout.id),
        orderedEquals([
          'folder-a-null-order',
          'folder-a-first',
          'folder-a-third',
        ]),
      );
      expect(await dao.getWorkoutsByFolderId('missing-folder'), isEmpty);
    });

    test(
      'filters workouts by status through direct and convenience queries',
      () async {
        await dao.insertAll([
          _workout(
            id: 'template-workout',
            name: 'Template',
            status: WorkoutStatus.template,
          ),
          _workout(
            id: 'in-progress-workout',
            name: 'Session',
            status: WorkoutStatus.inProgress,
          ),
          _workout(
            id: 'completed-workout',
            name: 'History',
            status: WorkoutStatus.completed,
          ),
        ]);

        final templateWorkouts = await dao.getTemplateWorkouts();
        final inProgressWorkouts = await dao.getInProgressWorkouts();
        final completedWorkouts = await dao.getCompletedWorkouts();
        final directCompleted = await dao.getWorkoutsByStatus(
          WorkoutStatus.completed,
        );

        expect(templateWorkouts.map((workout) => workout.id), [
          'template-workout',
        ]);
        expect(inProgressWorkouts.map((workout) => workout.id), [
          'in-progress-workout',
        ]);
        expect(completedWorkouts.map((workout) => workout.id), [
          'completed-workout',
        ]);
        expect(directCompleted.map((workout) => workout.id), [
          'completed-workout',
        ]);
      },
    );

    test('filters workouts by template id', () async {
      await dao.insertAll([
        _workout(id: 'template-root', name: 'Template root'),
        _workout(
          id: 'session-1',
          name: 'Session 1',
          status: WorkoutStatus.inProgress,
          templateId: 'template-root',
        ),
        _workout(
          id: 'session-2',
          name: 'Session 2',
          status: WorkoutStatus.completed,
          templateId: 'template-root',
        ),
        _workout(
          id: 'other-session',
          name: 'Other session',
          status: WorkoutStatus.completed,
          templateId: 'different-template',
        ),
      ]);

      final workouts = await dao.getWorkoutsByTemplateId('template-root');

      expect(
        workouts.map((workout) => workout.id),
        unorderedEquals(['session-1', 'session-2']),
      );
      expect(await dao.getWorkoutsByTemplateId('missing-template'), isEmpty);
    });

    test(
      'returns completed workouts in a date range ordered newest first',
      () async {
        final rangeStart = DateTime.utc(2024, 3, 1);
        final rangeEnd = DateTime.utc(2024, 3, 31, 23, 59, 59);

        await dao.insertAll([
          _workout(
            id: 'boundary-start',
            name: 'Boundary start',
            status: WorkoutStatus.completed,
            startedAt: rangeStart,
            completedAt: rangeStart.add(const Duration(hours: 1)),
          ),
          _workout(
            id: 'middle',
            name: 'Middle',
            status: WorkoutStatus.completed,
            startedAt: DateTime.utc(2024, 3, 15, 8),
            completedAt: DateTime.utc(2024, 3, 15, 9),
          ),
          _workout(
            id: 'boundary-end',
            name: 'Boundary end',
            status: WorkoutStatus.completed,
            startedAt: rangeEnd,
            completedAt: rangeEnd.add(const Duration(hours: 1)),
          ),
          _workout(
            id: 'out-of-range',
            name: 'Too early',
            status: WorkoutStatus.completed,
            startedAt: DateTime.utc(2024, 2, 29, 23, 59, 59),
            completedAt: DateTime.utc(2024, 3, 1),
          ),
          _workout(
            id: 'wrong-status',
            name: 'In progress',
            status: WorkoutStatus.inProgress,
            startedAt: DateTime.utc(2024, 3, 20),
          ),
        ]);

        final workouts = await dao.getWorkoutsInDateRange(rangeStart, rangeEnd);

        expect(
          workouts.map((workout) => workout.id),
          orderedEquals(['boundary-end', 'middle', 'boundary-start']),
        );
        expect(
          workouts.every(
            (workout) => workout.status == WorkoutStatus.completed,
          ),
          isTrue,
        );
      },
    );

    test('updates workouts and deletes only the requested row', () async {
      await dao.insertAll([
        _workout(
          id: 'workout-1',
          name: 'Original',
          notes: 'Old notes',
          orderIndex: 1,
        ),
        _workout(id: 'workout-2', name: 'Keep me', orderIndex: 2),
      ]);

      final updatedCount = await dao.updateWorkout(
        _workout(
          id: 'workout-1',
          name: 'Updated',
          notes: 'New notes',
          orderIndex: 4,
          status: WorkoutStatus.completed,
          startedAt: DateTime.utc(2024, 4, 1, 7),
          completedAt: DateTime.utc(2024, 4, 1, 8),
          mood: 4,
        ),
      );
      final updatedRow = await database.query(
        dao.tableName,
        where: 'id = ?',
        whereArgs: ['workout-1'],
      );
      final deletedCount = await dao.deleteWorkout('workout-1');

      expect(updatedCount, 1);
      expect(updatedRow.single['id'], 'workout-1');
      expect(updatedRow.single['name'], 'Updated');
      expect(updatedRow.single['notes'], 'New notes');
      expect(updatedRow.single['orderIndex'], 4);
      expect(updatedRow.single['status'], WorkoutStatus.completed.index);
      expect(updatedRow.single['mood'], 4);
      expect(deletedCount, 1);
      expect(await dao.getWorkoutById('workout-1'), isNull);
      expect(await dao.getWorkoutById('workout-2'), isNotNull);
      expect(
        await dao.updateWorkout(_workout(id: 'missing', name: 'Missing')),
        0,
      );
      expect(await dao.deleteWorkout('missing'), 0);
    });

    test('rethrows persistence errors for duplicate ids', () async {
      await dao.insert(_workout(id: 'workout-1', name: 'First'));

      await expectLater(
        () => dao.insert(_workout(id: 'workout-1', name: 'Duplicate')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test(
      'rethrows mapping errors when persisted workout data is invalid',
      () async {
        await database.insert(dao.tableName, {
          'id': 'broken-workout',
          'name': 'Broken',
          'status': 99,
        });

        await expectLater(
          () => dao.getAllWorkouts(),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
