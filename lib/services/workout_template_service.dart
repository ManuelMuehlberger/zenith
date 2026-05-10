import 'package:logging/logging.dart';
import '../models/typedefs.dart';
import '../models/workout_exercise.dart';
import '../models/workout_folder.dart';
import '../models/workout_set.dart';
import '../models/workout_template.dart';
import 'dao/workout_exercise_dao.dart';
import 'dao/workout_folder_dao.dart';
import 'dao/workout_set_dao.dart';
import 'dao/workout_template_dao.dart';

class WorkoutTemplateService {
  static const int maxFolderDepth = 2;

  static final WorkoutTemplateService _instance =
      WorkoutTemplateService._internal();
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
  final Map<WorkoutTemplateId, List<WorkoutExercise>> _templateExercisesCache =
      <WorkoutTemplateId, List<WorkoutExercise>>{};
  final Map<WorkoutTemplateId, Future<List<WorkoutExercise>>>
  _ongoingTemplateExerciseLoads =
      <WorkoutTemplateId, Future<List<WorkoutExercise>>>{};

  // Cache for folders
  List<WorkoutFolder> _folders = [];
  bool _foldersLoaded = false;

  List<WorkoutFolder> get folders => getFoldersInParentSync(null);

  /// Get all workout templates ordered by folder and orderIndex
  Future<List<WorkoutTemplate>> getAllWorkoutTemplates() async {
    _logger.fine('Getting all workout templates');
    try {
      final templates = await _workoutTemplateDao
          .getAllWorkoutTemplatesOrdered();
      _logger.fine('Retrieved ${templates.length} workout templates');
      return templates;
    } catch (e) {
      _logger.severe('Failed to get all workout templates: $e');
      rethrow;
    }
  }

  /// Get workout templates in a specific folder
  Future<List<WorkoutTemplate>> getWorkoutTemplatesByFolder(
    WorkoutFolderId folderId,
  ) async {
    _logger.fine('Getting workout templates for folder: $folderId');
    try {
      final templates = await _workoutTemplateDao.getWorkoutTemplatesByFolderId(
        folderId,
      );
      _logger.fine(
        'Retrieved ${templates.length} workout templates for folder $folderId',
      );
      return templates;
    } catch (e) {
      _logger.severe(
        'Failed to get workout templates for folder $folderId: $e',
      );
      rethrow;
    }
  }

