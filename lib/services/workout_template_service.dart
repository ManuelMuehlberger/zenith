import 'package:logging/logging.dart';
import '../models/workout_template.dart';
import '../models/workout_folder.dart';
import '../models/typedefs.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import 'dao/workout_template_dao.dart';
import 'dao/workout_folder_dao.dart';
import 'dao/workout_exercise_dao.dart';
import 'dao/workout_set_dao.dart';

class WorkoutTemplateService {
  static final WorkoutTemplateService _instance = WorkoutTemplateService._internal();
  factory WorkoutTemplateService({
    WorkoutTemplateDao? workoutTemplateDao,
    WorkoutFolderDao? workoutFolderDao,
    WorkoutExerciseDao? workoutExerciseDao,
    WorkoutSetDao? workoutSetDao,
  }) {
    _instance._workoutTemplateDao = workoutTemplateDao ?? WorkoutTemplateDao();
    _instance._workoutFolderDao = workoutFolderDao ?? WorkoutFolderDao();
    _instance._workoutExerciseDao = workoutExerciseDao ?? WorkoutExerciseDao();
    _instance._workoutSetDao = workoutSetDao ?? WorkoutSetDao();
    return _instance;
  }
  WorkoutTemplateService._internal() {
    _workoutTemplateDao = WorkoutTemplateDao();
    _workoutFolderDao = WorkoutFolderDao();
    _workoutExerciseDao = WorkoutExerciseDao();
    _workoutSetDao = WorkoutSetDao();
  }

  static WorkoutTemplateService get instance => _instance;

  late WorkoutTemplateDao _workoutTemplateDao;
  late WorkoutFolderDao _workoutFolderDao;
  late WorkoutExerciseDao _workoutExerciseDao;
  late WorkoutSetDao _workoutSetDao;
  final Logger _logger = Logger('WorkoutTemplateService');

  // Cache for folders
  List<WorkoutFolder> _folders = [];
  List<WorkoutFolder> get folders => _folders;

  /// Get all workout templates ordered by folder and orderIndex
  Future<List<WorkoutTemplate>> getAllWorkoutTemplates() async {
    _logger.fine('Getting all workout templates');
    try {
      final templates = await _workoutTemplateDao.getAllWorkoutTemplatesOrdered();
      _logger.fine('Retrieved ${templates.length} workout templates');
      return templates;
    } catch (e) {
      _logger.severe('Failed to get all workout templates: $e');
      rethrow;
    }
  }

  /// Get workout templates in a specific folder
  Future<List<WorkoutTemplate>> getWorkoutTemplatesByFolder(WorkoutFolderId folderId) async {
    _logger.fine('Getting workout templates for folder: $folderId');
    try {
      final templates = await _workoutTemplateDao.getWorkoutTemplatesByFolderId(folderId);
      _logger.fine('Retrieved ${templates.length} workout templates for folder $folderId');
      return templates;
    } catch (e) {
      _logger.severe('Failed to get workout templates for folder $folderId: $e');
      rethrow;
    }
  }

  /// Get workout templates without a folder
  Future<List<WorkoutTemplate>> getWorkoutTemplatesWithoutFolder() async {
    _logger.fine('Getting workout templates without folder');
    try {
      final templates = await _workoutTemplateDao.getWorkoutTemplatesWithoutFolder();
      _logger.fine('Retrieved ${templates.length} workout templates without folder');
      return templates;
    } catch (e) {
      _logger.severe('Failed to get workout templates without folder: $e');
      rethrow;
    }
  }

  /// Get a specific workout template by ID
  Future<WorkoutTemplate?> getWorkoutTemplateById(WorkoutTemplateId id) async {
    _logger.fine('Getting workout template with id: $id');
    try {
      final template = await _workoutTemplateDao.getWorkoutTemplateById(id);
      if (template != null) {
        _logger.fine('Found workout template with id: $id');
      } else {
        _logger.fine('No workout template found with id: $id');
      }
      return template;
    } catch (e) {
      _logger.severe('Failed to get workout template with id $id: $e');
      rethrow;
    }
  }

