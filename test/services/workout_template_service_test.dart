import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zenith/models/workout_template.dart';
import 'package:zenith/models/workout_folder.dart';
import 'package:zenith/services/workout_template_service.dart';
import 'package:zenith/services/dao/workout_template_dao.dart';
import 'package:zenith/services/dao/workout_folder_dao.dart';

// Generate mocks
@GenerateMocks([WorkoutTemplateDao, WorkoutFolderDao])
import 'workout_template_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutTemplateService Tests', () {
    late WorkoutTemplateService service;
    late MockWorkoutTemplateDao mockTemplateDao;
    late MockWorkoutFolderDao mockFolderDao;
    late WorkoutTemplate testTemplate;
    late List<WorkoutTemplate> testTemplates;
    late WorkoutFolder testFolder;
    late List<WorkoutFolder> testFolders;

    setUp(() {
      mockTemplateDao = MockWorkoutTemplateDao();
      mockFolderDao = MockWorkoutFolderDao();
      service = WorkoutTemplateService(
        workoutTemplateDao: mockTemplateDao,
        workoutFolderDao: mockFolderDao,
      );

      testTemplate = WorkoutTemplate(
        id: 'template123',
        name: 'Push Day',
        description: 'Focus on push exercises',
        iconCodePoint: 0xe1a3,
        colorValue: 0xFF2196F3,
        folderId: 'folder123',
        notes: 'Warm up properly',
        orderIndex: 1,
      );

      testTemplates = [
        testTemplate,
        WorkoutTemplate(
          id: 'template456',
          name: 'Pull Day',
          folderId: 'folder123',
          orderIndex: 2,
        ),
        WorkoutTemplate(
          id: 'template789',
          name: 'Leg Day',
          folderId: 'folder456',
          orderIndex: 1,
        ),
      ];

      testFolder = WorkoutFolder(
        id: 'folder123',
        name: 'Upper Body',
        orderIndex: 0,
      );

      testFolders = [
        testFolder,
        WorkoutFolder(
          id: 'folder456',
          name: 'Lower Body',
          orderIndex: 1,
        ),
      ];
    });

    test('should be a singleton', () {
      final service1 = WorkoutTemplateService();
      final service2 = WorkoutTemplateService();
      expect(service1, same(service2));
    });

    test('getAllWorkoutTemplates should return all templates ordered', () async {
      when(mockTemplateDao.getAllWorkoutTemplatesOrdered())
          .thenAnswer((_) async => testTemplates);

      final result = await service.getAllWorkoutTemplates();

      expect(result, testTemplates);
      verify(mockTemplateDao.getAllWorkoutTemplatesOrdered()).called(1);
    });

    test('getWorkoutTemplatesByFolder should return templates for a specific folder',
        () async {
      const folderId = 'folder123';
      final expected =
          testTemplates.where((t) => t.folderId == folderId).toList();
      when(mockTemplateDao.getWorkoutTemplatesByFolderId(folderId))
          .thenAnswer((_) async => expected);

      final result = await service.getWorkoutTemplatesByFolder(folderId);

      expect(result, expected);
      verify(mockTemplateDao.getWorkoutTemplatesByFolderId(folderId)).called(1);
    });

    test('getWorkoutTemplatesWithoutFolder should return templates with no folder',
        () async {
      final expected =
          testTemplates.where((t) => t.folderId == null).toList();
      when(mockTemplateDao.getWorkoutTemplatesWithoutFolder())
          .thenAnswer((_) async => expected);

      final result = await service.getWorkoutTemplatesWithoutFolder();

      expect(result, expected);
      verify(mockTemplateDao.getWorkoutTemplatesWithoutFolder()).called(1);
    });

    test('getWorkoutTemplateById should return a template when found', () async {
      when(mockTemplateDao.getWorkoutTemplateById('template123'))
          .thenAnswer((_) async => testTemplate);

      final result = await service.getWorkoutTemplateById('template123');

      expect(result, testTemplate);
      verify(mockTemplateDao.getWorkoutTemplateById('template123')).called(1);
    });

    test('getWorkoutTemplateById should return null when not found', () async {
      when(mockTemplateDao.getWorkoutTemplateById('not-found'))
          .thenAnswer((_) async => null);

      final result = await service.getWorkoutTemplateById('not-found');

      expect(result, isNull);
      verify(mockTemplateDao.getWorkoutTemplateById('not-found')).called(1);
    });

    test('createWorkoutTemplate should create and return a new template',
        () async {
      when(mockTemplateDao.insert(any)).thenAnswer((_) async => 1);

      final newTemplate = await service.createWorkoutTemplate(
        name: 'New Workout',
        description: 'A new workout for testing',
      );

      expect(newTemplate.name, 'New Workout');
      expect(newTemplate.description, 'A new workout for testing');
      verify(mockTemplateDao.insert(any)).called(1);
    });

    test('updateWorkoutTemplate should call the dao to update', () async {
      when(mockTemplateDao.updateWorkoutTemplate(testTemplate)).thenAnswer((_) async => 1);

      await service.updateWorkoutTemplate(testTemplate);

      verify(mockTemplateDao.updateWorkoutTemplate(testTemplate)).called(1);
    });

    test('deleteWorkoutTemplate should call the dao to delete', () async {
      when(mockTemplateDao.deleteWorkoutTemplate('template123')).thenAnswer((_) async => 1);

      await service.deleteWorkoutTemplate('template123');

      verify(mockTemplateDao.deleteWorkoutTemplate('template123')).called(1);
    });

    test('markTemplateAsUsed should update the lastUsed timestamp', () async {
      when(mockTemplateDao.updateLastUsed(any, any)).thenAnswer((_) async => 1);

      await service.markTemplateAsUsed('template123');

      verify(mockTemplateDao.updateLastUsed(
        'template123',
        argThat(isA<String>()),
      )).called(1);
    });

    test('getRecentlyUsedTemplates should return a list of templates', () async {
      when(mockTemplateDao.getWorkoutTemplatesByLastUsed(limit: 5))
          .thenAnswer((_) async => testTemplates);

      final result = await service.getRecentlyUsedTemplates(limit: 5);

      expect(result, testTemplates);
      verify(mockTemplateDao.getWorkoutTemplatesByLastUsed(limit: 5)).called(1);
    });

    test('moveTemplateToFolder should update the template folderId', () async {
      when(mockTemplateDao.getWorkoutTemplateById('template123'))
          .thenAnswer((_) async => testTemplate);
      when(mockTemplateDao.updateWorkoutTemplate(any)).thenAnswer((_) async => 1);

      await service.moveTemplateToFolder('template123', 'new-folder');

      final verification =
          verify(mockTemplateDao.updateWorkoutTemplate(captureAny));
      verification.called(1);
      expect(verification.captured.single.folderId, 'new-folder');
    });

    test('duplicateTemplate should create a copy of a template', () async {
      when(mockTemplateDao.getWorkoutTemplateById('template123'))
          .thenAnswer((_) async => testTemplate);
      when(mockTemplateDao.insert(any)).thenAnswer((_) async => 1);

      final newTemplate = await service.duplicateTemplate('template123');

      expect(newTemplate.name, '${testTemplate.name} (Copy)');
      expect(newTemplate.id, isNot(testTemplate.id));
      verify(mockTemplateDao.insert(any)).called(1);
    });

    test('getTemplateCountByFolder should return a map of folder counts',
        () async {
      when(mockTemplateDao.getAllWorkoutTemplatesOrdered())
          .thenAnswer((_) async => testTemplates);

      final result = await service.getTemplateCountByFolder();

      expect(result, {
        'folder123': 2,
        'folder456': 1,
      });
      verify(mockTemplateDao.getAllWorkoutTemplatesOrdered()).called(1);
    });

    group('Folder Operations', () {
      test('loadFolders should load folders into cache', () async {
        when(mockFolderDao.getAllWorkoutFoldersOrdered())
            .thenAnswer((_) async => testFolders);

        await service.loadFolders();

        expect(service.folders, testFolders);
        verify(mockFolderDao.getAllWorkoutFoldersOrdered()).called(1);
      });

      test('getFolderById should return folder when found', () async {
        // Set up folders in cache first
        when(mockFolderDao.getAllWorkoutFoldersOrdered())
            .thenAnswer((_) async => testFolders);
        await service.loadFolders();

        final result = service.getFolderById('folder123');

        expect(result, testFolder);
      });

      test('getFolderById should return null when not found', () async {
        // Set up folders in cache first
        when(mockFolderDao.getAllWorkoutFoldersOrdered())
            .thenAnswer((_) async => testFolders);
        await service.loadFolders();

        final result = service.getFolderById('not-found');

        expect(result, isNull);
      });

      test('createFolder should create and return a new folder', () async {
        when(mockFolderDao.insert(any)).thenAnswer((_) async => 1);

        final newFolder = await service.createFolder('New Folder');

        expect(newFolder.name, 'New Folder');
        verify(mockFolderDao.insert(any)).called(1);
      });

      test('updateFolder should call the dao to update', () async {
        when(mockFolderDao.updateWorkoutFolder(testFolder))
            .thenAnswer((_) async => 1);

        await service.updateFolder(testFolder);

        verify(mockFolderDao.updateWorkoutFolder(testFolder)).called(1);
      });

      test('deleteFolder should delete folder and move templates out', () async {
        final templatesInFolder = [testTemplate];
        when(mockTemplateDao.getWorkoutTemplatesByFolderId('folder123'))
            .thenAnswer((_) async => templatesInFolder);
        when(mockTemplateDao.updateWorkoutTemplate(any))
            .thenAnswer((_) async => 1);
        when(mockFolderDao.deleteWorkoutFolder('folder123'))
            .thenAnswer((_) async => 1);

        await service.deleteFolder('folder123');

        verify(mockTemplateDao.getWorkoutTemplatesByFolderId('folder123')).called(1);
        verify(mockTemplateDao.updateWorkoutTemplate(any)).called(1);
        verify(mockFolderDao.deleteWorkoutFolder('folder123')).called(1);
      });

      test('reorderFolders should reorder folders successfully', () async {
        // Set up folders in cache first
        when(mockFolderDao.getAllWorkoutFoldersOrdered())
            .thenAnswer((_) async => testFolders);
        await service.loadFolders();
        
        when(mockFolderDao.updateWorkoutFolder(any))
            .thenAnswer((_) async => 1);

        await service.reorderFolders(0, 1);

        verify(mockFolderDao.updateWorkoutFolder(any)).called(2);
      });

      test('reorderFolders should handle invalid indices', () async {
        // Set up folders in cache first
        when(mockFolderDao.getAllWorkoutFoldersOrdered())
            .thenAnswer((_) async => testFolders);
        await service.loadFolders();

        await service.reorderFolders(-1, 0);
        await service.reorderFolders(0, 5);

        verifyNever(mockFolderDao.updateWorkoutFolder(any));
      });

      test('reorderTemplatesInFolder should reorder templates successfully', () async {
        final templatesInFolder = [
          testTemplate,
          WorkoutTemplate(
            id: 'template456',
            name: 'Pull Day',
            folderId: 'folder123',
            orderIndex: 2,
          ),
        ];
        when(mockTemplateDao.getWorkoutTemplatesByFolderId('folder123'))
            .thenAnswer((_) async => templatesInFolder);
        when(mockTemplateDao.updateWorkoutTemplate(any))
            .thenAnswer((_) async => 1);

        await service.reorderTemplatesInFolder('folder123', 0, 1);

        verify(mockTemplateDao.getWorkoutTemplatesByFolderId('folder123')).called(1);
        verify(mockTemplateDao.updateWorkoutTemplate(any)).called(2);
      });

      test('reorderTemplatesInFolder should handle invalid indices', () async {
        final templatesInFolder = [testTemplate];
        when(mockTemplateDao.getWorkoutTemplatesByFolderId('folder123'))
            .thenAnswer((_) async => templatesInFolder);

        await service.reorderTemplatesInFolder('folder123', -1, 0);
        await service.reorderTemplatesInFolder('folder123', 0, 5);

        verify(mockTemplateDao.getWorkoutTemplatesByFolderId('folder123')).called(2);
        verifyNever(mockTemplateDao.updateWorkoutTemplate(any));
      });

      test('getTemplatesInFolder should return templates for a specific folder', () async {
        final templatesInFolder = [testTemplate];
        when(mockTemplateDao.getWorkoutTemplatesByFolderId('folder123'))
            .thenAnswer((_) async => templatesInFolder);

        final result = await service.getTemplatesInFolder('folder123');

        expect(result, templatesInFolder);
        verify(mockTemplateDao.getWorkoutTemplatesByFolderId('folder123')).called(1);
      });

      test('getTemplatesInFolder should return templates without folder when folderId is null', () async {
        final templatesWithoutFolder = [
          WorkoutTemplate(id: 'template999', name: 'No Folder Template'),
        ];
        when(mockTemplateDao.getWorkoutTemplatesWithoutFolder())
            .thenAnswer((_) async => templatesWithoutFolder);

        final result = await service.getTemplatesInFolder(null);

        expect(result, templatesWithoutFolder);
        verify(mockTemplateDao.getWorkoutTemplatesWithoutFolder()).called(1);
      });
    });
  });
}
