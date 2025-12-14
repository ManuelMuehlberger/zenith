import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/services/dao/exercise_dao.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';
import 'package:zenith/services/exercise_service.dart';

// Generate mocks
@GenerateMocks([ExerciseDao, MuscleGroupDao])
import 'exercise_service_test.mocks.dart';

void main() {
  group('ExerciseService Tests', () {
    late ExerciseService exerciseService;
    late MockExerciseDao mockExerciseDao;
    late MockMuscleGroupDao mockMuscleGroupDao;
    late List<Exercise> testExercises;
    late List<MuscleGroup> testMuscleGroups;

    setUp(() {
      // Create mock DAOs
      mockExerciseDao = MockExerciseDao();
      mockMuscleGroupDao = MockMuscleGroupDao();
      
      // Create test data
      testExercises = [
        Exercise(
          slug: 'bench-press',
          name: 'Bench Press',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [MuscleGroup.triceps],
          instructions: ['Lie on bench', 'Press bar up'],
          image: 'bench_press.jpg',
          animation: 'bench_press.gif',
          isBodyWeightExercise: false,
        ),
        Exercise(
          slug: 'push-up',
          name: 'Push Up',
          primaryMuscleGroup: MuscleGroup.chest,
          secondaryMuscleGroups: [MuscleGroup.triceps, MuscleGroup.shoulders],
          instructions: ['Place hands on floor', 'Push body up'],
          image: 'pushup.jpg',
          animation: 'pushup.gif',
          isBodyWeightExercise: true,
        ),
        Exercise(
          slug: 'squat',
          name: 'Squat',
          primaryMuscleGroup: MuscleGroup.quads,
          secondaryMuscleGroups: [MuscleGroup.glutes, MuscleGroup.hamstrings],
          instructions: ['Stand with feet shoulder-width apart', 'Squat down'],
          image: 'squat.jpg',
          animation: 'squat.gif',
          isBodyWeightExercise: true,
        ),
        Exercise(
          slug: 'deadlift',
          name: 'Deadlift',
          primaryMuscleGroup: MuscleGroup.back,
          secondaryMuscleGroups: [MuscleGroup.hamstrings, MuscleGroup.glutes],
          instructions: ['Stand with feet hip-width apart', 'Lift bar from ground'],
          image: 'deadlift.jpg',
          animation: 'deadlift.gif',
          isBodyWeightExercise: false,
        ),
      ];

      testMuscleGroups = [
        MuscleGroup.chest,
        MuscleGroup.triceps,
        MuscleGroup.quads,
        MuscleGroup.glutes,
        MuscleGroup.back,
        MuscleGroup.hamstrings,
        MuscleGroup.shoulders,
      ];

      // Initialize the exercise service with mocked dependencies
      exerciseService = ExerciseService.withDependencies(
        exerciseDao: mockExerciseDao,
        muscleGroupDao: mockMuscleGroupDao,
      );
    });

    test('should initialize exercise service with dependencies', () {
      expect(exerciseService, isNotNull);
      expect(exerciseService.exercises, isEmpty);
      expect(exerciseService.allMuscleGroups, isEmpty);
    });

    test('singleton should return same instance', () {
      final service1 = ExerciseService();
      final service2 = ExerciseService();
      expect(service1, same(service2));
    });

    group('loadExercises', () {
      test('should load exercises and muscle groups successfully', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);

        // Act
        await exerciseService.loadExercises();

        // Assert
        verify(mockExerciseDao.getAllExercises()).called(1);
        verify(mockMuscleGroupDao.getAllMuscleGroups()).called(1);
        
        expect(exerciseService.exercises, hasLength(4));
        expect(exerciseService.exercises, containsAll(testExercises));
        
        expect(exerciseService.allMuscleGroups, hasLength(7));
        expect(exerciseService.allMuscleGroups, contains('Chest'));
        expect(exerciseService.allMuscleGroups, contains('Back'));
        expect(exerciseService.allMuscleGroups, contains('Quads'));
        
        // Verify muscle groups are sorted
        final sortedNames = testMuscleGroups.map((mg) => mg.name).toList()..sort();
        expect(exerciseService.allMuscleGroups, equals(sortedNames));
      });

      test('should handle empty exercise list', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => []);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => []);

        // Act
        await exerciseService.loadExercises();

        // Assert
        verify(mockExerciseDao.getAllExercises()).called(1);
        verify(mockMuscleGroupDao.getAllMuscleGroups()).called(1);
        
        expect(exerciseService.exercises, isEmpty);
        expect(exerciseService.allMuscleGroups, isEmpty);
      });

      test('should handle exception when loading exercises', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenThrow(Exception('Database error'));
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);

        // Act
        await exerciseService.loadExercises();

        // Assert
        verify(mockExerciseDao.getAllExercises()).called(1);
        // MuscleGroup DAO should still be called since errors are handled independently
        verify(mockMuscleGroupDao.getAllMuscleGroups()).called(1);
        
        expect(exerciseService.exercises, isEmpty);
        expect(exerciseService.allMuscleGroups, hasLength(7)); // Muscle groups should still load
      });

      test('should handle exception when loading muscle groups', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenThrow(Exception('Database error'));

        // Act
        await exerciseService.loadExercises();

        // Assert
        verify(mockExerciseDao.getAllExercises()).called(1);
        verify(mockMuscleGroupDao.getAllMuscleGroups()).called(1);
        
        expect(exerciseService.exercises, hasLength(4)); // Exercises should still load
        expect(exerciseService.allMuscleGroups, isEmpty); // Only muscle groups should be empty
      });

      test('should handle exception when both DAOs fail', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenThrow(Exception('Exercise DAO error'));
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenThrow(Exception('MuscleGroup DAO error'));

        // Act
        await exerciseService.loadExercises();

        // Assert
        verify(mockExerciseDao.getAllExercises()).called(1);
        // MuscleGroup DAO should still be called since errors are handled independently
        verify(mockMuscleGroupDao.getAllMuscleGroups()).called(1);
        
        expect(exerciseService.exercises, isEmpty);
        expect(exerciseService.allMuscleGroups, isEmpty);
      });
    });

    group('searchExercises', () {
      setUp(() async {
        // Load test data into service
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);
        await exerciseService.loadExercises();
      });

      test('should return all exercises when query is empty', () {
        // Act
        final result = exerciseService.searchExercises('');

        // Assert
        expect(result, hasLength(4));
        expect(result, containsAll(testExercises));
      });

      test('should filter exercises by name (exact match)', () {
        // Act
        final result = exerciseService.searchExercises('Bench Press');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, equals('Bench Press'));
      });

      test('should filter exercises by name (partial match)', () {
        // Act
        final result = exerciseService.searchExercises('Press');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, equals('Bench Press'));
      });

      test('should filter exercises by primary muscle group', () {
        // Act
        final result = exerciseService.searchExercises('Chest');

        // Assert
        expect(result, hasLength(2));
        expect(result.every((e) => e.primaryMuscleGroup == MuscleGroup.chest), isTrue);
        expect(result.map((e) => e.name), containsAll(['Bench Press', 'Push Up']));
      });

      test('should handle case-insensitive search for exercise name', () {
        // Act
        final result1 = exerciseService.searchExercises('BENCH');
        final result2 = exerciseService.searchExercises('bench');
        final result3 = exerciseService.searchExercises('BeNcH');

        // Assert
        expect(result1, hasLength(1));
        expect(result2, hasLength(1));
        expect(result3, hasLength(1));
        expect(result1.first.name, equals('Bench Press'));
        expect(result2.first.name, equals('Bench Press'));
        expect(result3.first.name, equals('Bench Press'));
      });

      test('should handle case-insensitive search for muscle group', () {
        // Act
        final result1 = exerciseService.searchExercises('CHEST');
        final result2 = exerciseService.searchExercises('chest');
        final result3 = exerciseService.searchExercises('ChEsT');

        // Assert
        expect(result1, hasLength(2));
        expect(result2, hasLength(2));
        expect(result3, hasLength(2));
        expect(result1.every((e) => e.primaryMuscleGroup == MuscleGroup.chest), isTrue);
        expect(result2.every((e) => e.primaryMuscleGroup == MuscleGroup.chest), isTrue);
        expect(result3.every((e) => e.primaryMuscleGroup == MuscleGroup.chest), isTrue);
      });

      test('should return empty list for non-matching query', () {
        // Act
        final result = exerciseService.searchExercises('NonExistentExercise');

        // Assert
        expect(result, isEmpty);
      });

      test('should handle partial matches in exercise names', () {
        // Act
        final result = exerciseService.searchExercises('Up');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, equals('Push Up'));
      });

      test('should handle queries that match both name and muscle group', () {
        // Act - searching for 'qu' should match 'Squat' (name) and 'Quads' (muscle group)
        final result = exerciseService.searchExercises('qu');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, equals('Squat'));
      });

      test('should handle whitespace in queries', () {
        // Act
        final result1 = exerciseService.searchExercises(' Bench ');
        final result2 = exerciseService.searchExercises('  ');

        // Assert
        expect(result1, hasLength(1));
        expect(result1.first.name, equals('Bench Press'));
        expect(result2, hasLength(4)); // Empty query after trim should return all
      });

      test('should search by secondary muscle groups', () {
        // Act - search for 'Triceps' which is a secondary muscle group for both chest exercises
        final result = exerciseService.searchExercises('Triceps');

        // Assert
        expect(result, hasLength(2));
        expect(result.map((e) => e.name), containsAll(['Bench Press', 'Push Up']));
        expect(result.every((e) => e.secondaryMuscleGroups.contains(MuscleGroup.triceps)), isTrue);
      });

      test('should handle multiple matching criteria', () {
        // Act - search for 'Chest' which matches both primary muscle group and could be in names
        final result = exerciseService.searchExercises('Chest');

        // Assert
        expect(result, hasLength(2));
        expect(result.every((e) => e.primaryMuscleGroup == MuscleGroup.chest), isTrue);
      });

      test('should return exercises in consistent order', () {
        // Act - perform same search multiple times
        final result1 = exerciseService.searchExercises('');
        final result2 = exerciseService.searchExercises('');

        // Assert - should return exercises in same order
        expect(result1.length, equals(result2.length));
        for (int i = 0; i < result1.length; i++) {
          expect(result1[i].slug, equals(result2[i].slug));
        }
      });
    });

    group('filterByMuscleGroup', () {
      setUp(() async {
        // Load test data into service
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);
        await exerciseService.loadExercises();
      });

      test('should return all exercises when muscle group is empty', () {
        // Act
        final result = exerciseService.filterByMuscleGroup('');

        // Assert
        expect(result, hasLength(4));
        expect(result, containsAll(testExercises));
      });

      test('should filter exercises by primary muscle group (exact match)', () {
        // Act
        final result = exerciseService.filterByMuscleGroup('Chest');

        // Assert
        expect(result, hasLength(2));
        expect(result.every((e) => e.primaryMuscleGroup == MuscleGroup.chest), isTrue);
        expect(result.map((e) => e.name), containsAll(['Bench Press', 'Push Up']));
      });

      test('should filter exercises by primary muscle group (case insensitive)', () {
        // Act
        final result1 = exerciseService.filterByMuscleGroup('CHEST');
        final result2 = exerciseService.filterByMuscleGroup('chest');
        final result3 = exerciseService.filterByMuscleGroup('ChEsT');

        // Assert
        expect(result1, hasLength(2));
        expect(result2, hasLength(2));
        expect(result3, hasLength(2));
        expect(result1.every((e) => e.primaryMuscleGroup == MuscleGroup.chest), isTrue);
        expect(result2.every((e) => e.primaryMuscleGroup == MuscleGroup.chest), isTrue);
        expect(result3.every((e) => e.primaryMuscleGroup == MuscleGroup.chest), isTrue);
      });

      test('should return empty list for non-existent muscle group', () {
        // Act
        final result = exerciseService.filterByMuscleGroup('NonExistentMuscle');

        // Assert
        expect(result, isEmpty);
      });

      test('should filter by single exercise muscle group', () {
        // Act
        final result = exerciseService.filterByMuscleGroup('Quads');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, equals('Squat'));
        expect(result.first.primaryMuscleGroup, equals(MuscleGroup.quads));
      });

      test('should filter by back muscle group', () {
        // Act
        final result = exerciseService.filterByMuscleGroup('Back');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, equals('Deadlift'));
        expect(result.first.primaryMuscleGroup, equals(MuscleGroup.back));
      });

      test('should handle whitespace in muscle group filter', () {
        // Act
        final result1 = exerciseService.filterByMuscleGroup(' Chest ');
        final result2 = exerciseService.filterByMuscleGroup('  ');

        // Assert
        expect(result1, hasLength(2));
        expect(result1.every((e) => e.primaryMuscleGroup == MuscleGroup.chest), isTrue);
        expect(result2, hasLength(4)); // Empty filter should return all
      });
    });

    group('allMuscleGroups getter', () {
      test('should return empty list when no muscle groups loaded', () {
        // Act
        final result = exerciseService.allMuscleGroups;

        // Assert
        expect(result, isEmpty);
        expect(result, isA<List<String>>());
      });

      test('should return sorted muscle group names after loading', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);

        // Act
        await exerciseService.loadExercises();
        final result = exerciseService.allMuscleGroups;

        // Assert
        expect(result, isA<List<String>>());
        expect(result, hasLength(7));
        
        // Verify sorting
        final expectedSorted = testMuscleGroups.map((mg) => mg.name).toList()..sort();
        expect(result, equals(expectedSorted));
        
        // Verify specific muscle groups are present
        expect(result, contains('Back'));
        expect(result, contains('Chest'));
        expect(result, contains('Glutes'));
        expect(result, contains('Hamstrings'));
        expect(result, contains('Quads'));
        expect(result, contains('Shoulders'));
        expect(result, contains('Triceps'));
      });

      test('should maintain sorted order with duplicate muscle groups', () async {
        // Arrange - create muscle groups with duplicates
        final duplicateMuscleGroups = [
          MuscleGroup.chest,
          MuscleGroup.back,
          MuscleGroup.chest, // duplicate
          MuscleGroup.quads,
          MuscleGroup.back, // duplicate
        ];
        
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => []);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => duplicateMuscleGroups);

        // Act
        await exerciseService.loadExercises();
        final result = exerciseService.allMuscleGroups;

        // Assert
        expect(result, hasLength(5)); // Should include duplicates
        expect(result, equals(['Back', 'Back', 'Chest', 'Chest', 'Quads']));
      });
    });

    group('exercises getter', () {
      test('should return empty list when no exercises loaded', () {
        // Act
        final result = exerciseService.exercises;

        // Assert
        expect(result, isEmpty);
        expect(result, isA<List<Exercise>>());
      });

      test('should return loaded exercises', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);

        // Act
        await exerciseService.loadExercises();
        final result = exerciseService.exercises;

        // Assert
        expect(result, isA<List<Exercise>>());
        expect(result, hasLength(4));
        expect(result, containsAll(testExercises));
        
        // Verify specific exercises
        expect(result.map((e) => e.name), containsAll([
          'Bench Press',
          'Push Up',
          'Squat',
          'Deadlift'
        ]));
      });

      test('should return reference to internal list', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);

        // Act
        await exerciseService.loadExercises();
        final result1 = exerciseService.exercises;
        final result2 = exerciseService.exercises;

        // Assert - should return same reference
        expect(identical(result1, result2), isTrue);
      });
    });

    group('edge cases and error handling', () {
      test('should handle null or malformed data gracefully', () async {
        // Arrange - simulate malformed data that might cause issues
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => []);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => []);

        // Act
        await exerciseService.loadExercises();

        // Assert - should not throw and should have empty collections
        expect(exerciseService.exercises, isEmpty);
        expect(exerciseService.allMuscleGroups, isEmpty);
        expect(() => exerciseService.searchExercises('test'), returnsNormally);
        expect(() => exerciseService.filterByMuscleGroup('test'), returnsNormally);
      });

      test('should handle very long search queries', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);
        await exerciseService.loadExercises();

        // Act
        final longQuery = 'a' * 1000; // Very long query
        final result = exerciseService.searchExercises(longQuery);

        // Assert
        expect(result, isEmpty);
        expect(() => exerciseService.searchExercises(longQuery), returnsNormally);
      });

      test('should handle special characters in search queries', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);
        await exerciseService.loadExercises();

        // Act & Assert
        expect(() => exerciseService.searchExercises('!@#\$%^&*()'), returnsNormally);
        expect(() => exerciseService.searchExercises('weightlifter'), returnsNormally);
        expect(() => exerciseService.filterByMuscleGroup('!@#\$%^&*()'), returnsNormally);
        
        final result1 = exerciseService.searchExercises('!@#\$%^&*()');
        final result2 = exerciseService.filterByMuscleGroup('weightlifter');
        
        expect(result1, isEmpty);
        expect(result2, isEmpty);
      });

      test('should handle concurrent loadExercises calls', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return testExercises;
        });
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50));
          return testMuscleGroups;
        });

        // Act - call loadExercises multiple times concurrently
        final futures = [
          exerciseService.loadExercises(),
          exerciseService.loadExercises(),
          exerciseService.loadExercises(),
        ];
        await Future.wait(futures);

        // Assert - should handle concurrent calls gracefully
        expect(exerciseService.exercises, hasLength(4));
        expect(exerciseService.allMuscleGroups, hasLength(7));
        
        // Verify DAOs were called multiple times (once per concurrent call)
        verify(mockExerciseDao.getAllExercises()).called(3);
        verify(mockMuscleGroupDao.getAllMuscleGroups()).called(3);
      });

      test('should maintain state consistency after partial failures', () async {
        // Arrange - first call succeeds, second call fails for exercises
        when(mockExerciseDao.getAllExercises())
            .thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups())
            .thenAnswer((_) async => testMuscleGroups);

        // Act - first successful load
        await exerciseService.loadExercises();
        expect(exerciseService.exercises, hasLength(4));
        expect(exerciseService.allMuscleGroups, hasLength(7));

        // Arrange - second call fails for exercises
        when(mockExerciseDao.getAllExercises())
            .thenThrow(Exception('Database error'));

        // Act - second load with exercise failure
        await exerciseService.loadExercises();

        // Assert - exercises should be cleared but muscle groups should still be loaded
        expect(exerciseService.exercises, isEmpty);
        expect(exerciseService.allMuscleGroups, hasLength(7));
      });
    });

    group('performance and behavior tests', () {
      test('should handle large datasets efficiently', () async {
        // Arrange - create a large dataset
        final largeExerciseList = List.generate(1000, (index) => Exercise(
          slug: 'exercise-$index',
          name: 'Exercise $index',
          primaryMuscleGroup: MuscleGroup.values[index % MuscleGroup.values.length],
          secondaryMuscleGroups: [],
          instructions: ['Instruction $index'],
          image: 'image$index.jpg',
          animation: 'animation$index.gif',
          isBodyWeightExercise: index % 2 == 0,
        ));

        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => largeExerciseList);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);

        // Act
        final stopwatch = Stopwatch()..start();
        await exerciseService.loadExercises();
        final loadTime = stopwatch.elapsedMilliseconds;

        stopwatch.reset();
        final searchResult = exerciseService.searchExercises('Exercise 1');
        final searchTime = stopwatch.elapsedMilliseconds;

        stopwatch.reset();
        final filterResult = exerciseService.filterByMuscleGroup('Chest');
        final filterTime = stopwatch.elapsedMilliseconds;

        // Assert - operations should complete in reasonable time
        expect(loadTime, lessThan(1000)); // Less than 1 second
        expect(searchTime, lessThan(100)); // Less than 100ms
        expect(filterTime, lessThan(100)); // Less than 100ms
        
        expect(exerciseService.exercises, hasLength(1000));
        expect(searchResult, isNotEmpty);
        expect(filterResult, isNotEmpty);
      });

      test('should return immutable results from search and filter', () async {
        // Arrange
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
        when(mockMuscleGroupDao.getAllMuscleGroups()).thenAnswer((_) async => testMuscleGroups);
        await exerciseService.loadExercises();

        // Act
        final searchResult = exerciseService.searchExercises('Chest');
        final filterResult = exerciseService.filterByMuscleGroup('Chest');

        // Assert - modifying results should not affect internal state
        searchResult.clear();
        filterResult.clear();
        
        expect(exerciseService.exercises, hasLength(4)); // Should remain unchanged
        expect(exerciseService.searchExercises('Chest'), hasLength(2)); // Should still work
        expect(exerciseService.filterByMuscleGroup('Chest'), hasLength(2)); // Should still work
      });
    });
  });
}
