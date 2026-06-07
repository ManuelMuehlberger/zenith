import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenith/models/workout_achievement.dart';
import 'package:zenith/services/dao/workout_achievement_dao.dart';

class TestWorkoutAchievementDao extends WorkoutAchievementDao {
  TestWorkoutAchievementDao(this._database);

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
          CREATE TABLE WorkoutAchievement (
            id TEXT PRIMARY KEY,
            workoutId TEXT NOT NULL,
            ruleId TEXT NOT NULL,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            reason TEXT NOT NULL,
            earnedAt TEXT NOT NULL,
            metricsJson TEXT NOT NULL
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

  group('WorkoutAchievementDao', () {
    late Database database;
    late TestWorkoutAchievementDao dao;

    setUp(() async {
      database = await _openTestDatabase();
      dao = TestWorkoutAchievementDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('replaces and fetches achievements for a workout', () async {
      final earnedAt = DateTime.utc(2026, 1, 1);
      final achievement = WorkoutAchievement(
        id: 'achievement-1',
        workoutId: 'workout-1',
        ruleId: 'first_workout',
        type: WorkoutAchievementType.firstWorkout,
        title: 'First Workout',
        reason: 'Completed your first workout.',
        earnedAt: earnedAt,
      );

      await dao.replaceAchievementsForWorkout('workout-1', [achievement]);
      await dao.replaceAchievementsForWorkout('workout-1', [achievement]);

      final fetched = await dao.getAchievementsByWorkoutId('workout-1');

      expect(fetched, hasLength(1));
      expect(fetched.single.id, 'achievement-1');
      expect(fetched.single.type, WorkoutAchievementType.firstWorkout);
    });

    test('batch fetch groups achievements by workout id', () async {
      final earnedAt = DateTime.utc(2026, 1, 1);
      await dao.insert(
        WorkoutAchievement(
          id: 'achievement-1',
          workoutId: 'workout-1',
          ruleId: 'first_workout',
          type: WorkoutAchievementType.firstWorkout,
          title: 'First Workout',
          reason: 'First one.',
          earnedAt: earnedAt,
        ),
      );
      await dao.insert(
        WorkoutAchievement(
          id: 'achievement-2',
          workoutId: 'workout-2',
          ruleId: 'high_volume',
          type: WorkoutAchievementType.highVolume,
          title: 'High Volume',
          reason: 'Lots of sets.',
          earnedAt: earnedAt,
        ),
      );

      final grouped = await dao.getAchievementsByWorkoutIds([
        'workout-1',
        'workout-2',
      ]);

      expect(grouped['workout-1'], hasLength(1));
      expect(grouped['workout-2'], hasLength(1));
      expect(grouped['workout-2']!.single.ruleId, 'high_volume');
    });
  });
}
