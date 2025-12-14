import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:zenith/services/insights_service.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/exercise_service.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';

@GenerateMocks([])
void main() {
  group('WeeklyInsights', () {
    late InsightsService service;
    late ExerciseService exerciseService;

    setUp(() {
      service = InsightsService.instance;
      service.reset();
      exerciseService = ExerciseService.instance;
      exerciseService.resetForTesting();
    });

    tearDown(() {
      service.reset();
      exerciseService.resetForTesting();
    });

    test('WeeklyDataPoint serialization and deserialization', () {
      final weekStart = DateTime(2025, 1, 6); // Monday
      final dataPoint = WeeklyDataPoint(
        weekStart: weekStart,
        minValue: 10.0,
        maxValue: 50.0,
      );

      final map = dataPoint.toMap();
      expect(map['weekStart'], weekStart.millisecondsSinceEpoch);
      expect(map['minValue'], 10.0);
      expect(map['maxValue'], 50.0);

      final restored = WeeklyDataPoint.fromMap(map);
      expect(restored.weekStart, weekStart);
      expect(restored.minValue, 10.0);
      expect(restored.maxValue, 50.0);
    });

    test('WeeklyInsights serialization and deserialization', () {
      final weekStart = DateTime(2025, 1, 6);
      final insights = WeeklyInsights(
        weeklyWorkoutCounts: [
          WeeklyDataPoint(weekStart: weekStart, minValue: 0, maxValue: 3),
        ],
        weeklyDurations: [
          WeeklyDataPoint(weekStart: weekStart, minValue: 30, maxValue: 60),
        ],
        weeklyVolumes: [
          WeeklyDataPoint(weekStart: weekStart, minValue: 20, maxValue: 40),
        ],
        averageWorkoutsPerWeek: 3.0,
        averageDuration: 45.0,
        averageVolume: 30.0,
        lastUpdated: DateTime(2025, 1, 10),
      );

      final map = insights.toMap();
      expect(map['averageWorkoutsPerWeek'], 3.0);
      expect(map['averageDuration'], 45.0);
      expect(map['averageVolume'], 30.0);

      final restored = WeeklyInsights.fromMap(map);
      expect(restored.weeklyWorkoutCounts.length, 1);
      expect(restored.weeklyDurations.length, 1);
      expect(restored.weeklyVolumes.length, 1);
      expect(restored.averageWorkoutsPerWeek, 3.0);
      expect(restored.averageDuration, 45.0);
      expect(restored.averageVolume, 30.0);
    });

    test('getWeeklyInsights returns empty insights when no workouts', () async {
      service.setWorkoutsProvider(() async => []);

      final insights = await service.getWeeklyInsights(monthsBack: 6);

      expect(insights.weeklyWorkoutCounts, isEmpty);
      expect(insights.weeklyDurations, isEmpty);
      expect(insights.weeklyVolumes, isEmpty);
      expect(insights.averageWorkoutsPerWeek, 0);
      expect(insights.averageDuration, 0);
      expect(insights.averageVolume, 0);
    });

    test('getWeeklyInsights calculates workout counts correctly for 6 months', () async {
      final now = DateTime(2025, 1, 10, 12, 0); // Friday
      final workouts = [
        // This week: 2 workouts
        _createWorkout(now.subtract(const Duration(days: 1)), 60, 20), // Thursday
        _createWorkout(now.subtract(const Duration(days: 3)), 45, 15), // Tuesday
        // Last week: 3 workouts
        _createWorkout(now.subtract(const Duration(days: 7)), 50, 25), // Last Friday
        _createWorkout(now.subtract(const Duration(days: 9)), 40, 18), // Last Wednesday
        _createWorkout(now.subtract(const Duration(days: 10)), 55, 22), // Last Tuesday
        // 2 weeks ago: 1 workout
        _createWorkout(now.subtract(const Duration(days: 14)), 35, 12), // 2 weeks ago Friday
      ];

      service.setWorkoutsProvider(() async => workouts);

      final insights = await service.getWeeklyInsights(monthsBack: 6);

      expect(insights.weeklyWorkoutCounts.length, 26); // 6 months = 26 weeks
      
      // This week (most recent)
      expect(insights.weeklyWorkoutCounts[25].maxValue, 2);
      // Last week
      expect(insights.weeklyWorkoutCounts[24].maxValue, 3);
      // 2 weeks ago
      expect(insights.weeklyWorkoutCounts[23].maxValue, 1);
      // Older weeks should be 0
      expect(insights.weeklyWorkoutCounts[22].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[21].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[20].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[19].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[0].maxValue, 0);
    });

    test('getWeeklyInsights calculates duration ranges correctly', () async {
      final now = DateTime(2025, 1, 10, 12, 0);
      final workouts = [
        _createWorkout(now.subtract(const Duration(days: 1)), 60, 20), // 60 min
        _createWorkout(now.subtract(const Duration(days: 2)), 45, 15), // 45 min
        _createWorkout(now.subtract(const Duration(days: 3)), 90, 25), // 90 min
      ];

      service.setWorkoutsProvider(() async => workouts);

      final insights = await service.getWeeklyInsights(monthsBack: 6);

      // This week should have min=45, max=90 (last index for 26 weeks)
      final thisWeek = insights.weeklyDurations[25];
      expect(thisWeek.minValue, 45);
      expect(thisWeek.maxValue, 90);
    });

    test('getWeeklyInsights calculates volume ranges correctly', () async {
      final now = DateTime(2025, 1, 10, 12, 0);
      final workouts = [
        _createWorkout(now.subtract(const Duration(days: 1)), 60, 20), // 20 sets
        _createWorkout(now.subtract(const Duration(days: 2)), 45, 15), // 15 sets
        _createWorkout(now.subtract(const Duration(days: 3)), 90, 30), // 30 sets
      ];

      service.setWorkoutsProvider(() async => workouts);

      final insights = await service.getWeeklyInsights(monthsBack: 6);

      // This week should have min=15, max=30 (last index for 26 weeks)
      final thisWeek = insights.weeklyVolumes[25];
      expect(thisWeek.minValue, 15);
      expect(thisWeek.maxValue, 30);
    });

    test('getWeeklyInsights calculates averages correctly', () async {
      final now = DateTime(2025, 1, 10, 12, 0);
      final workouts = [
        // Week 1: 2 workouts, 60+45=105 min total, 20+15=35 sets total
        _createWorkout(now.subtract(const Duration(days: 1)), 60, 20),
        _createWorkout(now.subtract(const Duration(days: 2)), 45, 15),
        // Week 2: 1 workout, 50 min, 25 sets
        _createWorkout(now.subtract(const Duration(days: 8)), 50, 25),
      ];

      service.setWorkoutsProvider(() async => workouts);

      final insights = await service.getWeeklyInsights(monthsBack: 6);

      // Average workouts per week: 3 workouts / 2 weeks with data = 1.5
      expect(insights.averageWorkoutsPerWeek, closeTo(1.5, 0.01));
      
      // Average duration: (60+45+50) / 3 = 51.67 minutes
      expect(insights.averageDuration, closeTo(51.67, 0.01));
      
      // Average volume: (20+15+25) / 3 = 20 sets
      expect(insights.averageVolume, closeTo(20.0, 0.01));
    });

    test('getWeeklyInsights handles workouts with no duration', () async {
      final now = DateTime(2025, 1, 10, 12, 0);
      final workoutId = 'w-1';
      final workoutExerciseId = 'we-1';
      final workout = Workout(
        id: workoutId,
        name: 'Test',
        startedAt: now,
        completedAt: null, // No completion time
        status: WorkoutStatus.completed,
        exercises: [
          WorkoutExercise(
            id: workoutExerciseId,
            workoutId: workoutId, // Link to workout
            exerciseSlug: 'bench-press',
            sets: [
              WorkoutSet(
                workoutExerciseId: workoutExerciseId,
                setIndex: 0,
                actualWeight: 100,
                actualReps: 10,
              ),
            ],
          ),
        ],
      );

      service.setWorkoutsProvider(() async => [workout]);

      final insights = await service.getWeeklyInsights(monthsBack: 6);

      // Should handle gracefully (last index for 26 weeks)
      expect(insights.weeklyWorkoutCounts[25].maxValue, 1);
      expect(insights.weeklyDurations[25].minValue, 0);
      expect(insights.weeklyDurations[25].maxValue, 0);
    });

    test('getWeeklyInsights uses caching', () async {
      final now = DateTime(2025, 1, 10, 12, 0);
      final workouts = [
        _createWorkout(now.subtract(const Duration(days: 1)), 60, 20),
      ];

      service.setWorkoutsProvider(() async => workouts);

      // First call
      final insights1 = await service.getWeeklyInsights(monthsBack: 6);
      
      // Second call should use cache
      final insights2 = await service.getWeeklyInsights(monthsBack: 6);

      expect(insights1.lastUpdated.millisecondsSinceEpoch, insights2.lastUpdated.millisecondsSinceEpoch);
    });

    test('getWeeklyInsights force refresh bypasses cache', () async {
      final now = DateTime(2025, 1, 10, 12, 0);
      final workouts = [
        _createWorkout(now.subtract(const Duration(days: 1)), 60, 20),
      ];

      service.setWorkoutsProvider(() async => workouts);

      // First call
      final insights1 = await service.getWeeklyInsights(monthsBack: 6);
      
      // Wait a bit to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Force refresh
      final insights2 = await service.getWeeklyInsights(
        monthsBack: 6,
        forceRefresh: true,
      );

      expect(insights1.lastUpdated.isBefore(insights2.lastUpdated), isTrue);
    });

    test('getWeeklyInsights handles week boundaries correctly', () async {
      // Monday Jan 6, 2025 - this will be the reference week
      final monday = DateTime(2025, 1, 6, 12, 0);
      final workouts = [
        _createWorkout(monday, 60, 20), // Monday Jan 6
        _createWorkout(monday.add(const Duration(days: 6)), 45, 15), // Sunday Jan 12 (same week)
        _createWorkout(monday.subtract(const Duration(days: 7)), 50, 25), // Previous Monday (Dec 30)
      ];

      service.setWorkoutsProvider(() async => workouts);

      final insights = await service.getWeeklyInsights(monthsBack: 6);

      // First two workouts should be in the same week (most recent, last index for 26 weeks)
      expect(insights.weeklyWorkoutCounts[25].maxValue, 2);
      // Third workout should be in the previous week
      expect(insights.weeklyWorkoutCounts[24].maxValue, 1);
    });

    test('getWeeklyInsights uses monthly grouping for 1 year timeframe', () async {
      final now = DateTime(2025, 1, 10, 12, 0);
      final workouts = [
        // This month: 2 workouts
        _createWorkout(now.subtract(const Duration(days: 1)), 60, 20),
        _createWorkout(now.subtract(const Duration(days: 3)), 45, 15),
        // Last month: 3 workouts
        _createWorkout(now.subtract(const Duration(days: 35)), 50, 25),
        _createWorkout(now.subtract(const Duration(days: 37)), 40, 18),
        _createWorkout(now.subtract(const Duration(days: 38)), 55, 22),
      ];

      service.setWorkoutsProvider(() async => workouts);

      final insights = await service.getWeeklyInsights(monthsBack: 12);

      expect(insights.weeklyWorkoutCounts.length, 12); // 1 year = 12 months
      
      // This month (most recent)
      expect(insights.weeklyWorkoutCounts[11].maxValue, 2);
      // Last month
      expect(insights.weeklyWorkoutCounts[10].maxValue, 3);
      // Older months should be 0
      expect(insights.weeklyWorkoutCounts[9].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[8].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[7].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[6].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[5].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[4].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[3].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[2].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[1].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[0].maxValue, 0);
    });

    test('getWeeklyInsights uses monthly grouping for 2 year timeframe', () async {
      final now = DateTime(2025, 1, 10, 12, 0);
      final workouts = [
        // This month: 2 workouts
        _createWorkout(now.subtract(const Duration(days: 1)), 60, 20),
        _createWorkout(now.subtract(const Duration(days: 3)), 45, 15),
        // Last month: 3 workouts
        _createWorkout(now.subtract(const Duration(days: 35)), 50, 25),
        _createWorkout(now.subtract(const Duration(days: 37)), 40, 18),
        _createWorkout(now.subtract(const Duration(days: 38)), 55, 22),
      ];

      service.setWorkoutsProvider(() async => workouts);

      final insights = await service.getWeeklyInsights(monthsBack: 24);

      expect(insights.weeklyWorkoutCounts.length, 24); // 2 years = 24 months
      
      // This month (most recent)
      expect(insights.weeklyWorkoutCounts[23].maxValue, 2);
      // Last month
      expect(insights.weeklyWorkoutCounts[22].maxValue, 3);
      // Older months should be 0
      expect(insights.weeklyWorkoutCounts[21].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[20].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[19].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[18].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[17].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[16].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[15].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[14].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[13].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[12].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[11].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[10].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[9].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[8].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[7].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[6].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[5].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[4].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[3].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[2].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[1].maxValue, 0);
      expect(insights.weeklyWorkoutCounts[0].maxValue, 0);
    });

    group('Filtering', () {
      test('filter by workout name', () async {
        final now = DateTime(2025, 1, 10, 12, 0);
        final workouts = [
          _createWorkout(now.subtract(const Duration(days: 1)), 60, 20).copyWith(name: 'Leg Day'),
          _createWorkout(now.subtract(const Duration(days: 2)), 45, 15).copyWith(name: 'Push Day'),
          _createWorkout(now.subtract(const Duration(days: 3)), 50, 25).copyWith(name: 'Leg Day'),
        ];

        service.setWorkoutsProvider(() async => workouts);

        final insights = await service.getWeeklyInsights(
          monthsBack: 6,
          workoutName: 'Leg Day',
        );

        // Should only count Leg Day workouts (2)
        expect(insights.weeklyWorkoutCounts[25].maxValue, 2);
        expect(insights.averageWorkoutsPerWeek, 2.0);
      });

      test('filter by muscle group', () async {
        // Setup exercises
        final chestExercise = Exercise(
          slug: 'bench-press',
          name: 'Bench Press',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [],
          instructions: [],
          equipment: 'Barbell',
          image: '',
          animation: '',
          isBodyWeightExercise: false,
        );
        
        final legExercise = Exercise(
          slug: 'squat',
          name: 'Squat',
          primaryMuscleGroup: MuscleGroup.legs,
          secondaryMuscleGroups: [],
          instructions: [],
          equipment: 'Barbell',
          image: '',
          animation: '',
          isBodyWeightExercise: false,
        );

        exerciseService.setDependenciesForTesting(
          seedExercises: [chestExercise, legExercise],
        );

        final now = DateTime(2025, 1, 10, 12, 0);
        
        // Workout 1: Chest only (20 sets)
        final workout1 = _createWorkout(now.subtract(const Duration(days: 1)), 60, 20);
        // Manually update exercise slugs to match our seeded exercises
        final w1Exercises = workout1.exercises.map((e) => e.copyWith(exerciseSlug: 'bench-press')).toList();
        final w1 = workout1.copyWith(exercises: w1Exercises);

        // Workout 2: Legs only (15 sets)
        final workout2 = _createWorkout(now.subtract(const Duration(days: 2)), 45, 15);
        final w2Exercises = workout2.exercises.map((e) => e.copyWith(exerciseSlug: 'squat')).toList();
        final w2 = workout2.copyWith(exercises: w2Exercises);

        // Workout 3: Mixed (10 sets chest, 10 sets legs)
        final workout3 = _createWorkout(now.subtract(const Duration(days: 3)), 90, 20);
        final w3Exercises = workout3.exercises.asMap().entries.map((entry) {
          // First half chest, second half legs
          // _createWorkout creates exercises with 5 sets each. 20 sets total = 4 exercises.
          // So indices 0,1 should be chest (10 sets), 2,3 should be legs (10 sets).
          return entry.value.copyWith(
            exerciseSlug: entry.key < 2 ? 'bench-press' : 'squat'
          );
        }).toList();
        final w3 = workout3.copyWith(exercises: w3Exercises);

        service.setWorkoutsProvider(() async => [w1, w2, w3]);

        // Filter by Chest
        final chestInsights = await service.getWeeklyInsights(
          monthsBack: 6,
          muscleGroup: 'Chest',
        );

        // Should include w1 and w3 (2 workouts)
        expect(chestInsights.weeklyWorkoutCounts[25].maxValue, 2);
        
        // Volume should only include chest sets
        // w1: 20 sets (all chest)
        // w3: 10 sets (chest part only)
        // Total volume range: min 10, max 20
        expect(chestInsights.weeklyVolumes[25].minValue, 10);
        expect(chestInsights.weeklyVolumes[25].maxValue, 20);
      });

      test('filter by equipment', () async {
        // Setup exercises
        final dumbbellExercise = Exercise(
          slug: 'db-press',
          name: 'DB Press',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [],
          instructions: [],
          equipment: 'Dumbbell',
          image: '',
          animation: '',
          isBodyWeightExercise: false,
        );
        
        final barbellExercise = Exercise(
          slug: 'bb-press',
          name: 'BB Press',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [],
          instructions: [],
          equipment: 'Barbell',
          image: '',
          animation: '',
          isBodyWeightExercise: false,
        );

        exerciseService.setDependenciesForTesting(
          seedExercises: [dumbbellExercise, barbellExercise],
        );

        final now = DateTime(2025, 1, 10, 12, 0);
        
        // Workout 1: Dumbbell only (20 sets)
        final workout1 = _createWorkout(now.subtract(const Duration(days: 1)), 60, 20);
        final w1 = workout1.copyWith(exercises: workout1.exercises.map((e) => e.copyWith(exerciseSlug: 'db-press')).toList());

        // Workout 2: Barbell only (15 sets)
        final workout2 = _createWorkout(now.subtract(const Duration(days: 2)), 45, 15);
        final w2 = workout2.copyWith(exercises: workout2.exercises.map((e) => e.copyWith(exerciseSlug: 'bb-press')).toList());

        service.setWorkoutsProvider(() async => [w1, w2]);

        // Filter by Dumbbell
        final dbInsights = await service.getWeeklyInsights(
          monthsBack: 6,
          equipment: 'Dumbbell',
        );

        // Should include w1 only
        expect(dbInsights.weeklyWorkoutCounts[25].maxValue, 1);
        expect(dbInsights.weeklyVolumes[25].maxValue, 20);
      });

      test('filter by bodyweight', () async {
        // Setup exercises
        final bwExercise = Exercise(
          slug: 'pushups',
          name: 'Pushups',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [],
          instructions: [],
          equipment: 'None',
          image: '',
          animation: '',
          isBodyWeightExercise: true,
        );
        
        final weightedExercise = Exercise(
          slug: 'bench-press',
          name: 'Bench Press',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [],
          instructions: [],
          equipment: 'Barbell',
          image: '',
          animation: '',
          isBodyWeightExercise: false,
        );

        exerciseService.setDependenciesForTesting(
          seedExercises: [bwExercise, weightedExercise],
        );

        final now = DateTime(2025, 1, 10, 12, 0);
        
        // Workout 1: Bodyweight only (20 sets)
        final workout1 = _createWorkout(now.subtract(const Duration(days: 1)), 60, 20);
        final w1 = workout1.copyWith(exercises: workout1.exercises.map((e) => e.copyWith(exerciseSlug: 'pushups')).toList());

        // Workout 2: Weighted only (15 sets)
        final workout2 = _createWorkout(now.subtract(const Duration(days: 2)), 45, 15);
        final w2 = workout2.copyWith(exercises: workout2.exercises.map((e) => e.copyWith(exerciseSlug: 'bench-press')).toList());

        service.setWorkoutsProvider(() async => [w1, w2]);

        // Filter by Bodyweight
        final bwInsights = await service.getWeeklyInsights(
          monthsBack: 6,
          isBodyWeight: true,
        );

        // Should include w1 only
        expect(bwInsights.weeklyWorkoutCounts[25].maxValue, 1);
        expect(bwInsights.weeklyVolumes[25].maxValue, 20);
      });
    });
  });
}