  /// Get workout templates without a folder
  Future<List<WorkoutTemplate>> getWorkoutTemplatesWithoutFolder() async {
    _logger.fine('Getting workout templates without folder');
    try {
      final templates = await _workoutTemplateDao
          .getWorkoutTemplatesWithoutFolder();
      _logger.fine(
        'Retrieved ${templates.length} workout templates without folder',
      );
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
        _logger.fine(
          'Successfully updated workout template with id: ${template.id}',
        );
      } else {
        _logger.warning(
          'No workout template found to update with id: ${template.id}',
        );
      }
    } catch (e) {
      _logger.severe(
        'Failed to update workout template with id ${template.id}: $e',
      );
      rethrow;
    }
  }

  /// Delete a workout template
  Future<void> deleteWorkoutTemplate(WorkoutTemplateId id) async {
    _logger.fine('Deleting workout template with id: $id');
    try {
      final count = await _workoutTemplateDao.deleteWorkoutTemplate(id);
      _invalidateTemplateExercisesCache(id);
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
        _logger.warning(
          'No workout template found to update lastUsed with id: $id',
        );
      }
    } catch (e) {
      _logger.severe('Failed to update lastUsed for workout template $id: $e');
      rethrow;
    }
  }

  /// Get recently used workout templates
  Future<List<WorkoutTemplate>> getRecentlyUsedTemplates({
    int limit = 10,
  }) async {
    _logger.fine('Getting recently used workout templates (limit: $limit)');
    try {
      final templates = await _workoutTemplateDao.getWorkoutTemplatesByLastUsed(
        limit: limit,
      );
      _logger.fine(
        'Retrieved ${templates.length} recently used workout templates',
      );
      return templates;
    } catch (e) {
      _logger.severe('Failed to get recently used workout templates: $e');
      rethrow;
    }
  }

  /// Move a workout template to a different folder
  Future<void> moveTemplateToFolder(
    WorkoutTemplateId templateId,
    WorkoutFolderId? folderId,
  ) async {
    _logger.fine('Moving workout template $templateId to folder: $folderId');
    try {
      final template = await getWorkoutTemplateById(templateId);
      if (template == null) {
        throw Exception('Workout template not found: $templateId');
      }

      final updatedTemplate = template.copyWith(folderId: folderId);
      await updateWorkoutTemplate(updatedTemplate);
      _logger.fine(
        'Successfully moved workout template $templateId to folder: $folderId',
      );
    } catch (e) {
      _logger.severe(
        'Failed to move workout template $templateId to folder $folderId: $e',
      );
      rethrow;
    }
  }

  /// Duplicate a workout template
  Future<WorkoutTemplate> duplicateTemplate(
    WorkoutTemplateId templateId, {
    String? newName,
  }) async {
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
      _logger.fine(
        'Successfully duplicated workout template. New id: ${duplicatedTemplate.id}',
      );
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

      _logger.fine(
        'Template count by folder calculated: ${countMap.length} folders',
      );
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
      _foldersLoaded = true;
      _logger.fine('Loaded ${_folders.length} folders');
    } catch (e) {
      _logger.severe('Failed to load folder data: $e');
      _folders = [];
      _foldersLoaded = false;
    }
  }

  /// Create a new folder
  Future<WorkoutFolder> createFolder(
    String name, {
    WorkoutFolderId? parentFolderId,
  }) async {
    await _ensureFoldersLoaded();
    _logger.info(
      'Creating new folder with name: $name under parent: $parentFolderId',
    );

    final parentFolder = parentFolderId == null
        ? null
        : _requireFolderById(parentFolderId);
    final depth = parentFolder == null ? 0 : parentFolder.depth + 1;
    if (depth > maxFolderDepth) {
      throw StateError('Folders can only be nested 3 levels deep.');
    }

    final folder = WorkoutFolder(
      name: name,
      parentFolderId: parentFolderId,
      depth: depth,
      orderIndex: _nextFolderOrderIndex(parentFolderId),
    );

    await _workoutFolderDao.insert(folder);
    _folders.add(folder);
    _logger.fine('Folder created with id: ${folder.id}');
    return folder;
  }

  /// Update an existing folder
  Future<void> updateFolder(WorkoutFolder folder) async {
    await _ensureFoldersLoaded();
    _logger.info('Updating folder with id: ${folder.id}');
    await _workoutFolderDao.updateWorkoutFolder(folder);
    _replaceCachedFolder(folder);
    _logger.fine('Folder updated in cache');
  }

  /// Delete a folder and move its templates to no folder
  Future<void> deleteFolder(String folderId) async {
    await _ensureFoldersLoaded();
    _logger.info('Deleting folder with id: $folderId');

    final folder = _requireFolderById(folderId);
    final subtreeFolderIds = {folderId, ..._getDescendantFolderIds(folderId)};

    final allTemplates = await getAllWorkoutTemplates();
    final templatesInSubtree = allTemplates.where(
      (template) => subtreeFolderIds.contains(template.folderId),
    );
    for (final template in templatesInSubtree) {
      final updatedTemplate = template.copyWith(folderId: null);
      await updateWorkoutTemplate(updatedTemplate);
      _logger.finer('Moved template ${template.id} out of folder subtree');
    }

    final foldersToDelete =
        _folders
            .where((cachedFolder) => subtreeFolderIds.contains(cachedFolder.id))
            .toList()
          ..sort((left, right) => right.depth.compareTo(left.depth));

    for (final nestedFolder in foldersToDelete) {
      await _workoutFolderDao.deleteWorkoutFolder(nestedFolder.id);
    }

    _folders.removeWhere(
      (cachedFolder) => subtreeFolderIds.contains(cachedFolder.id),
    );
    await _normalizeFolderOrderIndices(folder.parentFolderId);
    _logger.fine('Folder subtree deleted from database and cache');
  }

  /// Reorder folders
  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    await reorderFoldersInParent(null, oldIndex, newIndex);
  }

  /// Reorder folders within a given parent scope.
  Future<void> reorderFoldersInParent(
    WorkoutFolderId? parentFolderId,
    int oldIndex,
    int newIndex,
  ) async {
    await _ensureFoldersLoaded();
    _logger.info(
      'Reordering folders in parent $parentFolderId from $oldIndex to $newIndex',
    );
    final siblings = getFoldersInParentSync(parentFolderId);
    if (oldIndex < 0 ||
        oldIndex >= siblings.length ||
        newIndex < 0 ||
        newIndex >= siblings.length) {
      _logger.warning('Invalid reorder indices for folders');
      return;
    }

    final movedFolder = siblings.removeAt(oldIndex);
    siblings.insert(newIndex, movedFolder);
    await _applyFolderOrder(parentFolderId, siblings);
  }

  /// Move a folder into a different parent, validating cycles and depth.
  Future<void> moveFolderToParent(
    WorkoutFolderId folderId,
    WorkoutFolderId? parentFolderId,
  ) async {
    await _ensureFoldersLoaded();
    final folder = _requireFolderById(folderId);
    final oldParentFolderId = folder.parentFolderId;

    if (folderId == parentFolderId) {
      throw StateError('A folder cannot become its own parent.');
    }

    final descendantFolderIds = _getDescendantFolderIds(folderId);
    if (parentFolderId != null &&
        descendantFolderIds.contains(parentFolderId)) {
      throw StateError('A folder cannot be moved into one of its descendants.');
    }

    final parentFolder = parentFolderId == null
        ? null
        : _requireFolderById(parentFolderId);
    final targetDepth = parentFolder == null ? 0 : parentFolder.depth + 1;
    final maxSubtreeDepth = _getMaxSubtreeDepth(folderId);
    final depthDelta = targetDepth - folder.depth;

    if (maxSubtreeDepth + depthDelta > maxFolderDepth) {
      throw StateError('Folders can only be nested 3 levels deep.');
    }

    final updatedFolder = folder.copyWith(
      parentFolderId: parentFolderId,
      depth: targetDepth,
      orderIndex: _nextFolderOrderIndex(parentFolderId),
    );
    await _workoutFolderDao.updateWorkoutFolder(updatedFolder);
    _replaceCachedFolder(updatedFolder);

    for (final descendantFolderId in descendantFolderIds) {
      final descendantFolder = _requireFolderById(descendantFolderId);
      final shiftedFolder = descendantFolder.copyWith(
        depth: descendantFolder.depth + depthDelta,
      );
      await _workoutFolderDao.updateWorkoutFolder(shiftedFolder);
      _replaceCachedFolder(shiftedFolder);
    }

    await _normalizeFolderOrderIndices(oldParentFolderId);
    if (oldParentFolderId != parentFolderId) {
      await _normalizeFolderOrderIndices(parentFolderId);
    }
  }

  /// Reorder templates within a folder
  Future<void> reorderTemplatesInFolder(
    String? folderId,
    int oldIndex,
    int newIndex,
  ) async {
    _logger.info(
      'Reordering templates in folder $folderId from $oldIndex to $newIndex',
    );
    final templatesInFolder = folderId == null
        ? await getWorkoutTemplatesWithoutFolder()
        : await getWorkoutTemplatesByFolder(folderId);

    if (oldIndex < 0 ||
        oldIndex >= templatesInFolder.length ||
        newIndex < 0 ||
        newIndex >= templatesInFolder.length) {
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

  /// Get folders directly inside the given parent.
  Future<List<WorkoutFolder>> getFoldersInParent(
    WorkoutFolderId? parentFolderId,
  ) async {
    await _ensureFoldersLoaded();
    return getFoldersInParentSync(parentFolderId);
  }

  /// Synchronous cached view of folders directly inside the given parent.
  List<WorkoutFolder> getFoldersInParentSync(WorkoutFolderId? parentFolderId) {
    final foldersInParent = _folders
        .where((folder) => folder.parentFolderId == parentFolderId)
        .toList();
    foldersInParent.sort(
      (left, right) => (left.orderIndex ?? 0).compareTo(right.orderIndex ?? 0),
    );
    return foldersInParent;
  }

  /// Returns the ancestry path for a folder from root to the folder itself.
  List<WorkoutFolder> getFolderPathSync(WorkoutFolderId folderId) {
    final path = <WorkoutFolder>[];
    WorkoutFolder? currentFolder = getFolderById(folderId);
    while (currentFolder != null) {
      path.insert(0, currentFolder);
      currentFolder = currentFolder.parentFolderId == null
          ? null
          : getFolderById(currentFolder.parentFolderId!);
    }
    return path;
  }

  /// Returns whether moving a folder to a target parent would be valid.
  bool canMoveFolderToParentSync(
    WorkoutFolderId folderId,
    WorkoutFolderId? parentFolderId,
  ) {
    final folder = getFolderById(folderId);
    if (folder == null || folderId == parentFolderId) {
      return false;
    }

    final descendantFolderIds = _getDescendantFolderIds(folderId);
    if (parentFolderId != null &&
        descendantFolderIds.contains(parentFolderId)) {
      return false;
    }

    final parentFolder = parentFolderId == null
        ? null
        : getFolderById(parentFolderId);
    if (parentFolderId != null && parentFolder == null) {
      return false;
    }

    final targetDepth = parentFolder == null ? 0 : parentFolder.depth + 1;
    final maxSubtreeDepth = _getMaxSubtreeDepth(folderId);
    final depthDelta = targetDepth - folder.depth;
    return maxSubtreeDepth + depthDelta <= maxFolderDepth;
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
    _foldersLoaded = true;
    _logger.info('All user templates and folders cleared');
  }

  Future<void> _ensureFoldersLoaded() async {
    if (!_foldersLoaded) {
      await loadFolders();
    }
  }

  WorkoutFolder _requireFolderById(WorkoutFolderId folderId) {
    final folder = getFolderById(folderId);
    if (folder == null) {
      throw StateError('Folder not found: $folderId');
    }
    return folder;
  }

  int _nextFolderOrderIndex(WorkoutFolderId? parentFolderId) {
    final siblings = getFoldersInParentSync(parentFolderId);
    if (siblings.isEmpty) {
      return 0;
    }

    final highestOrderIndex = siblings
        .map((folder) => folder.orderIndex ?? 0)
        .reduce((left, right) => left > right ? left : right);
    return highestOrderIndex + 1;
  }

  Set<WorkoutFolderId> _getDescendantFolderIds(WorkoutFolderId folderId) {
    final descendants = <WorkoutFolderId>{};
    final pendingIds = <WorkoutFolderId>[folderId];

    while (pendingIds.isNotEmpty) {
      final currentFolderId = pendingIds.removeLast();
      final children = getFoldersInParentSync(currentFolderId);
      for (final child in children) {
        if (descendants.add(child.id)) {
          pendingIds.add(child.id);
        }
      }
    }

    return descendants;
  }

  int _getMaxSubtreeDepth(WorkoutFolderId folderId) {
    final folder = _requireFolderById(folderId);
    var maxDepthInSubtree = folder.depth;

    for (final descendantFolderId in _getDescendantFolderIds(folderId)) {
      final descendantFolder = _requireFolderById(descendantFolderId);
      if (descendantFolder.depth > maxDepthInSubtree) {
        maxDepthInSubtree = descendantFolder.depth;
      }
    }

    return maxDepthInSubtree;
  }

  Future<void> _normalizeFolderOrderIndices(
    WorkoutFolderId? parentFolderId,
  ) async {
    final siblings = getFoldersInParentSync(parentFolderId);
    await _applyFolderOrder(parentFolderId, siblings);
  }

  Future<void> _applyFolderOrder(
    WorkoutFolderId? parentFolderId,
    List<WorkoutFolder> orderedFolders,
  ) async {
    for (int index = 0; index < orderedFolders.length; index++) {
      final orderedFolder = orderedFolders[index];
      final updatedFolder = orderedFolder.copyWith(
        parentFolderId: parentFolderId,
        orderIndex: index,
      );
      await _workoutFolderDao.updateWorkoutFolder(updatedFolder);
      _replaceCachedFolder(updatedFolder);
    }
  }

  void _replaceCachedFolder(WorkoutFolder folder) {
    final index = _folders.indexWhere(
      (cachedFolder) => cachedFolder.id == folder.id,
    );
    if (index == -1) {
      _folders.add(folder);
    } else {
      _folders[index] = folder;
    }
  }

  // TEMPLATE EXERCISE MANAGEMENT

  /// Returns the exercises (with sets) defined for a given workout template.
  Future<List<WorkoutExercise>> getTemplateExercises(
    WorkoutTemplateId templateId,
  ) async {
    final cachedExercises = _templateExercisesCache[templateId];
    if (cachedExercises != null) {
      _logger.finer(
        'Returning cached template exercises for template: $templateId',
      );
      return _cloneTemplateExercises(cachedExercises);
    }

    final ongoingTemplateExerciseLoad =
        _ongoingTemplateExerciseLoads[templateId];
    if (ongoingTemplateExerciseLoad != null) {
      _logger.finer(
        'Awaiting in-flight template exercise load for template: $templateId',
      );
      final exercises = await ongoingTemplateExerciseLoad;
      return _cloneTemplateExercises(exercises);
    }

    final loadFuture = _loadTemplateExercises(templateId);
    _ongoingTemplateExerciseLoads[templateId] = loadFuture;

    try {
      final exercises = await loadFuture;
      return _cloneTemplateExercises(exercises);
    } finally {
      if (identical(_ongoingTemplateExerciseLoads[templateId], loadFuture)) {
        _ongoingTemplateExerciseLoads.remove(templateId);
      }
    }
  }

  Future<List<WorkoutExercise>> _loadTemplateExercises(
    WorkoutTemplateId templateId,
  ) async {
    _logger.fine('Loading template exercises for template: $templateId');
    try {
      final exercises = await _workoutExerciseDao
          .getWorkoutExercisesByWorkoutTemplateId(templateId);
      final result = <WorkoutExercise>[];
      for (final ex in exercises) {
        final sets = await _workoutSetDao.getWorkoutSetsByWorkoutExerciseId(
          ex.id,
        );
        result.add(ex.copyWith(sets: sets));
      }
      _templateExercisesCache[templateId] = _cloneTemplateExercises(result);
      _logger.fine(
        'Loaded ${result.length} template exercises for template: $templateId',
      );
      return result;
    } catch (e) {
      _logger.severe('Failed to load template exercises for $templateId: $e');
      rethrow;
    }
  }

  /// Replaces all exercises/sets for the given template with the provided list.
  /// This performs a simple "replace-all" to keep logic straightforward.
  Future<void> saveTemplateExercises(
    WorkoutTemplateId templateId,
    List<WorkoutExercise> exercises,
  ) async {
    _logger.fine(
      'Saving ${exercises.length} template exercises for template: $templateId',
    );
    try {
      // Remove existing template exercises (WorkoutSet rows will cascade delete)
      await _workoutExerciseDao.deleteWorkoutExercisesByWorkoutTemplateId(
        templateId,
      );

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
      _invalidateTemplateExercisesCache(templateId);
      _logger.fine(
        'Template exercises saved successfully for template: $templateId',
      );
    } catch (e) {
      _logger.severe('Failed to save template exercises for $templateId: $e');
      rethrow;
    }
  }

  List<WorkoutExercise> _cloneTemplateExercises(
    List<WorkoutExercise> exercises,
  ) {
    return exercises
        .map(
          (exercise) =>
              exercise.copyWith(sets: List<WorkoutSet>.from(exercise.sets)),
        )
        .toList(growable: false);
  }

  void _invalidateTemplateExercisesCache(WorkoutTemplateId templateId) {
    _templateExercisesCache.remove(templateId);
    _ongoingTemplateExerciseLoads.remove(templateId);
  }
}
