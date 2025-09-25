import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/database_service.dart';
import 'package:zenith/services/insights_service.dart';

// Generate mocks
@GenerateMocks([DatabaseService])
import 'insights_service_test.mocks.dart';

void main() {
  group('InsightsService Tests', () {
    late InsightsService insightsService;
    late MockDatabaseService mockDatabaseService;

    setUp(() {
      // Reset the singleton instance before each test to ensure isolation
      InsightsService.instance.reset();
      
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
      
      // Create mock database service
      mockDatabaseService = MockDatabaseService();
      
      // Initialize the insights service
      insightsService = InsightsService.instance;
    });

    test('should initialize insights service', () {
      expect(insightsService, isNotNull);
    });

    test('should be a singleton', () {
      final service1 = InsightsService();
      final service2 = InsightsService();
      expect(service1, same(service2));
    });

    group('initialize', () {
      test('should initialize without errors', () async {
        await expectLater(insightsService.initialize(), completes);
      });

      test('should handle cache loading errors gracefully', () async {
        // Set up shared preferences with invalid data
        SharedPreferences.setMockInitialValues({
          'insights_cache': 'invalid_json',
        });
        
        await expectLater(insightsService.initialize(), completes);
      });

      test('should load valid cache data', () async {
        final validCacheData = {
          'insights_cache': '{"data": {"test_key": {"totalWorkouts": 5}}, "lastUpdate": ${DateTime.now().millisecondsSinceEpoch}}'
        };
        SharedPreferences.setMockInitialValues(validCacheData);
        
        await expectLater(insightsService.initialize(), completes);
      });
    });

    group('getWorkoutInsights', () {
      late List<Workout> mockWorkouts;

      setUp(() {
        // Create deterministic test data with fixed dates
        final baseDate = DateTime(2023, 6, 15); // Fixed date for consistent testing
        mockWorkouts = [
          Workout(
            id: 'workout1',
            name: 'Chest Day',
            status: WorkoutStatus.completed,
            startedAt: baseDate.subtract(Duration(days: 5)),
            completedAt: baseDate.subtract(Duration(days: 5)).add(Duration(hours: 1)),
            exercises: [
              WorkoutExercise(
                id: 'exercise1',
                workoutId: 'workout1',
                exerciseSlug: 'bench-press',
                sets: [
                  WorkoutSet(
                    id: 'set1',
                    workoutExerciseId: 'exercise1',
                    setIndex: 0,
                    actualReps: 10,
                    actualWeight: 100.0,
                    isCompleted: true,
                  ),
                  WorkoutSet(
                    id: 'set2',
                    workoutExerciseId: 'exercise1',
                    setIndex: 1,
                    actualReps: 8,
                    actualWeight: 110.0,
                    isCompleted: true,
                  ),
                ],
              ),
            ],
          ),
          Workout(
            id: 'workout2',
            name: 'Leg Day',
            status: WorkoutStatus.completed,
            startedAt: baseDate.subtract(Duration(days: 3)),
            completedAt: baseDate.subtract(Duration(days: 3)).add(Duration(hours: 1, minutes: 30)),
            exercises: [
              WorkoutExercise(
                id: 'exercise2',
                workoutId: 'workout2',
                exerciseSlug: 'squat',
                sets: [
                  WorkoutSet(
                    id: 'set3',
                    workoutExerciseId: 'exercise2',
                    setIndex: 0,
                    actualReps: 12,
                    actualWeight: 150.0,
                    isCompleted: true,
                  ),
                ],
              ),
            ],
          ),
        ];
      });

      test('should calculate workout insights correctly with specific values', () async {
        final service = InsightsService();
        service.setWorkoutsProvider(() async => mockWorkouts);
        
        final insights = await service.getWorkoutInsights(monthsBack: 1);
        
        expect(insights, isNotNull);
        expect(insights.totalWorkouts, 2);
        expect(insights.totalHours, 2.5); // 1 hour + 1.5 hours
        expect(insights.totalWeight, 3680.0); // (10*100 + 8*110) + (12*150)
        expect(insights.averageWorkoutDuration, 1.25); // 2.5 / 2
        expect(insights.averageWeightPerWorkout, 1840.0); // 2680 / 2
        expect(insights.monthlyWorkouts, isNotEmpty);
        expect(insights.monthlyHours, isNotEmpty);
        expect(insights.monthlyWeight, isNotEmpty);
      });

      test('should handle empty workout list', () async {
        final service = InsightsService();
        await service.clearCache();
        service.setWorkoutsProvider(() async => []);
        
        final insights = await service.getWorkoutInsights(monthsBack: 1);
        
        expect(insights, isNotNull);
        expect(insights.totalWorkouts, 0);
        expect(insights.totalHours, 0.0);
        expect(insights.totalWeight, 0.0);
        expect(insights.averageWorkoutDuration, 0.0);
        expect(insights.averageWeightPerWorkout, 0.0);
        expect(insights.monthlyWorkouts, isNotEmpty); // Should have empty monthly data points
        expect(insights.monthlyHours, isNotEmpty);
        expect(insights.monthlyWeight, isNotEmpty);
      });

      test('should handle workouts with null weights and reps', () async {
        final service = InsightsService();
        await service.clearCache();
        
        final workoutsWithNulls = [
          Workout(
            id: 'workout1',
            name: 'Test Workout',
            status: WorkoutStatus.completed,
            startedAt: DateTime.now().subtract(Duration(days: 1)),
            completedAt: DateTime.now().subtract(Duration(days: 1)).add(Duration(hours: 1)),
            exercises: [
              WorkoutExercise(
                id: 'exercise1',
                workoutId: 'workout1',
                exerciseSlug: 'test-exercise',
                sets: [
                  WorkoutSet(
                    id: 'set1',
                    workoutExerciseId: 'exercise1',
                    setIndex: 0,
                    actualReps: null, // null reps
                    actualWeight: null, // null weight
                    isCompleted: true,
                  ),
                ],
              ),
            ],
          ),
        ];
        
        service.setWorkoutsProvider(() async => workoutsWithNulls);
        
        final insights = await service.getWorkoutInsights(monthsBack: 1);
        
        expect(insights.totalWorkouts, 1);
        expect(insights.totalWeight, 0.0); // Should handle nulls gracefully
        expect(insights.totalHours, 1.0);
      });

      test('should filter out incomplete workouts', () async {
        final service = InsightsService();
        await service.clearCache();
        
        final mixedWorkouts = [
          Workout(
            id: 'incomplete',
            name: 'Incomplete Workout',
            status: WorkoutStatus.inProgress,
            startedAt: DateTime.now().subtract(Duration(days: 1)),
            exercises: [],
          ),
          ...mockWorkouts,
        ];
        
        service.setWorkoutsProvider(() async => mixedWorkouts);
        
        final insights = await service.getWorkoutInsights(monthsBack: 1);
        
        expect(insights.totalWorkouts, 2); // Should only count completed workouts
      });

      test('should filter workouts by date range', () async {
        final service = InsightsService();
        await service.clearCache();

        // Use a fixed date for deterministic testing
        final baseDate = DateTime(2023, 6, 15);
        final workoutsInJune = mockWorkouts; // These are from June 2023
        final workoutsInMay = [
          Workout(
            id: 'may-workout',
            name: 'May Workout',
            status: WorkoutStatus.completed,
            startedAt: baseDate.subtract(Duration(days: 30)), // May 16, 2023
            completedAt: baseDate.subtract(Duration(days: 30)).add(Duration(hours: 1)),
            exercises: [],
          ),
        ];

        final allTestWorkouts = [...workoutsInJune, ...workoutsInMay];
        service.setWorkoutsProvider(() async => allTestWorkouts);

        // Test case 1: monthsBack = 1 (should only include June workouts)
        // The latest workout is June 12, so reference date is June 12.
        // Cutoff is June 1.
        final insights1 = await service.getWorkoutInsights(monthsBack: 1);
        expect(insights1.totalWorkouts, 2, reason: "Failed for monthsBack=1");

        // Test case 2: monthsBack = 2 (should include June and May workouts)
        // Reference date is June 12.
        // Cutoff is May 1.
        final insights2 = await service.getWorkoutInsights(monthsBack: 2);
        expect(insights2.totalWorkouts, 3, reason: "Failed for monthsBack=2");
      });

      test('should handle workouts without completion time', () async {
        final service = InsightsService();
        await service.clearCache();
        
        final workoutsWithoutCompletion = [
          Workout(
            id: 'no-completion',
            name: 'No Completion Time',
            status: WorkoutStatus.completed,
            startedAt: DateTime.now().subtract(Duration(days: 1)),
            completedAt: null, // No completion time
            exercises: [],
          ),
        ];
        
        service.setWorkoutsProvider(() async => workoutsWithoutCompletion);
        
        final insights = await service.getWorkoutInsights(monthsBack: 1);
        
        expect(insights.totalWorkouts, 1);
        expect(insights.totalHours, 0.0); // Should handle missing completion time
      });

      test('should use cached data when available and not expired', () async {
        final service = InsightsService();
        service.setWorkoutsProvider(() async => mockWorkouts);
        
        // First call to populate cache
        final insights1 = await service.getWorkoutInsights(monthsBack: 1);
        expect(insights1, isNotNull);
        
        // Change the data source
        service.setWorkoutsProvider(() async => []);
        
        // Second call should use cache (not the empty list)
        final insights2 = await service.getWorkoutInsights(monthsBack: 1);
        expect(insights2.totalWorkouts, insights1.totalWorkouts);
      });

      test('should refresh cache when forceRefresh is true', () async {
        final service = InsightsService();
        // Use the mockWorkouts from setUp (2 workouts in June 2023)
        service.setWorkoutsProvider(() async => mockWorkouts);
        
        // First call to populate cache.
        // With the new filtering logic, monthsBack=1 on June 15 reference date
        // should include the 2 workouts from June.
        final insights1 = await service.getWorkoutInsights(monthsBack: 1);
        expect(insights1.totalWorkouts, 2, reason: "Initial calculation should find 2 workouts");
        
        // Change the data source to a single workout
        final newWorkouts = [mockWorkouts.first];
        service.setWorkoutsProvider(() async => newWorkouts);
        
        // Second call without forceRefresh should use the cache
        final insights2 = await service.getWorkoutInsights(monthsBack: 1, forceRefresh: false);
        expect(insights2.totalWorkouts, 2, reason: "Should use cached result");

        // Third call with forceRefresh should use the new data
        final insights3 = await service.getWorkoutInsights(
          monthsBack: 1, 
          forceRefresh: true,
        );
        expect(insights3.totalWorkouts, 1, reason: "Should use refreshed data");
      });

      test('should handle database errors gracefully', () async {
        final service = InsightsService();
        await service.clearCache();
        
        service.setWorkoutsProvider(() async { 
          throw Exception('Database error'); 
        });
        
        final insights = await service.getWorkoutInsights(monthsBack: 1);
        
        expect(insights, isNotNull);
        expect(insights.totalWorkouts, 0);
        expect(insights.totalHours, 0.0);
        expect(insights.totalWeight, 0.0);
      });

      test('should handle invalid monthsBack values', () async {
        final service = InsightsService();
        service.setWorkoutsProvider(() async => mockWorkouts);
        
        // Test with zero months
        final insights1 = await service.getWorkoutInsights(monthsBack: 0);
        expect(insights1, isNotNull);
        expect(insights1.monthlyWorkouts, isEmpty);
        
        // Test with negative months (should still work due to loop logic)
        final insights2 = await service.getWorkoutInsights(monthsBack: -1);
        expect(insights2, isNotNull);
      });

      test('should handle month boundary calculations correctly', () async {
        final service = InsightsService();
        
        // Create workouts spanning multiple months
        final crossMonthWorkouts = [
          Workout(
            id: 'jan-workout',
            name: 'January Workout',
            status: WorkoutStatus.completed,
            startedAt: DateTime(2023, 1, 15),
            completedAt: DateTime(2023, 1, 15, 1),
            exercises: [],
          ),
          Workout(
            id: 'feb-workout',
            name: 'February Workout',
            status: WorkoutStatus.completed,
            startedAt: DateTime(2023, 2, 15),
            completedAt: DateTime(2023, 2, 15, 1),
            exercises: [],
          ),
        ];
        
        service.setWorkoutsProvider(() async => crossMonthWorkouts);
        
        final insights = await service.getWorkoutInsights(monthsBack: 3);
        
        expect(insights, isNotNull);
        expect(insights.monthlyWorkouts.length, 3);
        // Should have data points for each month even if some are zero
      });
    });

    group('getExerciseInsights', () {
      late List<Workout> mockWorkouts;

      setUp(() {
        final baseDate = DateTime(2023, 6, 15);
        mockWorkouts = [
          Workout(
            id: 'workout1',
            name: 'Chest Day',
            status: WorkoutStatus.completed,
            startedAt: baseDate.subtract(Duration(days: 5)),
            completedAt: baseDate.subtract(Duration(days: 5)).add(Duration(hours: 1)),
            exercises: [
              WorkoutExercise(
                id: 'exercise1',
                workoutId: 'workout1',
                exerciseSlug: 'bench-press',
                sets: [
                  WorkoutSet(
                    id: 'set1',
                    workoutExerciseId: 'exercise1',
                    setIndex: 0,
                    actualReps: 10,
                    actualWeight: 100.0,
                    isCompleted: true,
                  ),
                  WorkoutSet(
                    id: 'set2',
                    workoutExerciseId: 'exercise1',
                    setIndex: 1,
                    actualReps: 8,
                    actualWeight: 110.0,
                    isCompleted: true,
                  ),
                ],
              ),
            ],
          ),
          Workout(
            id: 'workout2',
            name: 'Another Chest Day',
            status: WorkoutStatus.completed,
            startedAt: baseDate.subtract(Duration(days: 3)),
            completedAt: baseDate.subtract(Duration(days: 3)).add(Duration(hours: 1)),
            exercises: [
              WorkoutExercise(
                id: 'exercise2',
                workoutId: 'workout2',
                exerciseSlug: 'bench-press',
                sets: [
                  WorkoutSet(
                    id: 'set3',
                    workoutExerciseId: 'exercise2',
                    setIndex: 0,
                    actualReps: 12,
                    actualWeight: 105.0,
                    isCompleted: true,
                  ),
                ],
              ),
            ],
          ),
        ];
      });

      test('should calculate exercise insights correctly with specific values', () async {
        final service = InsightsService();
        service.setWorkoutsProvider(() async => mockWorkouts);
        
        final insights = await service.getExerciseInsights(
          exerciseName: 'bench-press',
          monthsBack: 1,
        );
        
        expect(insights, isNotNull);
        expect(insights.exerciseName, 'bench-press');
        expect(insights.totalSessions, 2);
        expect(insights.totalSets, 3);
        expect(insights.totalReps, 30); // 10 + 8 + 12
        expect(insights.totalWeight, 3140.0); // (10*100 + 8*110) + (12*105)
        expect(insights.maxWeight, 110.0);
        expect(insights.averageWeight, closeTo(1046.6, 0.1)); // 2140 / 3 sets
        expect(insights.averageReps, 10.0); // 30 / 3 sets
        expect(insights.averageSets, 1.5); // 3 sets / 2 sessions
        expect(insights.monthlyVolume, isNotEmpty);
        expect(insights.monthlyMaxWeight, isNotEmpty);
        expect(insights.monthlyFrequency, isNotEmpty);
      });

      test('should handle exercise with no instances', () async {
        final service = InsightsService();
        service.setWorkoutsProvider(() async => mockWorkouts);
        
        final insights = await service.getExerciseInsights(
          exerciseName: 'non-existent-exercise',
          monthsBack: 1,
        );
        
        expect(insights, isNotNull);
        expect(insights.exerciseName, 'non-existent-exercise');
        expect(insights.totalSessions, 0);
        expect(insights.totalSets, 0);
        expect(insights.totalReps, 0);
        expect(insights.totalWeight, 0.0);
        expect(insights.maxWeight, 0.0);
        expect(insights.averageWeight, 0.0);
        expect(insights.averageReps, 0.0);
        expect(insights.averageSets, 0.0);
        expect(insights.monthlyVolume, isNotEmpty); // Should have empty data points
      });

      test('should handle empty workout list', () async {
        final service = InsightsService();
        await service.clearCache();
        service.setWorkoutsProvider(() async => []);
        
        final insights = await service.getExerciseInsights(
          exerciseName: 'bench-press',
          monthsBack: 1,
        );
        
        expect(insights, isNotNull);
        expect(insights.totalSessions, 0);
      });

      test('should handle case insensitive exercise name matching', () async {
        final service = InsightsService();
        await service.clearCache();
        service.setWorkoutsProvider(() async => mockWorkouts);
        
        final insights1 = await service.getExerciseInsights(
          exerciseName: 'BENCH-PRESS',
          monthsBack: 1,
        );
        
        final insights2 = await service.getExerciseInsights(
          exerciseName: 'bench-press',
          monthsBack: 1,
        );
        
        expect(insights1.totalSessions, insights2.totalSessions);
        expect(insights1.totalSessions, 2);
      });

      test('should handle exercises with empty sets', () async {
        final service = InsightsService();
        await service.clearCache();
        
        final workoutsWithEmptySets = [
          Workout(
            id: 'workout1',
            name: 'Empty Sets Workout',
            status: WorkoutStatus.completed,
            startedAt: DateTime.now().subtract(Duration(days: 1)),
            completedAt: DateTime.now().subtract(Duration(days: 1)).add(Duration(hours: 1)),
            exercises: [
              WorkoutExercise(
                id: 'exercise1',
                workoutId: 'workout1',
                exerciseSlug: 'test-exercise',
                sets: [], // Empty sets
              ),
            ],
          ),
        ];
        
        service.setWorkoutsProvider(() async => workoutsWithEmptySets);
        
        final insights = await service.getExerciseInsights(
          exerciseName: 'test-exercise',
          monthsBack: 1,
        );
        
        expect(insights.totalSessions, 1);
        expect(insights.totalSets, 0);
        expect(insights.maxWeight, 0.0);
      });

      test('should use cached data when available and not expired', () async {
        final service = InsightsService();
        service.setWorkoutsProvider(() async => mockWorkouts);
        
        // First call to populate cache
        final insights1 = await service.getExerciseInsights(
          exerciseName: 'bench-press',
          monthsBack: 1,
        );
        expect(insights1, isNotNull);
        
        // Change data source
        service.setWorkoutsProvider(() async => []);
        
        // Second call should use cache
        final insights2 = await service.getExerciseInsights(
          exerciseName: 'bench-press',
          monthsBack: 1,
        );
        expect(insights2.totalSessions, insights1.totalSessions);
      });

      test('should refresh cache when forceRefresh is true', () async {
        final service = InsightsService();
        service.setWorkoutsProvider(() async => mockWorkouts);
        
        // First call to populate cache
        final insights1 = await service.getExerciseInsights(
          exerciseName: 'bench-press',
          monthsBack: 1,
        );
        expect(insights1.totalSessions, 2);
        
        // Change data source
        service.setWorkoutsProvider(() async => []);
        
        // Force refresh should use new data
        final insights2 = await service.getExerciseInsights(
          exerciseName: 'bench-press',
          monthsBack: 1,
          forceRefresh: true,
        );
        expect(insights2.totalSessions, 0);
      });

      test('should handle database errors gracefully', () async {
        final service = InsightsService();
        await service.clearCache();
        
        service.setWorkoutsProvider(() async { 
          throw Exception('Database error'); 
        });
        
        final insights = await service.getExerciseInsights(
          exerciseName: 'bench-press',
          monthsBack: 1,
        );
        
        expect(insights, isNotNull);
        expect(insights.totalSessions, 0);
      });
    });

    group('clearCache', () {
      test('should clear cache successfully', () async {
        await expectLater(insightsService.clearCache(), completes);
      });

      test('should clear cache and affect subsequent calls', () async {
        final service = InsightsService();
        service.setWorkoutsProvider(() async => []);
        
        // Populate cache
        await service.getWorkoutInsights(monthsBack: 1);
        
        // Clear cache
        await service.clearCache();
        
        // This should recalculate since cache is cleared
        final insights = await service.getWorkoutInsights(monthsBack: 1);
        expect(insights, isNotNull);
      });
    });

    group('Cache expiry', () {
      // Note: Testing time-based expiry accurately requires a time-mocking library (e.g., clock).
      // This test will verify the basic caching mechanism works as expected,
      // which is a prerequisite for time-based expiry.
      test('should use cache when not expired and not force-refreshed', () async {
        final service = InsightsService();
        final baseDate = DateTime(2023, 6, 15);
        final initialWorkouts = [
          Workout(
            id: 'workout1',
            name: 'Test Workout',
            status: WorkoutStatus.completed,
            startedAt: baseDate.subtract(Duration(days: 5)),
            completedAt: baseDate.subtract(Duration(days: 5)).add(Duration(hours: 1)),
            exercises: [],
          ),
        ];
        service.setWorkoutsProvider(() async => initialWorkouts);
        
        // 1. Populate cache
        final insights1 = await service.getWorkoutInsights(monthsBack: 1);
        expect(insights1.totalWorkouts, 1);
        
        // 2. Change the data provider. If cache is used, this won't be called.
        service.setWorkoutsProvider(() async => []);

        // 3. Call again without forceRefresh. Should return the cached result.
        final insights2 = await service.getWorkoutInsights(monthsBack: 1, forceRefresh: false);
        expect(insights2.totalWorkouts, 1);
      });
    });

    group('Model serialization', () {
      group('WorkoutInsights', () {
        test('should convert to and from map correctly', () {
          final insights = WorkoutInsights(
            totalWorkouts: 10,
            totalHours: 15.5,
            totalWeight: 5000.0,
            monthlyWorkouts: [
              MonthlyDataPoint(
                month: DateTime(2023, 1, 1),
                value: 5.0,
              ),
            ],
            monthlyHours: [
              MonthlyDataPoint(
                month: DateTime(2023, 1, 1),
                value: 7.5,
              ),
            ],
            monthlyWeight: [
              MonthlyDataPoint(
                month: DateTime(2023, 1, 1),
                value: 2500.0,
              ),
            ],
            averageWorkoutDuration: 1.55,
            averageWeightPerWorkout: 500.0,
            lastUpdated: DateTime(2023, 1, 1),
          );

          final map = insights.toMap();
          final restored = WorkoutInsights.fromMap(map);

          expect(restored.totalWorkouts, insights.totalWorkouts);
          expect(restored.totalHours, insights.totalHours);
          expect(restored.totalWeight, insights.totalWeight);
          expect(restored.monthlyWorkouts.length, insights.monthlyWorkouts.length);
          expect(restored.monthlyHours.length, insights.monthlyHours.length);
          expect(restored.monthlyWeight.length, insights.monthlyWeight.length);
          expect(restored.averageWorkoutDuration, insights.averageWorkoutDuration);
          expect(restored.averageWeightPerWorkout, insights.averageWeightPerWorkout);
          expect(restored.lastUpdated, insights.lastUpdated);
        });

        test('should handle empty monthly data', () {
          final insights = WorkoutInsights(
            totalWorkouts: 0,
            totalHours: 0.0,
            totalWeight: 0.0,
            monthlyWorkouts: [],
            monthlyHours: [],
            monthlyWeight: [],
            averageWorkoutDuration: 0.0,
            averageWeightPerWorkout: 0.0,
            lastUpdated: DateTime(2023, 1, 1),
          );

          final map = insights.toMap();
          final restored = WorkoutInsights.fromMap(map);

          expect(restored.monthlyWorkouts, isEmpty);
          expect(restored.monthlyHours, isEmpty);
          expect(restored.monthlyWeight, isEmpty);
        });

        test('should handle malformed map data gracefully', () {
          final malformedMap = <String, dynamic>{
            'totalWorkouts': 'invalid', // Wrong type
            'totalHours': null,
            'monthlyWorkouts': 'not a list',
            // Missing required fields
          };

          final restored = WorkoutInsights.fromMap(malformedMap);

          expect(restored.totalWorkouts, 0); // Should use default
          expect(restored.totalHours, 0.0);
          expect(restored.monthlyWorkouts, isEmpty);
        });
      });

      group('ExerciseInsights', () {
        test('should convert to and from map correctly', () {
          final insights = ExerciseInsights(
            exerciseName: 'Bench Press',
            totalSessions: 5,
            totalSets: 15,
            totalReps: 150,
            totalWeight: 7500.0,
            maxWeight: 120.0,
            averageWeight: 50.0,
            averageReps: 10.0,
            averageSets: 3.0,
            monthlyVolume: [
              MonthlyDataPoint(
                month: DateTime(2023, 1, 1),
                value: 2500.0,
              ),
            ],
            monthlyMaxWeight: [
              MonthlyDataPoint(
                month: DateTime(2023, 1, 1),
                value: 110.0,
              ),
            ],
            monthlyFrequency: [
              MonthlyDataPoint(
                month: DateTime(2023, 1, 1),
                value: 2.0,
              ),
            ],
            lastUpdated: DateTime(2023, 1, 1),
          );

          final map = insights.toMap();
          final restored = ExerciseInsights.fromMap(map);

          expect(restored.exerciseName, insights.exerciseName);
          expect(restored.totalSessions, insights.totalSessions);
          expect(restored.totalSets, insights.totalSets);
          expect(restored.totalReps, insights.totalReps);
          expect(restored.totalWeight, insights.totalWeight);
          expect(restored.maxWeight, insights.maxWeight);
          expect(restored.averageWeight, insights.averageWeight);
          expect(restored.averageReps, insights.averageReps);
          expect(restored.averageSets, insights.averageSets);
          expect(restored.monthlyVolume.length, insights.monthlyVolume.length);
          expect(restored.monthlyMaxWeight.length, insights.monthlyMaxWeight.length);
          expect(restored.monthlyFrequency.length, insights.monthlyFrequency.length);
          expect(restored.lastUpdated, insights.lastUpdated);
        });

        test('should handle empty monthly data', () {
          final insights = ExerciseInsights(
            exerciseName: 'Bench Press',
            totalSessions: 0,
            totalSets: 0,
            totalReps: 0,
            totalWeight: 0.0,
            maxWeight: 0.0,
            averageWeight: 0.0,
            averageReps: 0.0,
            averageSets: 0.0,
            monthlyVolume: [],
            monthlyMaxWeight: [],
            monthlyFrequency: [],
            lastUpdated: DateTime(2023, 1, 1),
          );

          final map = insights.toMap();
          final restored = ExerciseInsights.fromMap(map);

          expect(restored.monthlyVolume, isEmpty);
          expect(restored.monthlyMaxWeight, isEmpty);
          expect(restored.monthlyFrequency, isEmpty);
        });
      });

      group('MonthlyDataPoint', () {
        test('should convert to and from map correctly', () {
          final dataPoint = MonthlyDataPoint(
            month: DateTime(2023, 1, 1),
            value: 100.5,
          );

          final map = dataPoint.toMap();
          final restored = MonthlyDataPoint.fromMap(map);

          expect(restored.month, dataPoint.month);
          expect(restored.value, dataPoint.value);
        });

        test('should handle zero value', () {
          final dataPoint = MonthlyDataPoint(
            month: DateTime(2023, 1, 1),
            value: 0.0,
          );

          final map = dataPoint.toMap();
          final restored = MonthlyDataPoint.fromMap(map);

          expect(restored.value, 0.0);
        });

        test('should handle negative values', () {
          final dataPoint = MonthlyDataPoint(
            month: DateTime(2023, 1, 1),
            value: -50.0,
          );

          final map = dataPoint.toMap();
          final restored = MonthlyDataPoint.fromMap(map);

          expect(restored.value, -50.0);
        });
      });
    });

    group('Edge cases and error handling', () {
      test('should handle very large datasets without performance issues', () async {
        final service = InsightsService();
        await service.clearCache();
        
        // Create a large dataset
        final largeWorkoutList = List.generate(1000, (index) => 
          Workout(
            id: 'workout_$index',
            name: 'Workout $index',
            status: WorkoutStatus.completed,
            startedAt: DateTime.now().subtract(Duration(days: index % 30)),
            completedAt: DateTime.now().subtract(Duration(days: index % 30)).add(Duration(hours: 1)),
            exercises: [
              WorkoutExercise(
                id: 'exercise_$index',
                workoutId: 'workout_$index',
                exerciseSlug: 'test-exercise',
                sets: [
                  WorkoutSet(
                    id: 'set_$index',
                    workoutExerciseId: 'exercise_$index',
                    setIndex: 0,
                    actualReps: 10,
                    actualWeight: 100.0,
                    isCompleted: true,
                  ),
                ],
              ),
            ],
          ),
        );
        
        service.setWorkoutsProvider(() async => largeWorkoutList);
        
        final stopwatch = Stopwatch()..start();
        final insights = await service.getWorkoutInsights(monthsBack: 1);
        stopwatch.stop();
        
        expect(insights, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
      });

      test('should handle workouts with extreme date values', () async {
        final service = InsightsService();
        await service.clearCache();
        
        final extremeWorkouts = [
          Workout(
            id: 'future-workout',
            name: 'Future Workout',
            status: WorkoutStatus.completed,
            startedAt: DateTime(2030, 1, 1), // Future date
            completedAt: DateTime(2030, 1, 1, 1),
            exercises: [],
          ),
          Workout(
            id: 'past-workout',
            name: 'Ancient Workout',
            status: WorkoutStatus.completed,
            startedAt: DateTime(1990, 1, 1), // Very old date
            completedAt: DateTime(1990, 1, 1, 1),
            exercises: [],
          ),
        ];
        
        service.setWorkoutsProvider(() async => extremeWorkouts);
        
        final insights = await service.getWorkoutInsights(monthsBack: 1);
        
        expect(insights, isNotNull);
        expect(insights.totalWorkouts, 0); // Should filter out extreme dates
      });

      test('should handle workouts with null startedAt', () async {
        final service = InsightsService();
        await service.clearCache();
        
        final workoutsWithNullDates = [
          Workout(
            id: 'null-date-workout',
            name: 'Null Date Workout',
            status: WorkoutStatus.completed,
            startedAt: null, // Null start date
            completedAt: DateTime.now(),
            exercises: [],
          ),
        ];
        
        service.setWorkoutsProvider(() async => workoutsWithNullDates);
        
        final insights = await service.getWorkoutInsights(monthsBack: 1);
        
        expect(insights, isNotNull);
        expect(insights.totalWorkouts, 0); // Should filter out workouts with null dates
      });

      test('should handle concurrent access gracefully', () async {
        final service = InsightsService();
        final baseDate = DateTime(2023, 6, 15);
        final testWorkouts = [
          Workout(
            id: 'workout1',
            name: 'Test Workout',
            status: WorkoutStatus.completed,
            startedAt: baseDate.subtract(Duration(days: 5)),
            completedAt: baseDate.subtract(Duration(days: 5)).add(Duration(hours: 1)),
            exercises: [],
          ),
          Workout(
            id: 'workout2',
            name: 'Test Workout 2',
            status: WorkoutStatus.completed,
            startedAt: baseDate.subtract(Duration(days: 3)),
            completedAt: baseDate.subtract(Duration(days: 3)).add(Duration(hours: 1)),
            exercises: [],
          ),
        ];
        
        // Provider that introduces a delay to make concurrency more likely
        service.setWorkoutsProvider(() async {
          await Future.delayed(Duration(milliseconds: 50));
          return testWorkouts;
        });
        
        // Simulate concurrent access
        final futures = List.generate(10, (index) => 
          service.getWorkoutInsights(monthsBack: 1)
        );
        
        final results = await Future.wait(futures);
        
        // All results should be consistent and correct
        for (final result in results) {
          expect(result.totalWorkouts, 2);
        }
      });
    });

    group('Input validation', () {
      test('should handle empty exercise name', () async {
        final service = InsightsService();
        final baseDate = DateTime(2023, 6, 15);
        final testWorkouts = [
          Workout(
            id: 'workout1',
            name: 'Test Workout',
            status: WorkoutStatus.completed,
            startedAt: baseDate.subtract(Duration(days: 5)),
            completedAt: baseDate.subtract(Duration(days: 5)).add(Duration(hours: 1)),
            exercises: [
              WorkoutExercise(
                id: 'exercise1',
                workoutId: 'workout1',
                exerciseSlug: 'bench-press',
                sets: [],
              ),
            ],
          ),
        ];
        service.setWorkoutsProvider(() async => testWorkouts);
        
        final insights = await service.getExerciseInsights(
          exerciseName: '',
          monthsBack: 1,
        );
        
        expect(insights, isNotNull);
        expect(insights.totalSessions, 0);
      });

      test('should handle whitespace-only exercise name', () async {
        final service = InsightsService();
        final baseDate = DateTime(2023, 6, 15);
        final testWorkouts = [
          Workout(
            id: 'workout1',
            name: 'Test Workout',
            status: WorkoutStatus.completed,
            startedAt: baseDate.subtract(Duration(days: 5)),
            completedAt: baseDate.subtract(Duration(days: 5)).add(Duration(hours: 1)),
            exercises: [
              WorkoutExercise(
                id: 'exercise1',
                workoutId: 'workout1',
                exerciseSlug: 'bench-press',
                sets: [],
              ),
            ],
          ),
        ];
        service.setWorkoutsProvider(() async => testWorkouts);
        
        final insights = await service.getExerciseInsights(
          exerciseName: '   ',
          monthsBack: 1,
        );
        
        expect(insights, isNotNull);
        expect(insights.totalSessions, 0);
      });

      test('should handle special characters in exercise name', () async {
        final service = InsightsService();
        await service.clearCache();
        
        final specialCharWorkouts = [
          Workout(
            id: 'special-workout',
            name: 'Special Workout',
            status: WorkoutStatus.completed,
            startedAt: DateTime.now().subtract(Duration(days: 1)),
            completedAt: DateTime.now().subtract(Duration(days: 1)).add(Duration(hours: 1)),
            exercises: [
              WorkoutExercise(
                id: 'special-exercise',
                workoutId: 'special-workout',
                exerciseSlug: 'test-exercise-@#\$%',
                sets: [
                  WorkoutSet(
                    id: 'special-set',
                    workoutExerciseId: 'special-exercise',
                    setIndex: 0,
                    actualReps: 10,
                    actualWeight: 100.0,
                    isCompleted: true,
                  ),
                ],
              ),
            ],
          ),
        ];
        
        service.setWorkoutsProvider(() async => specialCharWorkouts);
        
        final insights = await service.getExerciseInsights(
          exerciseName: 'test-exercise-@#\$%',
          monthsBack: 1,
        );
        
        expect(insights, isNotNull);
        expect(insights.totalSessions, 1);
      });
    });
  });
}
