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
import '../widgets/folder_breadcrumbs_card.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  final String? folderId;
  const WorkoutBuilderScreen({super.key, this.folderId});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  final ScrollController _scrollController = ScrollController();
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
    if (widget.folderId == null) {
      templates = await WorkoutTemplateService.instance
          .getWorkoutTemplatesWithoutFolder();
    } else {
      templates = await WorkoutTemplateService.instance
          .getWorkoutTemplatesByFolder(widget.folderId!);
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
    developer.log('Drag started, selectedFolderId: $widget.folderId');
    setState(() {
      _activeDragPayload = payload;
      _isDragging = widget.folderId != null;
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

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                centerTitle: true,
                automaticallyImplyLeading: false,
                leading: widget.folderId != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.appScheme.surface.withValues(
                                alpha: 0.6,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                CupertinoIcons.back,
                                color: context.appScheme.onSurface,
                              ),
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: kToolbarHeight),
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
        );
      },
    );
  }

  Widget _buildSmallTitle() {
    final bool isInsideFolder = widget.folderId != null;
    String title = 'Workouts';
    if (isInsideFolder) {
      title = _getFolderName(widget.folderId!);
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
    final bool isInsideFolder = widget.folderId != null;
    String title = 'Workouts';
    if (isInsideFolder) {
      title = _getFolderName(widget.folderId!);
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
      widget.folderId,
    );

    return Column(
      children: [
        if (widget.folderId != null) _buildBreadcrumbNavigation(),
        _buildContent(folders: folders),
        const MainDockSpacer(),
      ],
    );
  }

  Widget _buildBreadcrumbNavigation() {
    if (widget.folderId == null) return const SizedBox.shrink();
    final folder = WorkoutTemplateService.instance.getFolderById(
      widget.folderId!,
    );
    if (folder == null) return const SizedBox.shrink();

    final path = WorkoutTemplateService.instance.getFolderPathSync(
      widget.folderId!,
    );
    final ancestors = path.length > 1
        ? path.take(path.length - 1).toList(growable: false)
        : const <WorkoutFolder>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: FolderBreadcrumbsCard(
        folder: folder,
        ancestors: ancestors,
        activeDragPayload: _activeDragPayload,
        onMovePayloadToParent: _movePayloadToCurrentParent,
        canMovePayloadToParent: _canMovePayloadToCurrentParent,
        onNavigateToFolder: (id) {
          if (id == null) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            Navigator.of(context)
                .push(
                  CupertinoPageRoute(
                    builder: (_) => WorkoutBuilderScreen(folderId: id),
                  ),
                )
                .then((_) => _initialLoad());
          }
        },
        onDragEnded: _onDragEnded,
        parentFolderName: _currentParentFolderId == null
            ? 'All Workouts'
            : _getFolderName(_currentParentFolderId!),
        isDragging: _isDragging,
      ),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentSectionHeader(
            title: 'Folders',
            countLabel: '${folders.length}',
            action: _buildAddFolderButton(),
          ),
          const SizedBox(height: 10),
          if (folders.isNotEmpty) ...[
            ReorderableFolderList(
              folders: folders,
              currentParentFolderId: widget.folderId,
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
          ] else ...[
            _buildInlineSectionEmptyState(
              message: widget.folderId != null
                  ? 'No folders in this folder yet. Use Add folder to create one here.'
                  : 'No folders created yet. Use Add folder to organize your workouts.',
            ),
          ],
          const SizedBox(height: 16),
          ReorderableWorkoutTemplateList(
            templates: templates,
            folderId: widget.folderId,
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

  Widget _buildInlineSectionEmptyState({required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appColors.surfaceAlt,
        borderRadius: AppTheme.workoutCardBorderRadius,
      ),
      child: Text(
        message,
        style: context.appText.bodyMedium?.copyWith(
          color: context.appColors.textSecondary,
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

  Future<void> _createWorkout() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutScreen(folderId: widget.folderId),
      ),
    );
    if (result == true) {
      await _loadCounts();
      await _loadTemplates();
      setState(() {});
    }
  }

  void _selectFolder(String folderId) {
    Navigator.of(context)
        .push(
          CupertinoPageRoute(
            builder: (_) => WorkoutBuilderScreen(folderId: folderId),
          ),
        )
        .then((_) => _initialLoad());
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
        widget.folderId,
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
    if (widget.folderId == null) {
      return null;
    }
    return WorkoutTemplateService.instance
        .getFolderById(widget.folderId!)
        ?.parentFolderId;
  }

  Future<void> _reorderTemplates(int oldIndex, int newIndex) async {
    developer.log(
      'Reordering templates: oldIndex=$oldIndex, newIndex=$newIndex',
    );
    try {
      await WorkoutTemplateService.instance.reorderTemplatesInFolder(
        widget.folderId,
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
                              parentFolderId: widget.folderId,
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
                              parentFolderId: widget.folderId,
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
                      if (widget.folderId == folder.id) {
                        Navigator.of(context).pop();
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
                      if (widget.folderId == folder.id) {
                        Navigator.of(context).pop();
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