  /// Create a new workout template
  Future<WorkoutTemplate> createWorkoutTemplate({
    required String name,
    String? description,
    int? iconCodePoint,
    int? colorValue,
    WorkoutFolderId? folderId,
    String? notes,
    int? orderIndex,
  }) async {
    _logger.fine('Creating new workout template: $name');
    try {
      final template = WorkoutTemplate(
        name: name,
        description: description,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
        folderId: folderId,
        notes: notes,
        orderIndex: orderIndex,
      );

      await _workoutTemplateDao.insert(template);
      _logger.fine('Created workout template with id: ${template.id}');
      return template;
    } catch (e) {
      _logger.severe('Failed to create workout template: $e');
      rethrow;
    }
  }

  /// Update an existing workout template
  Future<void> updateWorkoutTemplate(WorkoutTemplate template) async {
    _logger.fine('Updating workout template with id: ${template.id}');
    try {
      final count = await _workoutTemplateDao.updateWorkoutTemplate(template);
      if (count > 0) {
        _logger.fine('Successfully updated workout template with id: ${template.id}');
      } else {
        _logger.warning('No workout template found to update with id: ${template.id}');
      }
    } catch (e) {
      _logger.severe('Failed to update workout template with id ${template.id}: $e');
      rethrow;
    }
  }

  /// Delete a workout template
  Future<void> deleteWorkoutTemplate(WorkoutTemplateId id) async {
    _logger.fine('Deleting workout template with id: $id');
    try {
      final count = await _workoutTemplateDao.deleteWorkoutTemplate(id);
      if (count > 0) {
        _logger.fine('Successfully deleted workout template with id: $id');
      } else {
        _logger.warning('No workout template found to delete with id: $id');
      }
    } catch (e) {
      _logger.severe('Failed to delete workout template with id $id: $e');
      rethrow;
    }
  }

  /// Update the last used timestamp for a workout template
  Future<void> markTemplateAsUsed(WorkoutTemplateId id) async {
    _logger.fine('Marking workout template as used: $id');
    try {
      final timestamp = DateTime.now().toIso8601String();
      final count = await _workoutTemplateDao.updateLastUsed(id, timestamp);
      if (count > 0) {
        _logger.fine('Successfully updated lastUsed for workout template: $id');
      } else {
        _logger.warning('No workout template found to update lastUsed with id: $id');
      }
    } catch (e) {
      _logger.severe('Failed to update lastUsed for workout template $id: $e');
      rethrow;
    }
  }

  /// Get recently used workout templates
  Future<List<WorkoutTemplate>> getRecentlyUsedTemplates({int limit = 10}) async {
    _logger.fine('Getting recently used workout templates (limit: $limit)');
    try {
      final templates = await _workoutTemplateDao.getWorkoutTemplatesByLastUsed(limit: limit);
      _logger.fine('Retrieved ${templates.length} recently used workout templates');
      return templates;
    } catch (e) {
      _logger.severe('Failed to get recently used workout templates: $e');
      rethrow;
    }
  }

  /// Move a workout template to a different folder
  Future<void> moveTemplateToFolder(WorkoutTemplateId templateId, WorkoutFolderId? folderId) async {
    _logger.fine('Moving workout template $templateId to folder: $folderId');
    try {
      final template = await getWorkoutTemplateById(templateId);
      if (template == null) {
        throw Exception('Workout template not found: $templateId');
      }

      final updatedTemplate = template.copyWith(folderId: folderId);
      await updateWorkoutTemplate(updatedTemplate);
      _logger.fine('Successfully moved workout template $templateId to folder: $folderId');
    } catch (e) {
      _logger.severe('Failed to move workout template $templateId to folder $folderId: $e');
      rethrow;
    }
  }

