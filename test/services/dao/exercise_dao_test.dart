import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/dao/exercise_dao.dart';

class TestExerciseDao extends ExerciseDao {
  TestExerciseDao(this._database);

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
      },
    ),
  );
}

Exercise _exercise({
  required String slug,
  required String name,
  required MuscleGroup primaryMuscleGroup,
  List<MuscleGroup> secondaryMuscleGroups = const [],
  List<String> instructions = const [],
  String equipment = '',
  String image = '',
  String animation = '',
  bool isBodyWeightExercise = false,
}) {
  return Exercise(
    slug: slug,
    name: name,
    primaryMuscleGroup: primaryMuscleGroup,
    secondaryMuscleGroups: secondaryMuscleGroups,
    instructions: instructions,
    equipment: equipment,
    image: image,
    animation: animation,
    isBodyWeightExercise: isBodyWeightExercise,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  group('ExerciseDao', () {
    late Database database;
    late TestExerciseDao dao;

    setUp(() async {
      database = await _openTestDatabase();
      dao = TestExerciseDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should have correct table name', () {
      expect(dao.tableName, 'Exercise');
    });

    test('serializes exercises to database values', () {
      final exercise = _exercise(
        slug: 'bench-press',
        name: 'Bench Press',
        primaryMuscleGroup: MuscleGroup.chest,
        secondaryMuscleGroups: [MuscleGroup.triceps, MuscleGroup.shoulders],
        instructions: ['Lie on bench', 'Press barbell'],
        equipment: 'Barbell',
        image: 'bench_press.jpg',
        animation: 'bench_press.gif',
        isBodyWeightExercise: false,
      );

      final map = dao.toMap(exercise);

      expect(map, {
        'slug': 'bench-press',
        'name': 'Bench Press',
        'primaryMuscleGroup': 'Chest',
        'secondaryMuscleGroups': '["Triceps","Shoulders"]',
        'instructions': '["Lie on bench","Press barbell"]',
        'equipment': 'Barbell',
        'image': 'bench_press.jpg',
        'animation': 'bench_press.gif',
        'isBodyWeightExercise': 0,
      });
    });

    test('deserializes compatible persisted values into immutable models', () {
      final exercise = dao.fromMap({
        'slug': 'single-leg-squat',
        'name': 'Single Leg Squat',
        'primary_muscle_group': 'Quads',
        'secondary_muscle_groups': ['Glutes', 'Core'],
        'instructions': ['Balance on one leg', 'Lower under control'],
        'equipment': null,
        'image': null,
        'animation': null,
        'bodyweight': '1',
      });

      expect(exercise.slug, 'single-leg-squat');
      expect(exercise.name, 'Single Leg Squat');
      expect(exercise.primaryMuscleGroup, MuscleGroup.quads);
      expect(exercise.secondaryMuscleGroups, [
        MuscleGroup.glutes,
        MuscleGroup.core,
      ]);
      expect(exercise.instructions, [
        'Balance on one leg',
        'Lower under control',
      ]);
      expect(exercise.equipment, '');
      expect(exercise.image, '');
      expect(exercise.animation, '');
      expect(exercise.isBodyWeightExercise, isTrue);
      expect(
        () => exercise.secondaryMuscleGroups.add(MuscleGroup.hamstrings),
        throwsUnsupportedError,
      );
      expect(
        () => exercise.instructions.add('Drive back up'),
        throwsUnsupportedError,
      );
    });

    test('persists and looks up exercises by slug', () async {
      await dao.insert(
        _exercise(
          slug: 'deadlift',
          name: 'Deadlift',
          primaryMuscleGroup: MuscleGroup.hamstrings,
          secondaryMuscleGroups: [MuscleGroup.glutes, MuscleGroup.lowerBack],
          instructions: ['Brace', 'Drive through the floor'],
          equipment: 'Barbell',
        ),
      );

      final exercise = await dao.getExerciseBySlug('deadlift');

      expect(exercise, isNotNull);
      expect(exercise!.slug, 'deadlift');
      expect(exercise.name, 'Deadlift');
      expect(exercise.primaryMuscleGroup, MuscleGroup.hamstrings);
      expect(exercise.secondaryMuscleGroups, [
        MuscleGroup.glutes,
        MuscleGroup.lowerBack,
      ]);
      expect(exercise.instructions, ['Brace', 'Drive through the floor']);
      expect(exercise.equipment, 'Barbell');
      expect(await dao.getExerciseBySlug('missing-exercise'), isNull);
    });

    test('gets all exercises and keeps mapped values intact', () async {
      await dao.insertAll([
        _exercise(
          slug: 'bench-press',
          name: 'Bench Press',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [MuscleGroup.triceps],
          instructions: ['Unrack', 'Press'],
        ),
        _exercise(
          slug: 'pull-up',
          name: 'Pull Up',
          primaryMuscleGroup: MuscleGroup.lats,
          secondaryMuscleGroups: [MuscleGroup.biceps],
          instructions: ['Hang', 'Pull'],
          isBodyWeightExercise: true,
        ),
      ]);

      final exercises = await dao.getAllExercises();

      expect(exercises.map((exercise) => exercise.slug), [
        'bench-press',
        'pull-up',
      ]);
      expect(exercises[0].secondaryMuscleGroups, [MuscleGroup.triceps]);
      expect(exercises[1].isBodyWeightExercise, isTrue);
    });

    test(
      'filters exercises by primary muscle group and returns empty when absent',
      () async {
        await dao.insertAll([
          _exercise(
            slug: 'bench-press',
            name: 'Bench Press',
            primaryMuscleGroup: MuscleGroup.chest,
          ),
          _exercise(
            slug: 'push-up',
            name: 'Push Up',
            primaryMuscleGroup: MuscleGroup.chest,
            isBodyWeightExercise: true,
          ),
          _exercise(
            slug: 'barbell-row',
            name: 'Barbell Row',
            primaryMuscleGroup: MuscleGroup.back,
          ),
        ]);

        final chestExercises = await dao.getExercisesByPrimaryMuscleGroup(
          'Chest',
        );

        expect(chestExercises.map((exercise) => exercise.slug), [
          'bench-press',
          'push-up',
        ]);
        expect(await dao.getExercisesByPrimaryMuscleGroup('Calves'), isEmpty);
      },
    );

    test(
      'filters exercises by secondary muscle group and returns empty when absent',
      () async {
        await dao.insertAll([
          _exercise(
            slug: 'bench-press',
            name: 'Bench Press',
            primaryMuscleGroup: MuscleGroup.chest,
            secondaryMuscleGroups: [MuscleGroup.triceps, MuscleGroup.shoulders],
          ),
          _exercise(
            slug: 'dips',
            name: 'Dips',
            primaryMuscleGroup: MuscleGroup.chest,
            secondaryMuscleGroups: [MuscleGroup.triceps],
          ),
          _exercise(
            slug: 'squat',
            name: 'Squat',
            primaryMuscleGroup: MuscleGroup.quads,
            secondaryMuscleGroups: [MuscleGroup.glutes],
          ),
        ]);

        final tricepsExercises = await dao.getExercisesBySecondaryMuscleGroup(
          'Triceps',
        );

        expect(tricepsExercises.map((exercise) => exercise.slug), [
          'bench-press',
          'dips',
        ]);
        expect(await dao.getExercisesBySecondaryMuscleGroup('Calves'), isEmpty);
      },
    );

    test(
      'searches exercises by partial name and returns empty when absent',
      () async {
        await dao.insertAll([
          _exercise(
            slug: 'bench-press',
            name: 'Bench Press',
            primaryMuscleGroup: MuscleGroup.chest,
          ),
          _exercise(
            slug: 'incline-bench-press',
            name: 'Incline Bench Press',
            primaryMuscleGroup: MuscleGroup.chest,
          ),
          _exercise(
            slug: 'pull-up',
            name: 'Pull Up',
            primaryMuscleGroup: MuscleGroup.lats,
          ),
        ]);

        final benchExercises = await dao.searchExercisesByName('Bench');

        expect(benchExercises.map((exercise) => exercise.slug), [
          'bench-press',
          'incline-bench-press',
        ]);
        expect(await dao.searchExercisesByName('Curl'), isEmpty);
      },
    );

    test(
      'rethrows mapping errors when persisted exercise data is invalid',
      () async {
        await database.insert(dao.tableName, {
          'slug': 'broken-exercise',
          'name': 'Broken Exercise',
          'primaryMuscleGroup': 'Chest',
          'secondaryMuscleGroups': '["Triceps"]',
          'instructions': '{"step":"not-a-list"}',
          'equipment': 'Band',
          'image': '',
          'animation': '',
          'isBodyWeightExercise': 0,
        });

        await expectLater(
          () => dao.getAllExercises(),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