/// Helper to create a workout with specified duration and volume
Workout _createWorkout(DateTime startedAt, int durationMinutes, int totalSets) {
  final completedAt = startedAt.add(Duration(minutes: durationMinutes));
  final workoutId = 'w-${startedAt.millisecondsSinceEpoch}';
  
  // Create exercises with the specified total sets
  final exercises = <WorkoutExercise>[];
  int remainingSets = totalSets;
  
  while (remainingSets > 0) {
    final setsForThisExercise = remainingSets > 5 ? 5 : remainingSets;
    final workoutExerciseId = 'we-${exercises.length}';
    exercises.add(
      WorkoutExercise(
        id: workoutExerciseId,
        workoutId: workoutId, // Link to the workout (for history exercises)
        exerciseSlug: 'exercise-${exercises.length}',
        sets: List.generate(
          setsForThisExercise,
          (i) => WorkoutSet(
            workoutExerciseId: workoutExerciseId,
            setIndex: i,
            actualWeight: 100,
            actualReps: 10,
          ),
        ),
      ),
    );
    remainingSets -= setsForThisExercise;
  }

  return Workout(
    id: workoutId,
    name: 'Test Workout',
    startedAt: startedAt,
    completedAt: completedAt,
    status: WorkoutStatus.completed,
    exercises: exercises,
  );
}