  /// Duplicate a workout template
  Future<WorkoutTemplate> duplicateTemplate(WorkoutTemplateId templateId, {String? newName}) async {
    _logger.fine('Duplicating workout template: $templateId');
    try {
      final originalTemplate = await getWorkoutTemplateById(templateId);
      if (originalTemplate == null) {
        throw Exception('Workout template not found: $templateId');
      }

      final duplicatedTemplate = WorkoutTemplate(
        name: newName ?? '${originalTemplate.name} (Copy)',
        description: originalTemplate.description,
        iconCodePoint: originalTemplate.iconCodePoint,
        colorValue: originalTemplate.colorValue,
        folderId: originalTemplate.folderId,
        notes: originalTemplate.notes,
        orderIndex: originalTemplate.orderIndex,
      );

      await _workoutTemplateDao.insert(duplicatedTemplate);
      _logger.fine('Successfully duplicated workout template. New id: ${duplicatedTemplate.id}');
      return duplicatedTemplate;
    } catch (e) {
      _logger.severe('Failed to duplicate workout template $templateId: $e');
      rethrow;
    }
  }

  /// Get workout templates count by folder
  Future<Map<WorkoutFolderId?, int>> getTemplateCountByFolder() async {
    _logger.fine('Getting workout template count by folder');
    try {
      final allTemplates = await getAllWorkoutTemplates();
      final countMap = <WorkoutFolderId?, int>{};

      for (final template in allTemplates) {
        countMap[template.folderId] = (countMap[template.folderId] ?? 0) + 1;
      }

      _logger.fine('Template count by folder calculated: ${countMap.length} folders');
      return countMap;
    } catch (e) {
      _logger.severe('Failed to get template count by folder: $e');
      rethrow;
    }
  }

  // FOLDER MANAGEMENT OPERATIONS

  /// Load folder data into cache
  Future<void> loadFolders() async {
    _logger.info('Loading folder data');
    try {
      _folders = await _workoutFolderDao.getAllWorkoutFoldersOrdered();
      _logger.fine('Loaded ${_folders.length} folders');
    } catch (e) {
      _logger.severe('Failed to load folder data: $e');
      _folders = [];
    }
  }

  /// Create a new folder
  Future<WorkoutFolder> createFolder(String name) async {
    _logger.info('Creating new folder with name: $name');
    final folder = WorkoutFolder(name: name);
    
    await _workoutFolderDao.insert(folder);
    _folders.add(folder);
    _logger.fine('Folder created with id: ${folder.id}');
    return folder;
  }

