import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/models/workout_folder.dart';
import 'package:zenith/models/workout.dart';
import 'package:zenith/models/exercise.dart';
import 'package:zenith/models/muscle_group.dart';
import 'package:zenith/models/workout_exercise.dart';
import 'package:zenith/models/workout_set.dart';
import 'package:zenith/services/dao/user_dao.dart';
import 'package:zenith/services/dao/weight_entry_dao.dart';
import 'package:zenith/services/dao/workout_dao.dart';
import 'package:zenith/services/dao/workout_folder_dao.dart';
import 'package:zenith/services/dao/workout_exercise_dao.dart';
import 'package:zenith/services/dao/workout_set_dao.dart';
import 'package:zenith/services/dao/exercise_dao.dart';
import 'package:zenith/services/dao/muscle_group_dao.dart';
import 'package:zenith/services/export_import_service.dart';

// Generate mocks for all the DAOs
@GenerateMocks([
  UserDao,
  WeightEntryDao,
  WorkoutDao,
  WorkoutFolderDao,
  WorkoutExerciseDao,
  WorkoutSetDao,
  ExerciseDao,
  MuscleGroupDao,
])
import 'export_import_service_test.mocks.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportImportService Tests', () {
    late ExportImportService exportImportService;
    late MockUserDao mockUserDao;
    late MockWeightEntryDao mockWeightEntryDao;
    late MockWorkoutDao mockWorkoutDao;
    late MockWorkoutFolderDao mockWorkoutFolderDao;
    late MockWorkoutExerciseDao mockWorkoutExerciseDao;
    late MockWorkoutSetDao mockWorkoutSetDao;
    late MockExerciseDao mockExerciseDao;
    late MockMuscleGroupDao mockMuscleGroupDao;

    // Test data
    late UserData testUser;
    late List<WeightEntry> testWeightEntries;
    late List<WorkoutFolder> testWorkoutFolders;
    late List<Workout> testTemplateWorkouts;
    late List<Workout> testCompletedWorkouts;
    late List<Exercise> testExercises;

    setUp(() {
      // Create mock instances
      mockUserDao = MockUserDao();
      mockWeightEntryDao = MockWeightEntryDao();
      mockWorkoutDao = MockWorkoutDao();
      mockWorkoutFolderDao = MockWorkoutFolderDao();
      mockWorkoutExerciseDao = MockWorkoutExerciseDao();
      mockWorkoutSetDao = MockWorkoutSetDao();
      mockExerciseDao = MockExerciseDao();
      mockMuscleGroupDao = MockMuscleGroupDao();

      // Initialize the service with mock DAOs
      exportImportService = ExportImportService.internal(
        mockUserDao,
        mockWeightEntryDao,
        mockWorkoutDao,
        mockWorkoutFolderDao,
        mockWorkoutExerciseDao,
        mockWorkoutSetDao,
        mockExerciseDao,
        mockMuscleGroupDao,
      );
      ExportImportService.setTestInstance(exportImportService);

      // Setup mock for path_provider
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            final tempDir = await Directory.systemTemp.createTemp();
            return tempDir.path;
          }
          return null;
        },
      );

      // Setup mock for share_plus
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'shareFiles') {
            return null; // Simulate success
          }
          return null;
        },
      );

      // Initialize test data
      testWeightEntries = [
        WeightEntry(id: 'w1', timestamp: DateTime(2023, 1, 1), value: 80),
      ];

      testUser = UserData(
        id: 'user1',
        name: 'Test User',
        birthdate: DateTime(1990, 5, 15),
        units: Units.metric,
        weightHistory: testWeightEntries,
        createdAt: DateTime(2023, 1, 1),
        theme: 'dark',
      );

      testWorkoutFolders = [
        WorkoutFolder(id: 'folder1', name: 'Leg Day', orderIndex: 0),
      ];

      final workoutSet = WorkoutSet(id: 'set1', workoutExerciseId: 'we1', setIndex: 0, targetReps: 10, targetWeight: 100);
      final workoutExercise = WorkoutExercise(id: 'we1', workoutId: 't_workout1', exerciseSlug: 'squat', orderIndex: 0, sets: [workoutSet]);
      
      testTemplateWorkouts = [
        Workout(id: 't_workout1', name: 'Template A', folderId: 'folder1', exercises: [workoutExercise]),
      ];

      testCompletedWorkouts = [
        Workout(id: 'c_workout1', name: 'Completed A', startedAt: DateTime(2023, 8, 1), completedAt: DateTime(2023, 8, 1, 1), status: WorkoutStatus.completed, exercises: [workoutExercise]),
      ];

      testExercises = [
        Exercise(
          slug: 'squat', 
          name: 'Squat', 
          primaryMuscleGroup: MuscleGroup.quads,
          secondaryMuscleGroups: [],
          instructions: [],
          image: '',
          animation: '',
        ),
      ];

      // Default mock behaviors
      when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
      when(mockWeightEntryDao.getWeightEntriesByUserId('user1')).thenAnswer((_) async => testWeightEntries);
      when(mockWorkoutFolderDao.getAllWorkoutFoldersOrdered()).thenAnswer((_) async => testWorkoutFolders);
      when(mockWorkoutDao.getTemplateWorkouts()).thenAnswer((_) async => testTemplateWorkouts);
      when(mockWorkoutDao.getCompletedWorkouts()).thenAnswer((_) async => testCompletedWorkouts);
      when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => testExercises);
      when(mockWorkoutExerciseDao.getWorkoutExercisesByWorkoutId(any)).thenAnswer((_) async => [workoutExercise]);
      when(mockWorkoutSetDao.getWorkoutSetsByWorkoutExerciseId(any)).thenAnswer((_) async => [workoutSet]);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'), null);
    });

    test('should initialize export import service', () {
      expect(exportImportService, isNotNull);
    });

    group('exportData', () {
      test('should successfully export all data', () async {
        // This test is more of an integration test due to direct DAO instantiation.
        // We can't inject mocks, so we can't verify calls.
        // We will check the output file path.
        
        // Act
        final filePath = await exportImportService.exportData();

        // Assert
        expect(filePath, isNotNull);
        expect(filePath, contains('workout_tracker_backup_'));
        expect(filePath, endsWith('.json'));

        // Optional: Read the file and verify its contents
        final file = File(filePath!);
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        expect(data['metadata'], isNotNull);
        expect(data['data'], isNotNull);
        
        final metadata = data['metadata'] as Map<String, dynamic>;
        expect(metadata['version'], '1.0.0');
        expect(metadata['dataIntegrity']['checksum'], isNotEmpty);

        final exportData = data['data'] as Map<String, dynamic>;
        expect(exportData['userProfile'], isNotNull);
        expect(exportData['workoutFolders'], isNotEmpty);
        
        // This will fail due to the bug where 'workouts' is overwritten.
        // This test helps identify the bug.
        expect(exportData['workouts'], isNotEmpty);
        expect(exportData['workout_sessions'], isNotEmpty);
      });

      test('should handle no data gracefully', () async {
        // Arrange
        when(mockUserDao.getAll()).thenAnswer((_) async => []);
        when(mockWeightEntryDao.getWeightEntriesByUserId(any)).thenAnswer((_) async => []);
        when(mockWorkoutFolderDao.getAllWorkoutFoldersOrdered()).thenAnswer((_) async => []);
        when(mockWorkoutDao.getTemplateWorkouts()).thenAnswer((_) async => []);
        when(mockWorkoutDao.getCompletedWorkouts()).thenAnswer((_) async => []);
        when(mockExerciseDao.getAllExercises()).thenAnswer((_) async => []);

        // Act
        final filePath = await exportImportService.exportData();
        
        // Assert
        expect(filePath, isNotNull);
        final file = File(filePath!);
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        
        final exportData = data['data'] as Map<String, dynamic>;
        expect(exportData['userProfile'], isNull);
        expect(exportData['workoutFolders'], isEmpty);
        expect(exportData['workouts'], isEmpty);
        expect(exportData['workout_sessions'], isEmpty);
      });

       test('should throw exception if DAO fails', () async {
        // Arrange
        when(mockUserDao.getAll()).thenThrow(Exception('Database connection failed'));

        // Act & Assert
        expect(
          () => exportImportService.exportData(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to export data'),
          )),
        );
      });
    });

    // More tests for importData would follow a similar pattern,
    // mocking FilePicker and verifying DAO interactions.

    group('importData', () {
      // Since we can't inject DAO mocks, we can't verify the insertions.
      // The main goal here is to test the flow, validation, and error handling.
      // We will mock the FilePicker to simulate user actions.

      // TODO: Mock FilePicker and write tests for importData.
      // This is complex because it requires mocking the static method `FilePicker.platform.pickFiles`
      // and creating a temporary file with valid JSON content.
      // Due to the limitations of the current test setup (no dependency injection for DAOs),
      // writing full end-to-end import tests is challenging.
      // The existing structure provides a good foundation for future expansion
      // if the service is refactored to allow for proper dependency injection.
    });
  });
}
