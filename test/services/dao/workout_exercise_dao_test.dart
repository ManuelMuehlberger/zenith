import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/models/workout_template.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_template_dao.dart';
import 'package:zenith/services/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  final testDatabaseDirectory = Directory(
    '${Directory.current.path}/.dart_tool/test_databases',
  );

  group('WorkoutExerciseDao', () {
    late DatabaseHelper databaseHelper;
    late WorkoutDao workoutDao;
    late WorkoutTemplateDao workoutTemplateDao;
    late WorkoutExerciseDao dao;

    setUpAll(() async {
      sqfliteFfiInit();
      sqflite.databaseFactory = databaseFactoryFfi;
      await testDatabaseDirectory.create(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
            if (methodCall.method == 'getApplicationDocumentsDirectory') {
              return testDatabaseDirectory.path;
            }
            return testDatabaseDirectory.path;
          });
    });

    tearDownAll(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, null);
      await _deleteDatabaseFiles(testDatabaseDirectory);
    });

    setUp(() async {
      await _deleteDatabaseFiles(testDatabaseDirectory);
      databaseHelper = DatabaseHelper();
      workoutDao = WorkoutDao();
      workoutTemplateDao = WorkoutTemplateDao();
      dao = WorkoutExerciseDao();
    });

    tearDown(() async {
      await _closeDatabaseIfCreated(databaseHelper, testDatabaseDirectory);
      await _deleteDatabaseFiles(testDatabaseDirectory);
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'WorkoutExercise');
    });

    test('should convert workout exercise to map', () {
      final workoutExercise = WorkoutExercise(
        id: 'exercise123',
        workoutId: 'workout123',
        exerciseSlug: 'bench-press',
        notes: 'Use spotter',
        orderIndex: 1,
        sets: [],
      );

      final map = dao.toMap(workoutExercise);

      expect(map['id'], 'exercise123');
      expect(map['workoutId'], 'workout123');
      expect(map['exerciseSlug'], 'bench-press');
      expect(map['notes'], 'Use spotter');
      expect(map['orderIndex'], 1);
    });

    test('should convert map to workout exercise', () {
      final map = {
        'id': 'exercise456',
        'workoutId': 'workout456',
        'exerciseSlug': 'bench-press',
        'notes': 'Keep elbows tucked',
        'orderIndex': 2,
      };

      final workoutExercise = dao.fromMap(map);

      expect(workoutExercise.id, 'exercise456');
      expect(workoutExercise.workoutId, 'workout456');
      expect(workoutExercise.exerciseSlug, 'bench-press');
      expect(workoutExercise.notes, 'Keep elbows tucked');
      expect(workoutExercise.orderIndex, 2);
      expect(workoutExercise.sets, isEmpty);
    });

    test('should handle null values', () {
      final map = {
        'id': 'exercise789',
        'workoutId': 'workout789',
        'exerciseSlug': 'deadlift',
        'notes': null,
        'orderIndex': null,
      };

      final workoutExercise = dao.fromMap(map);

      expect(workoutExercise.id, 'exercise789');
      expect(workoutExercise.workoutId, 'workout789');
      expect(workoutExercise.exerciseSlug, 'deadlift');
      expect(workoutExercise.notes, isNull);
      expect(workoutExercise.orderIndex, isNull);
    });

    test('should return immutable sets collection from model factory', () {
      final workoutExercise = dao.fromMap({
        'id': 'exercise987',
        'workoutId': 'workout987',
        'exerciseSlug': 'press',
      });

      expect(
        () => workoutExercise.sets.add(
          WorkoutSet(workoutExerciseId: workoutExercise.id, setIndex: 0),
        ),
        throwsUnsupportedError,
      );
    });

    test('inserts and looks up workout exercises by id', () async {
      await _insertWorkout(workoutDao, id: 'workout-session');

      final workoutExercise = WorkoutExercise(
        id: 'exercise-session',
        workoutId: 'workout-session',
        exerciseSlug: 'bench-press',
        notes: 'Pause each rep',
        orderIndex: 3,
      );

      await dao.insert(workoutExercise);

      final fetched = await dao.getWorkoutExerciseById(workoutExercise.id);

      expect(fetched, isNotNull);
      expect(fetched!.id, workoutExercise.id);
      expect(fetched.workoutId, 'workout-session');
      expect(fetched.workoutTemplateId, isNull);
      expect(fetched.exerciseSlug, 'bench-press');
      expect(fetched.notes, 'Pause each rep');
      expect(fetched.orderIndex, 3);
      expect(await dao.getWorkoutExerciseById('missing-exercise'), isNull);
    });

    test(
      'looks up workout exercises by workout id in order and handles empty state',
      () async {
        await _insertWorkout(workoutDao, id: 'ordered-workout');

        expect(
          await dao.getWorkoutExercisesByWorkoutId('ordered-workout'),
          isEmpty,
        );

        await dao.insertAll([
          _sessionExercise(
            id: 'exercise-third',
            workoutId: 'ordered-workout',
            exerciseSlug: 'decline-bench-press',
            orderIndex: 3,
          ),
          _sessionExercise(
            id: 'exercise-first',
            workoutId: 'ordered-workout',
            exerciseSlug: 'bench-press',
            orderIndex: 1,
          ),
          _sessionExercise(
            id: 'exercise-second',
            workoutId: 'ordered-workout',
            exerciseSlug: 'incline-bench-press',
            orderIndex: 2,
          ),
        ]);

        final exercises = await dao.getWorkoutExercisesByWorkoutId(
          'ordered-workout',
        );

        expect(
          exercises.map((exercise) => exercise.id).toList(),
          orderedEquals([
            'exercise-first',
            'exercise-second',
            'exercise-third',
          ]),
        );
      },
    );

    test(
      'looks up workout exercises by workout ids with workout and exercise ordering',
      () async {
        expect(await dao.getWorkoutExercisesByWorkoutIds([]), isEmpty);

        await _insertWorkout(workoutDao, id: 'workout-b');
        await _insertWorkout(workoutDao, id: 'workout-a');
        await _insertWorkout(workoutDao, id: 'workout-c');

        await dao.insertAll([
          _sessionExercise(
            id: 'b-second',
            workoutId: 'workout-b',
            exerciseSlug: 'decline-bench-press',
            orderIndex: 2,
          ),
          _sessionExercise(
            id: 'a-first',
            workoutId: 'workout-a',
            exerciseSlug: 'bench-press',
            orderIndex: 1,
          ),
          _sessionExercise(
            id: 'b-first',
            workoutId: 'workout-b',
            exerciseSlug: 'incline-bench-press',
            orderIndex: 1,
          ),
          _sessionExercise(
            id: 'c-first',
            workoutId: 'workout-c',
            exerciseSlug: 'bench-press',
            orderIndex: 1,
          ),
        ]);

        final exercises = await dao.getWorkoutExercisesByWorkoutIds([
          'workout-b',
          'workout-a',
        ]);

        expect(
          exercises.map((exercise) => exercise.id).toList(),
          orderedEquals(['a-first', 'b-first', 'b-second']),
        );
      },
    );

    test('looks up template exercises in order', () async {
      await _insertWorkoutTemplate(workoutTemplateDao, id: 'template-primary');
      await _insertWorkoutTemplate(workoutTemplateDao, id: 'template-other');

      await dao.insertAll([
        _templateExercise(
          id: 'template-third',
          workoutTemplateId: 'template-primary',
          exerciseSlug: 'decline-bench-press',
          orderIndex: 3,
        ),
        _templateExercise(
          id: 'template-first',
          workoutTemplateId: 'template-primary',
          exerciseSlug: 'bench-press',
          orderIndex: 1,
        ),
        _templateExercise(
          id: 'template-other-exercise',
          workoutTemplateId: 'template-other',
          exerciseSlug: 'incline-bench-press',
          orderIndex: 1,
        ),
      ]);

      final exercises = await dao.getWorkoutExercisesByWorkoutTemplateId(
        'template-primary',
      );

      expect(
        exercises.map((exercise) => exercise.id).toList(),
        orderedEquals(['template-first', 'template-third']),
      );
    });

    test(
      'looks up exercises by slug across workout and template rows',
      () async {
        await _insertWorkout(workoutDao, id: 'slug-workout');
        await _insertWorkoutTemplate(workoutTemplateDao, id: 'slug-template');

        await dao.insertAll([
          _sessionExercise(
            id: 'session-match',
            workoutId: 'slug-workout',
            exerciseSlug: 'bench-press',
            orderIndex: 1,
          ),
          _templateExercise(
            id: 'template-match',
            workoutTemplateId: 'slug-template',
            exerciseSlug: 'bench-press',
            orderIndex: 1,
          ),
          _sessionExercise(
            id: 'session-non-match',
            workoutId: 'slug-workout',
            exerciseSlug: 'incline-bench-press',
            orderIndex: 2,
          ),
        ]);

        final matchingExercises = await dao.getWorkoutExercisesByExerciseSlug(
          'bench-press',
        );

        expect(matchingExercises.map((exercise) => exercise.id).toSet(), {
          'session-match',
          'template-match',
        });
        expect(
          await dao.getWorkoutExercisesByExerciseSlug('not-a-real-exercise'),
          isEmpty,
        );
      },
    );

    test('updates and deletes a single workout exercise by id', () async {
      await _insertWorkout(workoutDao, id: 'editable-workout');

      await dao.insert(
        WorkoutExercise(
          id: 'exercise-1',
          workoutId: 'editable-workout',
          exerciseSlug: 'bench-press',
          notes: 'Original note',
          orderIndex: 1,
        ),
      );

      final updatedCount = await dao.updateWorkoutExercise(
        WorkoutExercise(
          id: 'exercise-1',
          workoutId: 'editable-workout',
          exerciseSlug: 'incline-bench-press',
          notes: 'Updated note',
          orderIndex: 2,
        ),
      );
      final updatedExercise = await dao.getWorkoutExerciseById('exercise-1');
      final deletedCount = await dao.deleteWorkoutExercise('exercise-1');

      expect(updatedCount, 1);
      expect(updatedExercise, isNotNull);
      expect(updatedExercise!.exerciseSlug, 'incline-bench-press');
      expect(updatedExercise.notes, 'Updated note');
      expect(updatedExercise.orderIndex, 2);
      expect(deletedCount, 1);
      expect(await dao.getWorkoutExerciseById('exercise-1'), isNull);
      expect(await dao.deleteWorkoutExercise('missing-exercise'), 0);
    });

    test('deletes workout exercises by workout id only', () async {
      await _insertWorkout(workoutDao, id: 'delete-workout-a');
      await _insertWorkout(workoutDao, id: 'delete-workout-b');

      await dao.insertAll([
        _sessionExercise(
          id: 'exercise-a1',
          workoutId: 'delete-workout-a',
          exerciseSlug: 'bench-press',
          orderIndex: 1,
        ),
        _sessionExercise(
          id: 'exercise-a2',
          workoutId: 'delete-workout-a',
          exerciseSlug: 'row',
          orderIndex: 2,
        ),
        _sessionExercise(
          id: 'exercise-b1',
          workoutId: 'delete-workout-b',
          exerciseSlug: 'squat',
          orderIndex: 1,
        ),
      ]);

      final deletedCount = await dao.deleteWorkoutExercisesByWorkoutId(
        'delete-workout-a',
      );

      expect(deletedCount, 2);
      expect(
        await dao.getWorkoutExercisesByWorkoutId('delete-workout-a'),
        isEmpty,
      );
      expect(
        (await dao.getWorkoutExercisesByWorkoutId(
          'delete-workout-b',
        )).map((exercise) => exercise.id).toList(),
        ['exercise-b1'],
      );
      expect(await dao.deleteWorkoutExercisesByWorkoutId('missing-workout'), 0);
    });

    test('deletes workout exercises by workout template id only', () async {
      await _insertWorkoutTemplate(workoutTemplateDao, id: 'delete-template-a');
      await _insertWorkoutTemplate(workoutTemplateDao, id: 'delete-template-b');

      await dao.insertAll([
        _templateExercise(
          id: 'template-a1',
          workoutTemplateId: 'delete-template-a',
          exerciseSlug: 'bench-press',
          orderIndex: 1,
        ),
        _templateExercise(
          id: 'template-a2',
          workoutTemplateId: 'delete-template-a',
          exerciseSlug: 'row',
          orderIndex: 2,
        ),
        _templateExercise(
          id: 'template-b1',
          workoutTemplateId: 'delete-template-b',
          exerciseSlug: 'squat',
          orderIndex: 1,
        ),
      ]);

      final deletedCount = await dao.deleteWorkoutExercisesByWorkoutTemplateId(
        'delete-template-a',
      );

      expect(deletedCount, 2);
      expect(
        await dao.getWorkoutExercisesByWorkoutTemplateId('delete-template-a'),
        isEmpty,
      );
      expect(
        (await dao.getWorkoutExercisesByWorkoutTemplateId(
          'delete-template-b',
        )).map((exercise) => exercise.id).toList(),
        ['template-b1'],
      );
      expect(
        await dao.deleteWorkoutExercisesByWorkoutTemplateId('missing-template'),
        0,
      );
    });

    test(
      'returns an empty frequency map when the frequency query fails',
      () async {
        await _closeDatabaseIfCreated(databaseHelper, testDatabaseDirectory);

        final frequency = await dao.getExerciseFrequency();

        expect(frequency, isEmpty);
      },
    );

    test('gets exercise frequency from completed workouts only', () async {
      expect(await dao.getExerciseFrequency(), isEmpty);

      await _insertWorkout(
        workoutDao,
        id: 'completed-workout',
        status: WorkoutStatus.completed,
      );
      await _insertWorkout(
        workoutDao,
        id: 'in-progress-workout',
        status: WorkoutStatus.inProgress,
      );

      await dao.insertAll([
        _sessionExercise(
          id: 'completed-bench-1',
          workoutId: 'completed-workout',
          exerciseSlug: 'bench-press',
          orderIndex: 1,
        ),
        _sessionExercise(
          id: 'completed-bench-2',
          workoutId: 'completed-workout',
          exerciseSlug: 'bench-press',
          orderIndex: 2,
        ),
        _sessionExercise(
          id: 'completed-incline',
          workoutId: 'completed-workout',
          exerciseSlug: 'incline-bench-press',
          orderIndex: 3,
        ),
        _sessionExercise(
          id: 'in-progress-bench',
          workoutId: 'in-progress-workout',
          exerciseSlug: 'bench-press',
          orderIndex: 1,
        ),
      ]);

      final frequency = await dao.getExerciseFrequency();

      expect(frequency, equals({'bench-press': 2, 'incline-bench-press': 1}));
    });
  });
}