  /// Update an existing folder
  Future<void> updateFolder(WorkoutFolder folder) async {
    _logger.info('Updating folder with id: ${folder.id}');
    await _workoutFolderDao.updateWorkoutFolder(folder);
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder;
      _logger.fine('Folder updated in cache');
    }
  }

  /// Delete a folder and move its templates to no folder
  Future<void> deleteFolder(String folderId) async {
    _logger.info('Deleting folder with id: $folderId');
    
    // Move all templates in this folder to no folder
    final templatesInFolder = await getWorkoutTemplatesByFolder(folderId);
    for (final template in templatesInFolder) {
      final updatedTemplate = template.copyWith(folderId: null);
      await updateWorkoutTemplate(updatedTemplate);
      _logger.finer('Moved template ${template.id} out of folder');
    }
    
    await _workoutFolderDao.deleteWorkoutFolder(folderId);
    _folders.removeWhere((f) => f.id == folderId);
    _logger.fine('Folder deleted from database and cache');
  }

  /// Reorder folders
  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    _logger.info('Reordering folders from $oldIndex to $newIndex');
    if (oldIndex < 0 || oldIndex >= _folders.length || 
        newIndex < 0 || newIndex >= _folders.length) {
      _logger.warning('Invalid reorder indices for folders');
      return;
    }

    // Remove the folder from the old position
    final folder = _folders.removeAt(oldIndex);
    // Insert it at the new position
    _folders.insert(newIndex, folder);

    // Update orderIndex for all folders
    for (int i = 0; i < _folders.length; i++) {
      final updatedFolder = _folders[i].copyWith(orderIndex: i);
      await _workoutFolderDao.updateWorkoutFolder(updatedFolder);
      _folders[i] = updatedFolder;
    }
  }

  /// Reorder templates within a folder
  Future<void> reorderTemplatesInFolder(String? folderId, int oldIndex, int newIndex) async {
    _logger.info('Reordering templates in folder $folderId from $oldIndex to $newIndex');
    final templatesInFolder = folderId == null 
        ? await getWorkoutTemplatesWithoutFolder()
        : await getWorkoutTemplatesByFolder(folderId);
        
    if (oldIndex < 0 || oldIndex >= templatesInFolder.length || 
        newIndex < 0 || newIndex >= templatesInFolder.length) {
      _logger.warning('Invalid reorder indices');
      return;
    }

    // Remove the template from the old position
    final template = templatesInFolder.removeAt(oldIndex);
    // Insert it at the new position
    templatesInFolder.insert(newIndex, template);

    // Update orderIndex for all templates in the folder to reflect the new order
    for (int i = 0; i < templatesInFolder.length; i++) {
      final updatedTemplate = templatesInFolder[i].copyWith(orderIndex: i);
      await updateWorkoutTemplate(updatedTemplate);
    }
  }

  /// Get folder by ID
  WorkoutFolder? getFolderById(String id) {
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get templates in a specific folder (cached version)
  Future<List<WorkoutTemplate>> getTemplatesInFolder(String? folderId) async {
    if (folderId == null) {
      return await getWorkoutTemplatesWithoutFolder();
    } else {
      return await getWorkoutTemplatesByFolder(folderId);
    }
  }

  /// Clear all user templates and folders
  Future<void> clearUserTemplatesAndFolders() async {
    _logger.warning('Clearing all user templates and folders');
    
    final allTemplates = await getAllWorkoutTemplates();
    for (final template in allTemplates) {
      await deleteWorkoutTemplate(template.id);
    }
    
    for (final folder in _folders) {
      await _workoutFolderDao.deleteWorkoutFolder(folder.id);
    }
    
    _folders = [];
    _logger.info('All user templates and folders cleared');
  }

  // TEMPLATE EXERCISE MANAGEMENT

  /// Returns the exercises (with sets) defined for a given workout template.
  Future<List<WorkoutExercise>> getTemplateExercises(WorkoutTemplateId templateId) async {
    _logger.fine('Loading template exercises for template: $templateId');
    try {
      final exercises = await _workoutExerciseDao.getWorkoutExercisesByWorkoutTemplateId(templateId);
      final result = <WorkoutExercise>[];
      for (final ex in exercises) {
        final sets = await _workoutSetDao.getWorkoutSetsByWorkoutExerciseId(ex.id);
        result.add(ex.copyWith(sets: sets));
      }
      _logger.fine('Loaded ${result.length} template exercises for template: $templateId');
      return result;
    } catch (e) {
      _logger.severe('Failed to load template exercises for $templateId: $e');
      rethrow;
    }
  }

  /// Replaces all exercises/sets for the given template with the provided list.
  /// This performs a simple "replace-all" to keep logic straightforward.
  Future<void> saveTemplateExercises(WorkoutTemplateId templateId, List<WorkoutExercise> exercises) async {
    _logger.fine('Saving ${exercises.length} template exercises for template: $templateId');
    try {
      // Remove existing template exercises (WorkoutSet rows will cascade delete)
      await _workoutExerciseDao.deleteWorkoutExercisesByWorkoutTemplateId(templateId);

      // Insert provided exercises and their sets in order, regenerating IDs to avoid collisions
      for (int i = 0; i < exercises.length; i++) {
        final src = exercises[i];

        // Create a fresh exercise with a new UUID and correct FK
        final ex = WorkoutExercise(
          workoutTemplateId: templateId,
          exerciseSlug: src.exerciseSlug,
          notes: src.notes,
          orderIndex: i,
          sets: const [],
        );
        await _workoutExerciseDao.insert(ex);

        // Insert sets with new UUIDs and correct FK linkage
        for (int j = 0; j < src.sets.length; j++) {
          final s = src.sets[j];
          final set = WorkoutSet(
            workoutExerciseId: ex.id,
            setIndex: j,
            targetReps: s.targetReps,
            targetWeight: s.targetWeight,
            targetRestSeconds: s.targetRestSeconds,
          );
          await _workoutSetDao.insert(set);
        }
      }
      _logger.fine('Template exercises saved successfully for template: $templateId');
    } catch (e) {
      _logger.severe('Failed to save template exercises for $templateId: $e');
      rethrow;
    }
  }
}
