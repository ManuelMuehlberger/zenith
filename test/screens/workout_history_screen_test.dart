import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_achievement.dart';
import 'package:zenith/screens/workout_history_screen.dart';
import 'package:zenith/services/dao/workout_achievement_dao.dart';
import 'package:zenith/services/workout_service.dart';
import 'package:zenith/widgets/timeline/award_balloons.dart';

import '../services/workout_service_test.mocks.dart';

class FakeWorkoutAchievementDao extends WorkoutAchievementDao {
  FakeWorkoutAchievementDao(this.achievementsByWorkoutId);

  final Map<String, List<WorkoutAchievement>> achievementsByWorkoutId;

  @override
  Future<Map<String, List<WorkoutAchievement>>> getAchievementsByWorkoutIds(
    List<String> workoutIds,
  ) async {
    return {
      for (final id in workoutIds)
        if (achievementsByWorkoutId[id] != null)
          id: achievementsByWorkoutId[id]!,
    };
  }
}

void main() {
  testWidgets(
    'collapsed month row shows monthly awards and opens award sheet',
    (tester) async {
      final workoutService = WorkoutService.instance;
      final workoutDao = MockWorkoutDao();
      final workoutExerciseDao = MockWorkoutExerciseDao();
      final workoutSetDao = MockWorkoutSetDao();
      final completedAt = DateTime(2026, 6, 2, 18);
      final workout = Workout(
        id: 'workout-1',
        name: 'Awarded Session',
        status: WorkoutStatus.completed,
        startedAt: completedAt.subtract(const Duration(hours: 1)),
        completedAt: completedAt,
      );
      final achievements = List.generate(
        5,
        (index) => WorkoutAchievement(
          id: 'achievement-$index',
          workoutId: workout.id,
          ruleId: 'rule-$index',
          type: WorkoutAchievementType.highVolume,
          title: 'Award $index',
          reason: 'Reason $index',
          earnedAt: completedAt,
        ),
      );

      workoutService.workouts.clear();
      workoutService.workoutDao = workoutDao;
      workoutService.workoutAchievementDao = FakeWorkoutAchievementDao({
        workout.id: achievements,
      });
      workoutService.workoutExerciseDao = workoutExerciseDao;
      workoutService.workoutSetDao = workoutSetDao;

      when(workoutDao.getAllWorkouts()).thenAnswer((_) async => [workout]);
      when(
        workoutExerciseDao.getWorkoutExercisesByWorkoutIds(any),
      ).thenAnswer((_) async => []);
      when(
        workoutSetDao.getWorkoutSetsByWorkoutExerciseIds(any),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: const WorkoutHistoryScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('June 2026'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.byType(AwardBalloons), findsOneWidget);

      await tester.tap(find.byType(AwardBalloons));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Award 0'), findsOneWidget);
      expect(find.text('Reason 0'), findsOneWidget);
    },
  );
}
