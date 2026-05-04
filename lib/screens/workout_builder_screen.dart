import 'dart:async';
import 'dart:developer' as developer; // Add debug logging
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../models/typedefs.dart';
import '../models/workout_folder.dart';
import '../models/workout_template.dart';
import '../services/workout_session_service.dart';
import '../services/workout_template_service.dart';
import '../theme/app_theme.dart';
import '../widgets/main_dock_spacer.dart';
import '../widgets/profile_icon_button.dart';
import '../widgets/reorderable_folder_list.dart';
import '../widgets/reorderable_workout_template_list.dart';
import '../widgets/workout_builder_drag_payload.dart';
import 'active_workout_screen.dart';
import 'create_workout_screen.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  const WorkoutBuilderScreen({super.key});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedFolderId;
  bool _isLoading = true;
  bool _isDragging = false;
  WorkoutBuilderDragPayload? _activeDragPayload;

  // Local caches for templates and counts (to keep the UI responsive and consistent)
  List<WorkoutTemplate> _templates = [];
  Map<String?, int> _templateCountByFolder = {};

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Load folders into cache
      await WorkoutTemplateService.instance.loadFolders();
      // Load counts and templates
      await _loadCounts();
      await _loadTemplates();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCounts() async {
    final counts = await WorkoutTemplateService.instance
        .getTemplateCountByFolder();
    if (mounted) {
      setState(() {
        _templateCountByFolder = counts;
      });
    }
  }

  Future<void> _loadTemplates() async {
    List<WorkoutTemplate> templates;
    if (_selectedFolderId == null) {
      templates = await WorkoutTemplateService.instance
          .getWorkoutTemplatesWithoutFolder();
    } else {
      templates = await WorkoutTemplateService.instance
          .getWorkoutTemplatesByFolder(_selectedFolderId!);
    }
    if (mounted) {
      setState(() {
        _templates = templates;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onDragStarted(WorkoutBuilderDragPayload payload) {
    developer.log('Drag started, selectedFolderId: $_selectedFolderId');
    setState(() {
      _activeDragPayload = payload;
      _isDragging = _selectedFolderId != null;
    });
  }

  void _onDragEnded() {
    developer.log('Drag ended');
    setState(() {
      _isDragging = false;
      _activeDragPayload = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final headerSurface = Theme.of(context).scaffoldBackgroundColor;
    final transparentSurface = Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0);

    return AnimatedBuilder(
      animation: WorkoutSessionService.instance,
      builder: (context, _) {
        final sessionService = WorkoutSessionService.instance;

        if (sessionService.hasActiveSession) {
          return ActiveWorkoutScreen(session: sessionService.currentSession!);
        }

        return PopScope(
          canPop: _selectedFolderId == null,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _selectedFolderId != null) {
              setState(() {
                _selectedFolderId = null;
              });
              // When navigating back to all workouts, refresh templates
              _loadTemplates();
            }
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                  leading: const SizedBox(width: kToolbarHeight),
                  backgroundColor: headerSurface.withValues(alpha: 0),
                  elevation: 0,
                  expandedHeight:
                      AppConstants.HEADER_EXTRA_HEIGHT + kToolbarHeight,
                  actions: const [ProfileIconButton()],
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Persistent glass effect layer (covers expanded and collapsed states)
                          ClipRRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                                sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                              ),
                              child: ColoredBox(
                                color: headerSurface.withValues(alpha: 0.94),
                              ),
                            ),
                          ),
                          // FlexibleSpaceBar handles title positioning and parallax of the large title
                          FlexibleSpaceBar(
                            centerTitle: true,
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [_buildSmallTitle()],
                            ),
                            background: ColoredBox(
                              color: transparentSurface,
                              child: Align(
                                alignment: Alignment.center,
                                child: _buildLargeTitle(),
                              ),
                            ),
                            collapseMode: CollapseMode.parallax,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Content
                if (_isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: context.appScheme.primary,
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(child: _buildMainContentWithoutHeader()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallTitle() {
    final bool isInsideFolder = _selectedFolderId != null;
    String title = 'Workouts';
    if (isInsideFolder) {
      title = _getFolderName(_selectedFolderId!);
    }

    // Using AnimatedSwitcher similar to home screen to prevent duplication
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: child,
        ),
      ),
      child: Text(
        title,
        key: ValueKey('small_$title'),
        style: context.appText.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLargeTitle() {
    final bool isInsideFolder = _selectedFolderId != null;
    String title = 'Workouts';
    if (isInsideFolder) {
      title = _getFolderName(_selectedFolderId!);
    }

    // Using AnimatedSwitcher similar to home screen to prevent duplication
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation),
      child: Text(
        title,
        key: ValueKey('large_$title'),
        style: context.appText.displayLarge,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMainContentWithoutHeader() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.appScheme.primary),
      );
    }

    final folders = WorkoutTemplateService.instance.getFoldersInParentSync(
      _selectedFolderId,
    );

    return Column(
      children: [
        if (_selectedFolderId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildBreadcrumbNavigation(),
          ),
        _buildContent(folders: folders),
        const MainDockSpacer(),
      ],
    );
  }

  Widget _buildOverviewBadge({
    required IconData icon,
    required String label,
    Color? tint,
  }) {
    final colors = context.appColors;
    final badgeTint = tint ?? colors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeTint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: badgeTint),
          const SizedBox(width: 8),
          Text(
            label,
            style: context.appText.labelMedium?.copyWith(
              color: badgeTint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbNavigation() {
    final appScheme = context.appScheme;
    final appColors = context.appColors;
    final breadcrumbStyle = context.appText.titleSmall!;

    return DragTarget<WorkoutBuilderDragPayload>(
      onAcceptWithDetails: (details) async {
        final data = details.data;
        developer.log('Breadcrumb onAcceptWithDetails: $data');
        await _movePayloadToCurrentParent(data);
        _onDragEnded();
      },
      onWillAcceptWithDetails: (details) {
        developer.log('Breadcrumb onWillAcceptWithDetails: ${details.data}');
        return _canMovePayloadToCurrentParent(details.data);
      },
      onLeave: (data) {},
      builder: (context, candidateData, rejectedData) {
        final isHoveringOverDropTarget = candidateData.isNotEmpty;
        final showAnimation = _isDragging || isHoveringOverDropTarget;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.diagonal3Values(
            showAnimation ? 1.01 : 1.0,
            showAnimation ? 1.01 : 1.0,
            1.0,
          ),
          child: ClipRRect(
            borderRadius: AppTheme.workoutCardBorderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                sigmaY: AppConstants.GLASS_BLUR_SIGMA,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: showAnimation
                      ? appScheme.primary.withValues(alpha: 0.12)
                      : appColors.surfaceAlt,
                  borderRadius: AppTheme.workoutCardBorderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: showAnimation
                                ? appScheme.primary.withValues(alpha: 0.18)
                                : appColors.overlayMedium,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            showAnimation
                                ? Icons.move_up_rounded
                                : Icons.arrow_back_rounded,
                            color: showAnimation
                                ? appScheme.primary
                                : appColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                showAnimation
                                    ? 'Move to previous level'
                                    : 'Back to previous level',
                                style: context.appText.labelMedium?.copyWith(
                                  color: appColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildBreadcrumbPath(
                                breadcrumbStyle: breadcrumbStyle,
                                appScheme: appScheme,
                                appColors: appColors,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildOverviewBadge(
                          icon: showAnimation
                              ? Icons.move_up_rounded
                              : Icons.folder_open_rounded,
                          label: showAnimation
                              ? (_currentParentFolderId == null
                                    ? 'Move to root'
                                    : 'Move up one level')
                              : '${_templates.length} workouts',
                          tint: showAnimation
                              ? appScheme.primary
                              : appColors.textSecondary,
                        ),
                      ],
                    ),
                    if (showAnimation) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Drop a workout or folder here to move it to the previous level.',
                        style: context.appText.bodySmall?.copyWith(
                          color: appColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent({required List<WorkoutFolder> folders}) {
    final templates = _templates;
    final subfolderCountByFolder = <String, int>{
      for (final folder in folders)
        folder.id: WorkoutTemplateService.instance
            .getFoldersInParentSync(folder.id)
            .length,
    };

    if (folders.isEmpty && templates.isEmpty && _selectedFolderId == null) {
      return _buildEmptyState();
    }
    if (folders.isEmpty && templates.isEmpty && _selectedFolderId != null) {
      return _buildEmptyState(inFolder: true);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (folders.isNotEmpty) ...[
            _buildContentSectionHeader(
              title: 'Folders',
              countLabel: '${folders.length}',
              action: _buildAddFolderButton(),
            ),
            const SizedBox(height: 10),
            ReorderableFolderList(
              folders: folders,
              currentParentFolderId: _selectedFolderId,
              itemCountByFolder: _templateCountByFolder,
              subfolderCountByFolder: subfolderCountByFolder,
              activeDragPayload: _activeDragPayload,
              onFolderTap: (folder) => _selectFolder(folder.id),
              onRenamePressed: _showRenameFolderDialog,
              onDeletePressed: _showDeleteFolderDialog,
              onFolderReordered: _reorderFolders,
              onPayloadDroppedIntoFolder: _movePayloadIntoFolder,
              canDropIntoFolder: _canDropPayloadIntoFolder,
              onDragStarted: _onDragStarted,
              onDragEnded: _onDragEnded,
            ),
            const SizedBox(height: 16),
          ] else if (_selectedFolderId == null && templates.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildAddFolderButton(),
              ),
            ),
          ] else if (_selectedFolderId != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildAddFolderButton(),
              ),
            ),
          ],
          ReorderableWorkoutTemplateList(
            templates: templates,
            folderId: _selectedFolderId,
            onTemplateTap: _editWorkout,
            onTemplateDeletePressed: _showDeleteTemplateDialog,
            onTemplateReordered: _reorderTemplates,
            onAddWorkoutPressed: _createWorkout,
            onDragStarted: _onDragStarted,
            onDragEnded: _onDragEnded,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({bool inFolder = false}) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              inFolder
                  ? Icons.folder_open_rounded
                  : Icons.fitness_center_rounded,
              size: 64,
              color: context.appColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              inFolder ? 'This folder is empty' : 'No workouts created yet',
              style: context.appText.titleMedium!.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              inFolder
                  ? 'Drag workouts here or use the dock + button to create one in this folder.'
                  : 'Use the dock + button to create your first workout, or start with a folder above.',
              style: context.appText.labelMedium!.copyWith(
                color: context.appColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!inFolder) ...[
              const SizedBox(height: 18),
              _buildAddFolderButton(),
            ] else ...[
              const SizedBox(height: 18),
              _buildAddFolderButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentSectionHeader({
    required String title,
    required String countLabel,
    Widget? action,
  }) {
    final colors = context.appColors;

    return Row(
      children: [
        Text(
          title,
          style: context.appText.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            countLabel,
            style: context.appText.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null) ...[const Spacer(), action],
      ],
    );
  }

  Widget _buildAddFolderButton() {
    return TextButton.icon(
      onPressed: _showCreateFolderDialog,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: const Icon(Icons.create_new_folder_rounded, size: 18),
      label: const Text('Add folder'),
    );
  }

  Widget _buildBreadcrumbPath({
    required TextStyle breadcrumbStyle,
    required ColorScheme appScheme,
    required AppThemeTokens appColors,
  }) {
    final path = _selectedFolderId == null
        ? <WorkoutFolder>[]
        : WorkoutTemplateService.instance.getFolderPathSync(_selectedFolderId!);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedFolderId = null;
            });
            _loadTemplates();
          },
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: breadcrumbStyle.copyWith(
              color: appScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            child: const Text('All Workouts'),
          ),
        ),
        for (final folder in path) ...[
          Icon(
            Icons.chevron_right_rounded,
            color: appColors.textTertiary,
            size: 18,
          ),
          GestureDetector(
            onTap: folder.id == _selectedFolderId
                ? null
                : () {
                    setState(() {
                      _selectedFolderId = folder.id;
                    });
                    _loadTemplates();
                  },
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: breadcrumbStyle.copyWith(
                color: folder.id == _selectedFolderId
                    ? appColors.textPrimary
                    : appScheme.primary,
                fontWeight: folder.id == _selectedFolderId
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
              child: Text(folder.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _createWorkout() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutScreen(folderId: _selectedFolderId),
      ),
    );
    if (result == true) {
      await _loadCounts();
      await _loadTemplates();
      setState(() {});
    }
  }

  void _selectFolder(String folderId) {
    setState(() {
      _selectedFolderId = folderId;
    });
    _loadTemplates();
  }

  Future<void> _moveTemplateToFolder(
    String templateId,
    String? folderId,
  ) async {
    developer.log('Moving template $templateId to folder $folderId');
    try {
      await WorkoutTemplateService.instance.moveTemplateToFolder(
        templateId,
        folderId,
      );
      unawaited(HapticFeedback.lightImpact());

      await _loadCounts();
      await _loadTemplates();

      if (mounted) {
        final targetFolderName = folderId != null
            ? _getFolderName(folderId)
            : 'All Workouts';
        final message = 'Moved to "$targetFolderName"';
        developer.log(
          'Successfully moved template $templateId to folder $folderId',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: context.appColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log(
        'Failed to move template $templateId to folder $folderId: $e',
      );
      unawaited(HapticFeedback.heavyImpact());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move workout: $e'),
            backgroundColor: context.appScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _moveFolderToParent(
    WorkoutFolderId folderId,
    WorkoutFolderId? parentFolderId,
  ) async {
    developer.log('Moving folder $folderId to parent $parentFolderId');
    try {
      await WorkoutTemplateService.instance.moveFolderToParent(
        folderId,
        parentFolderId,
      );
      unawaited(HapticFeedback.lightImpact());

      await WorkoutTemplateService.instance.loadFolders();
      await _loadCounts();
      await _loadTemplates();

      if (!mounted) return;
      final targetName = parentFolderId == null
          ? 'All Workouts'
          : _getFolderName(parentFolderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved folder to "$targetName"'),
          backgroundColor: context.appColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      developer.log(
        'Failed to move folder $folderId to parent $parentFolderId: $e',
      );
      unawaited(HapticFeedback.heavyImpact());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to move folder: $e'),
          backgroundColor: context.appScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _movePayloadIntoFolder(
    WorkoutBuilderDragPayload payload,
    WorkoutFolder folder,
  ) async {
    if (payload is TemplateDragPayload) {
      await _moveTemplateToFolder(payload.templateId, folder.id);
    } else if (payload is FolderDragPayload) {
      await _moveFolderToParent(payload.folderId, folder.id);
    }
    _onDragEnded();
  }

  bool _canDropPayloadIntoFolder(
    WorkoutBuilderDragPayload payload,
    WorkoutFolder folder,
  ) {
    if (payload is TemplateDragPayload) {
      return payload.parentFolderId != folder.id;
    }
    if (payload is FolderDragPayload) {
      return WorkoutTemplateService.instance.canMoveFolderToParentSync(
        payload.folderId,
        folder.id,
      );
    }
    return false;
  }

  bool _canMovePayloadToCurrentParent(WorkoutBuilderDragPayload payload) {
    final targetParentFolderId = _currentParentFolderId;
    if (payload is TemplateDragPayload) {
      return payload.parentFolderId != targetParentFolderId;
    }
    if (payload is FolderDragPayload) {
      return WorkoutTemplateService.instance.canMoveFolderToParentSync(
        payload.folderId,
        targetParentFolderId,
      );
    }
    return false;
  }

  Future<void> _movePayloadToCurrentParent(
    WorkoutBuilderDragPayload payload,
  ) async {
    final targetParentFolderId = _currentParentFolderId;
    if (payload is TemplateDragPayload) {
      await _moveTemplateToFolder(payload.templateId, targetParentFolderId);
    } else if (payload is FolderDragPayload) {
      await _moveFolderToParent(payload.folderId, targetParentFolderId);
    }
  }

  Future<void> _reorderFolders(int oldIndex, int newIndex) async {
    developer.log('Reordering folders: oldIndex=$oldIndex, newIndex=$newIndex');
    try {
      await WorkoutTemplateService.instance.reorderFoldersInParent(
        _selectedFolderId,
        oldIndex,
        newIndex,
      );
      unawaited(HapticFeedback.lightImpact());
      await WorkoutTemplateService.instance.loadFolders();
      setState(() {});
    } catch (e) {
      developer.log(
        'Failed to reorder folders: oldIndex=$oldIndex, newIndex=$newIndex, error=$e',
      );
      unawaited(HapticFeedback.heavyImpact());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reorder folders: $e'),
          backgroundColor: context.appScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String? get _currentParentFolderId {
    if (_selectedFolderId == null) {
      return null;
    }
    return WorkoutTemplateService.instance
        .getFolderById(_selectedFolderId!)
        ?.parentFolderId;
  }

  Future<void> _reorderTemplates(int oldIndex, int newIndex) async {
    developer.log(
      'Reordering templates: oldIndex=$oldIndex, newIndex=$newIndex',
    );
    try {
      await WorkoutTemplateService.instance.reorderTemplatesInFolder(
        _selectedFolderId,
        oldIndex,
        newIndex,
      );
      unawaited(HapticFeedback.lightImpact());
      await _loadTemplates();
      developer.log(
        'Successfully reordered templates: oldIndex=$oldIndex, newIndex=$newIndex',
      );
    } catch (e) {
      developer.log(
        'Failed to reorder templates: oldIndex=$oldIndex, newIndex=$newIndex, error=$e',
      );
      unawaited(HapticFeedback.heavyImpact());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder workouts: $e'),
            backgroundColor: context.appScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getFolderName(String folderId) {
    final folder = WorkoutTemplateService.instance.getFolderById(folderId);
    return folder?.name ?? 'Unknown Folder';
  }

  Widget _buildMaterialDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: context.appScheme.surface,
      titleTextStyle: context.appText.titleMedium?.copyWith(
        color: context.appColors.textPrimary,
      ),
      contentTextStyle: context.appText.bodyLarge?.copyWith(
        color: context.appColors.textPrimary,
      ),
      title: Text(title),
      content: content,
      actions: actions,
    );
  }

  Widget _buildFolderDialogTextField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      style: context.appText.bodyLarge?.copyWith(
        color: context.appColors.textPrimary,
      ),
      maxLength: 30,
      decoration: InputDecoration(
        labelText: 'Folder Name',
        labelStyle: context.appText.bodyMedium?.copyWith(
          color: context.appColors.textSecondary,
        ),
        counterStyle: context.appText.bodySmall?.copyWith(
          color: context.appColors.textSecondary,
        ),
        filled: true,
        fillColor: context.appColors.field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        counterText: '${controller.text.length}/30',
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildMaterialDialogAction({
    required String label,
    required VoidCallback onPressed,
    Color? foregroundColor,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: foregroundColor == null
          ? null
          : TextButton.styleFrom(foregroundColor: foregroundColor),
      child: Text(label),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Theme.of(context).platform == TargetPlatform.iOS
                ? CupertinoAlertDialog(
                    title: Text(
                      'Create Folder',
                      style: context.appText.titleMedium,
                    ),
                    content: Column(
                      children: [
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: controller,
                          maxLength: 30,
                          autofocus: true,
                          placeholder: 'Folder Name',
                          placeholderStyle: context.appText.bodyMedium!
                              .copyWith(color: context.appColors.textSecondary),
                          style: context.appText.bodyLarge!.copyWith(
                            color: context.appColors.textPrimary,
                          ),
                          cursorColor: context.appScheme.primary,
                          decoration: BoxDecoration(
                            color: context.appColors.field,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${controller.text.length}/30',
                            style: context.appText.bodySmall!.copyWith(
                              fontSize: 12,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () async {
                          final name = controller.text.trim();
                          if (name.isNotEmpty && name.length <= 30) {
                            await WorkoutTemplateService.instance.createFolder(
                              name,
                              parentFolderId: _selectedFolderId,
                            );
                            if (!context.mounted || !mounted) return;
                            Navigator.pop(context);
                            await _loadCounts();
                            await _loadTemplates();
                            setState(() {});
                          } else if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  )
                : _buildMaterialDialog(
                    title: 'Create Folder',
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFolderDialogTextField(
                          controller: controller,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                    actions: [
                      _buildMaterialDialogAction(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context),
                      ),
                      _buildMaterialDialogAction(
                        label: 'Create',
                        foregroundColor: context.appScheme.primary,
                        onPressed: () async {
                          final name = controller.text.trim();
                          if (name.isNotEmpty && name.length <= 30) {
                            await WorkoutTemplateService.instance.createFolder(
                              name,
                              parentFolderId: _selectedFolderId,
                            );
                            if (!context.mounted || !mounted) return;
                            Navigator.pop(context);
                            await _loadCounts();
                            await _loadTemplates();
                            setState(() {});
                          } else if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  );
          },
        );
      },
    );
  }

  void _showRenameFolderDialog(WorkoutFolder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Theme.of(context).platform == TargetPlatform.iOS
                ? CupertinoAlertDialog(
                    title: Text(
                      'Rename Folder',
                      style: context.appText.titleMedium,
                    ),
                    content: Column(
                      children: [
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: controller,
                          maxLength: 30,
                          autofocus: true,
                          placeholder: 'Folder Name',
                          placeholderStyle: context.appText.bodyMedium!
                              .copyWith(color: context.appColors.textSecondary),
                          style: context.appText.bodyLarge!.copyWith(
                            color: context.appColors.textPrimary,
                          ),
                          cursorColor: context.appScheme.primary,
                          decoration: BoxDecoration(
                            color: context.appColors.field,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${controller.text.length}/30',
                            style: context.appText.bodySmall!.copyWith(
                              fontSize: 12,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () async {
                          final name = controller.text.trim();
                          if (name.isNotEmpty &&
                              name != folder.name &&
                              name.length <= 30) {
                            final updatedFolder = folder.copyWith(name: name);
                            await WorkoutTemplateService.instance.updateFolder(
                              updatedFolder,
                            );
                            if (!context.mounted || !mounted) return;
                            Navigator.pop(context);
                            await _loadCounts();
                            setState(() {});
                          } else if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  )
                : _buildMaterialDialog(
                    title: 'Rename Folder',
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFolderDialogTextField(
                          controller: controller,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                    actions: [
                      _buildMaterialDialogAction(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context),
                      ),
                      _buildMaterialDialogAction(
                        label: 'Save',
                        foregroundColor: context.appScheme.primary,
                        onPressed: () async {
                          final name = controller.text.trim();
                          if (name.isNotEmpty &&
                              name != folder.name &&
                              name.length <= 30) {
                            final updatedFolder = folder.copyWith(name: name);
                            await WorkoutTemplateService.instance.updateFolder(
                              updatedFolder,
                            );
                            if (!context.mounted || !mounted) return;
                            Navigator.pop(context);
                            await _loadCounts();
                            setState(() {});
                          } else if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  );
          },
        );
      },
    );
  }

  void _showDeleteFolderDialog(WorkoutFolder folder) {
    final folderId = folder.id;
    final workoutCount = _templateCountByFolder[folderId] ?? 0;
    final contentText = workoutCount > 0
        ? 'Are you sure you want to delete "${folder.name}"?\n\n$workoutCount workout${workoutCount != 1 ? 's' : ''} will be moved to All Workouts.'
        : 'Are you sure you want to delete "${folder.name}"?';

    showDialog(
      context: context,
      builder: (context) {
        return Theme.of(context).platform == TargetPlatform.iOS
            ? CupertinoAlertDialog(
                title: Text(
                  'Delete Folder',
                  style: context.appText.titleMedium,
                ),
                content: Text(contentText, style: context.appText.bodyLarge),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () async {
                      await WorkoutTemplateService.instance.deleteFolder(
                        folder.id,
                      );
                      if (!context.mounted || !mounted) return;
                      Navigator.pop(context);
                      if (_selectedFolderId == folder.id) {
                        _selectedFolderId = null;
                      }
                      await _loadCounts();
                      await _loadTemplates();
                      setState(() {});
                    },
                    child: const Text('Delete'),
                  ),
                ],
              )
            : _buildMaterialDialog(
                title: 'Delete Folder',
                content: Text(contentText),
                actions: [
                  _buildMaterialDialogAction(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  _buildMaterialDialogAction(
                    label: 'Delete',
                    foregroundColor: context.appScheme.error,
                    onPressed: () async {
                      await WorkoutTemplateService.instance.deleteFolder(
                        folder.id,
                      );
                      if (!context.mounted || !mounted) return;
                      Navigator.pop(context);
                      if (_selectedFolderId == folder.id) {
                        _selectedFolderId = null;
                      }
                      await _loadCounts();
                      await _loadTemplates();
                      setState(() {});
                    },
                  ),
                ],
              );
      },
    );
  }

  void _showDeleteTemplateDialog(WorkoutTemplate template) {
    final contentText =
        'Are you sure you want to delete "${template.name}"?\n\nThis action cannot be undone.';
    showDialog(
      context: context,
      builder: (context) {
        return Theme.of(context).platform == TargetPlatform.iOS
            ? CupertinoAlertDialog(
                title: Text(
                  'Delete Workout',
                  style: context.appText.titleMedium,
                ),
                content: Text(contentText, style: context.appText.bodyLarge),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () async {
                      await WorkoutTemplateService.instance
                          .deleteWorkoutTemplate(template.id);
                      if (!context.mounted || !mounted) return;
                      Navigator.pop(context);
                      await _loadCounts();
                      await _loadTemplates();
                      setState(() {});
                    },
                    child: const Text('Delete'),
                  ),
                ],
              )
            : _buildMaterialDialog(
                title: 'Delete Workout',
                content: Text(contentText),
                actions: [
                  _buildMaterialDialogAction(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  _buildMaterialDialogAction(
                    label: 'Delete',
                    foregroundColor: context.appScheme.error,
                    onPressed: () async {
                      await WorkoutTemplateService.instance
                          .deleteWorkoutTemplate(template.id);
                      if (!context.mounted || !mounted) return;
                      Navigator.pop(context);
                      await _loadCounts();
                      await _loadTemplates();
                      setState(() {});
                    },
                  ),
                ],
              );
      },
    );
  }

  Future<void> _editWorkout(WorkoutTemplate template) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutScreen(workoutTemplate: template),
      ),
    );
    if (result == true) {
      await _loadCounts();
      await _loadTemplates();
      setState(() {});
    }
  }
}
