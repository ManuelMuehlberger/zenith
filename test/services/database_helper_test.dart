import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/database_helper.dart';

const _assetKey = 'assets/gym_exercises_complete.toml';
const _databaseName = 'workout_tracker.db';
const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

const _seedToml = '''
[exercise_001_bench_press]
name = "Bench Press"
slug = "bench-press"
primary_muscle_group = "Chest"
secondary_muscle_groups = ["Triceps"]
instructions = ["Lie on bench", "Press bar"]
equipment = "Barbell"
bodyweight = false
image = "bench.png"
animation = "bench.gif"

[exercise_002_push_up]
name = "Push Up"
slug = "push-up"
primary_muscle_group = "Chest"
secondary_muscle_groups = ["Triceps", "Shoulders"]
instructions = ["Get into plank", "Push"]
equipment = "None"
bodyweight = true
image = ""
animation = ""

[exercise_003_plank]
name = "Plank"
slug = "plank"
primary_muscle_group = "Core"
secondary_muscle_groups = ["Abs"]
instructions = ["Brace core"]
equipment = "None"
bodyweight = 1
image = ""
animation = ""

[exercise_004_missing_primary]
name = "Missing Primary"
slug = "missing-primary"
primary_muscle_group = ""
secondary_muscle_groups = []
instructions = ["Skip me"]
equipment = "None"
bodyweight = false
image = ""
animation = ""

[exercise_005_invalid_primary]
name = "Invalid Primary"
slug = "invalid-primary"
primary_muscle_group = "Mystery"
secondary_muscle_groups = []
instructions = ["Skip me too"]
equipment = "Cable"
bodyweight = false
image = ""
animation = ""
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper databaseHelper;
  late String databasePath;
  late Directory testDirectory;
  late DatabaseFactory? originalDatabaseFactory;
  var helperOpened = false;

  Future<void> stubAsset(String content) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (
      ByteData? message,
    ) async {
      if (message == null) {
        return null;
      }

      final key = utf8.decode(
        message.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      if (key != _assetKey) {
        return null;
      }

      final bytes = Uint8List.fromList(utf8.encode(content));
      return ByteData.sublistView(bytes);
    });
  }

  Future<List<String>> tableNames(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    return rows
        .map((row) => row['name'] as String)
        .where((name) => !name.startsWith('sqlite_'))
        .toList();
  }

  Future<List<String>> columnNames(Database db, String tableName) async {
    final rows = await db.rawQuery('PRAGMA table_info($tableName)');
    return rows.map((row) => row['name'] as String).toList();
  }

  Future<Database> openHelperDatabase() async {
    final db = await databaseHelper.database;
    helperOpened = true;
    return db;
  }

  Future<void> createVersion1Database(String path) async {
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE WorkoutFolder (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              orderIndex INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE Workout (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              iconCodePoint INTEGER,
              colorValue INTEGER,
              folderId TEXT,
              notes TEXT,
              lastUsed TEXT,
              orderIndex INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE WorkoutExercise (
              id TEXT PRIMARY KEY,
              workoutId TEXT NOT NULL,
              exerciseSlug TEXT NOT NULL,
              notes TEXT,
              orderIndex INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE WorkoutSet (
              id TEXT PRIMARY KEY,
              workoutExerciseId TEXT NOT NULL,
              setIndex INTEGER NOT NULL,
              targetReps INTEGER,
              targetWeight REAL,
              targetRestSeconds INTEGER
            )
          ''');

          await db.insert('Workout', {'id': 'workout-1', 'name': 'Legacy'});
          await db.insert('WorkoutExercise', {
            'id': 'exercise-1',
            'workoutId': 'workout-1',
            'exerciseSlug': 'legacy-exercise',
          });
          await db.insert('WorkoutSet', {
            'id': 'set-1',
            'workoutExerciseId': 'exercise-1',
            'setIndex': 0,
            'targetReps': 10,
          });
        },
      ),
    );
    await db.close();
  }

  Future<void> createVersion2PartiallyMigratedDatabase(String path) async {
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE MuscleGroup (
              name TEXT PRIMARY KEY
            )
          ''');
          await db.insert('MuscleGroup', {'name': 'Chest'});

          await db.execute('''
            CREATE TABLE Exercise (
              slug TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              primaryMuscleGroup TEXT NOT NULL,
              secondaryMuscleGroups TEXT,
              instructions TEXT,
              equipment TEXT,
              image TEXT,
              animation TEXT,
              isBodyWeightExercise INTEGER DEFAULT 0
            )
          ''');
          await db.insert('Exercise', {
            'slug': 'legacy-exercise',
            'name': 'Legacy Exercise',
            'primaryMuscleGroup': 'Chest',
            'secondaryMuscleGroups': '[]',
            'instructions': '[]',
            'equipment': 'Legacy',
            'image': '',
            'animation': '',
            'isBodyWeightExercise': 0,
          });

          await db.execute('''
            CREATE TABLE UserData (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              birthdate TEXT NOT NULL,
              gender TEXT NOT NULL DEFAULT 'ratherNotSay',
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
              value REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE WorkoutFolder (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              orderIndex INTEGER
            )
          ''');
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
              status INTEGER DEFAULT 0,
              templateId TEXT,
              startedAt TEXT,
              completedAt TEXT,
              mood INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE WorkoutExercise (
              id TEXT PRIMARY KEY,
              workoutTemplateId TEXT,
              workoutId TEXT,
              exerciseSlug TEXT NOT NULL,
              notes TEXT,
              orderIndex INTEGER
            )
          ''');
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
    await db.close();
  }

  setUpAll(() async {
    sqfliteFfiInit();
    originalDatabaseFactory = databaseFactoryOrNull;
    databaseFactory = databaseFactoryFfi;

    testDirectory = Directory(
      '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
      '${Platform.pathSeparator}database_helper_test',
    );
    if (!await testDirectory.exists()) {
      await testDirectory.create(recursive: true);
    }
  });

  tearDownAll(() async {
    databaseFactoryOrNull = originalDatabaseFactory;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', null);
    messenger.setMockMethodCallHandler(_pathProviderChannel, null);
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  setUp(() async {
    helperOpened = false;
    databaseHelper = DatabaseHelper();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return testDirectory.path;
          }
          return null;
        });
    databasePath =
        '${testDirectory.path}${Platform.pathSeparator}$_databaseName';
    await databaseFactory.deleteDatabase(databasePath);
    await stubAsset(_seedToml);
  });

  tearDown(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', null);
    messenger.setMockMethodCallHandler(_pathProviderChannel, null);
    if (helperOpened) {
      await databaseHelper.close();
    }
    await databaseFactory.deleteDatabase(databasePath);
  });

  group('DatabaseHelper', () {
    test('databasePath uses the application documents directory', () async {
      expect(await databaseHelper.databasePath, databasePath);
    });

    test(
      'bootstraps schema, seeds exercises, and reuses the database instance',
      () async {
        final db = await openHelperDatabase();
        final cachedDb = await databaseHelper.database;

        expect(identical(db, cachedDb), isTrue);

        expect(
          await tableNames(db),
          containsAll(<String>[
            'Exercise',
            'MuscleGroup',
            'UserData',
            'WeightEntry',
            'Workout',
            'WorkoutExercise',
            'WorkoutFolder',
            'WorkoutSet',
            'WorkoutTemplate',
          ]),
        );
        expect(await columnNames(db, 'UserData'), contains('gender'));

        final seededExercises = await db.query('Exercise', orderBy: 'slug ASC');
        expect(seededExercises.map((row) => row['slug']), [
          'bench-press',
          'plank',
          'push-up',
        ]);

        final plank = seededExercises.firstWhere(
          (row) => row['slug'] == 'plank',
        );
        expect(plank['isBodyWeightExercise'], 1);
        expect(
          jsonDecode(plank['instructions'] as String),
          equals(['Brace core']),
        );

        final muscleGroups = await db.query('MuscleGroup');
        expect(muscleGroups, hasLength(MuscleGroup.values.length));
      },
    );

    test(
      'close resets the singleton connection so the database can reopen',
      () async {
        final firstOpen = await openHelperDatabase();

        await databaseHelper.close();
        helperOpened = false;

        final secondOpen = await openHelperDatabase();

        expect(identical(firstOpen, secondOpen), isFalse);
        expect(await secondOpen.query('Exercise'), hasLength(3));
      },
    );

    test('upgrades a version 1 database to the latest schema', () async {
      await createVersion1Database(databasePath);

      final db = await openHelperDatabase();

      expect(
        await columnNames(db, 'Workout'),
        containsAll([
          'description',
          'status',
          'templateId',
          'startedAt',
          'completedAt',
          'mood',
        ]),
      );
      expect(
        await columnNames(db, 'WorkoutSet'),
        containsAll(['actualReps', 'actualWeight', 'isCompleted']),
      );
      expect(
        await tableNames(db),
        containsAll(<String>[
          'Exercise',
          'MuscleGroup',
          'UserData',
          'WeightEntry',
          'WorkoutTemplate',
        ]),
      );
      expect(await columnNames(db, 'UserData'), contains('gender'));

      final workoutSet = await db.query(
        'WorkoutSet',
        where: 'id = ?',
        whereArgs: ['set-1'],
      );
      expect(workoutSet.single['isCompleted'], 0);
      expect(await db.query('Exercise'), hasLength(3));
    });

    test('upgrades tolerate partially applied legacy migrations', () async {
      await createVersion2PartiallyMigratedDatabase(databasePath);

      final db = await openHelperDatabase();

      expect(await columnNames(db, 'Workout'), contains('description'));
      expect(await columnNames(db, 'Workout'), contains('mood'));
      expect(await columnNames(db, 'UserData'), contains('gender'));
      expect(
        await columnNames(db, 'WorkoutExercise'),
        contains('workoutTemplateId'),
      );
      expect(await tableNames(db), contains('WorkoutTemplate'));

      final exercises = await db.query('Exercise', orderBy: 'slug ASC');
      expect(exercises.map((row) => row['slug']), [
        'bench-press',
        'plank',
        'push-up',
      ]);
      expect(exercises.any((row) => row['slug'] == 'legacy-exercise'), isFalse);
    });

    test(
      'rethrows bootstrap failures and can recover on a later attempt',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
              throw PlatformException(
                code: 'path-error',
                message: 'documents directory unavailable',
              );
            });

        await expectLater(databaseHelper.database, throwsException);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
              if (methodCall.method == 'getApplicationDocumentsDirectory') {
                return testDirectory.path;
              }
              return null;
            });
        final db = await openHelperDatabase();

        expect(await db.query('Exercise'), hasLength(3));
      },
    );
  });
}