Future<void> _insertWorkout(
  WorkoutDao workoutDao, {
  required String id,
  WorkoutStatus status = WorkoutStatus.template,
}) async {
  await workoutDao.insert(Workout(id: id, name: 'Workout $id', status: status));
}

Future<void> _insertWorkoutTemplate(
  WorkoutTemplateDao workoutTemplateDao, {
  required String id,
}) async {
  await workoutTemplateDao.insert(
    WorkoutTemplate(id: id, name: 'Template $id'),
  );
}

WorkoutExercise _sessionExercise({
  required String id,
  required String workoutId,
  required String exerciseSlug,
  int? orderIndex,
}) {
  return WorkoutExercise(
    id: id,
    workoutId: workoutId,
    exerciseSlug: exerciseSlug,
    orderIndex: orderIndex,
  );
}

WorkoutExercise _templateExercise({
  required String id,
  required String workoutTemplateId,
  required String exerciseSlug,
  int? orderIndex,
}) {
  return WorkoutExercise(
    id: id,
    workoutTemplateId: workoutTemplateId,
    exerciseSlug: exerciseSlug,
    orderIndex: orderIndex,
  );
}

Future<void> _closeDatabaseIfCreated(
  DatabaseHelper databaseHelper,
  Directory testDatabaseDirectory,
) async {
  final databaseFile = File('${testDatabaseDirectory.path}/workout_tracker.db');
  if (await databaseFile.exists()) {
    await databaseHelper.close();
  }
}

Future<void> _deleteDatabaseFiles(Directory testDatabaseDirectory) async {
  const suffixes = ['', '-wal', '-shm', '-journal'];
  for (final suffix in suffixes) {
    final file = File(
      '${testDatabaseDirectory.path}/workout_tracker.db$suffix',
    );
    if (await file.exists()) {
      await file.delete();
    }
  }
}
