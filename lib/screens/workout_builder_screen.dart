import 'dart:async';
import 'dart:developer' as developer; // Add debug logging
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../constants/app_constants.dart';
import '../models/workout_folder.dart';
import '../models/workout_template.dart';
import '../services/workout_session_service.dart';
import '../services/workout_template_service.dart';
import '../theme/app_theme.dart';
import '../widgets/folder_card.dart';
import '../widgets/profile_icon_button.dart';
import '../widgets/reorderable_workout_template_list.dart';
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
  bool _isPillMaximized = true;
  double _lastScrollOffset = 0.0;

  // Local caches for templates and counts (to keep the UI responsive and consistent)
  List<WorkoutTemplate> _templates = [];
  Map<String?, int> _templateCountByFolder = {};

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _scrollController.addListener(_onScroll);
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onDragStarted() {
    developer.log('Drag started, selectedFolderId: $_selectedFolderId');
    // Only set _isDragging if we are inside a folder,
    // as the "drop out" animation is only relevant then.
    if (_selectedFolderId != null) {
      setState(() {
        _isDragging = true;
      });
    }
  }

  void _onDragEnded() {
    developer.log('Drag ended');
    // Always reset _isDragging on drag end.
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: context.appScheme.surface.withValues(
                    alpha: 0,
                  ),
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
                              child: Container(
                                color: context.appColors.overlayStrong,
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
                            background: Align(
                              alignment: Alignment.center,
                              child: _buildLargeTitle(),
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
            floatingActionButton: _buildPillFloatingActionButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

    return Column(
      children: [
        if (_selectedFolderId != null) _buildBreadcrumbNavigation(),
        _buildContent(),
        SizedBox(
          height:
              MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight,
        ),
      ],
    );
  }

  Widget _buildBreadcrumbNavigation() {
    final appScheme = context.appScheme;
    final appColors = context.appColors;
    final breadcrumbStyle = context.appText.titleSmall!;

    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) async {
        final data = details.data;
        developer.log('Breadcrumb onAcceptWithDetails: $data');
        if (data['type'] == 'template') {
          await _moveTemplateToFolder(data['templateId'], null);
        }
        _onDragEnded();
      },
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        developer.log('Breadcrumb onWillAcceptWithDetails: $data');
        return data['type'] == 'template';
      },
      onLeave: (data) {},
      builder: (context, candidateData, rejectedData) {
        final isHoveringOverDropTarget = candidateData.isNotEmpty;
        final showAnimation = _isDragging || isHoveringOverDropTarget;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.diagonal3Values(
            showAnimation ? 1.02 : 1.0,
            showAnimation ? 1.02 : 1.0,
            1.0,
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                sigmaY: AppConstants.GLASS_BLUR_SIGMA,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: showAnimation ? 16.0 : 12.0,
                ),
                decoration: BoxDecoration(
                  color: showAnimation
                      ? appScheme.primary.withValues(alpha: 0.25)
                      : Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.3),
                  border: Border.all(
                    color: showAnimation
                        ? appScheme.primary.withValues(alpha: 0.6)
                        : appColors.textPrimary.withValues(alpha: 0.1),
                    width: showAnimation ? 2.0 : 0.5,
                  ),
                  borderRadius: showAnimation
                      ? BorderRadius.circular(12.0)
                      : BorderRadius.zero,
                  boxShadow: showAnimation
                      ? [
                          BoxShadow(
                            color: appScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8.0,
                            spreadRadius: 2.0,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(showAnimation ? 8.0 : 4.0),
                          decoration: BoxDecoration(
                            color: showAnimation
                                ? appScheme.primary.withValues(alpha: 0.4)
                                : appColors.textPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              showAnimation ? 10 : 6,
                            ),
                          ),
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: showAnimation ? 0.1 : 0.0,
                            child: Icon(
                              Icons.arrow_upward,
                              color: showAnimation
                                  ? appColors.textPrimary
                                  : appColors.textSecondary,
                              size: showAnimation ? 18 : 14,
                            ),
                          ),
                        ),
                        SizedBox(width: showAnimation ? 16 : 12),
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFolderId = null;
                              });
                              _loadTemplates();
                            },
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: breadcrumbStyle.copyWith(
                                color: showAnimation
                                    ? appColors.textPrimary
                                    : appScheme.primary,
                                fontSize: showAnimation ? 17 : 15,
                                fontWeight: showAnimation
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              child: const Text('All Workouts'),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            Icons.chevron_right,
                            color: appColors.textTertiary,
                            size: 16,
                          ),
                        ),
                        Flexible(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: breadcrumbStyle.copyWith(
                              color: showAnimation
                                  ? appColors.textSecondary
                                  : appColors.textPrimary,
                              fontSize: showAnimation ? 16 : 15,
                              fontWeight: FontWeight.w600,
                            ),
                            child: Text(
                              _getFolderName(_selectedFolderId!),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (showAnimation) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: appColors.textPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: appColors.textPrimary.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.move_down_outlined,
                                color: appColors.textPrimary,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Drop workout here',
                                style: context.appText.labelMedium!.copyWith(
                                  color: appColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildContent() {
    final folders = WorkoutTemplateService.instance.folders;
    final templates = _templates;

    if (folders.isEmpty && templates.isEmpty && _selectedFolderId == null) {
      return _buildEmptyState();
    }
    if (templates.isEmpty && _selectedFolderId != null) {
      return _buildEmptyState(inFolder: true);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedFolderId == null) ...[
            if (folders.isNotEmpty) ...[
              Text(
                'Folders',
                style: context.appText.titleMedium!.copyWith(
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...folders.map((folder) {
                final count = _templateCountByFolder[folder.id] ?? 0;
                return FolderCard(
                  folder: folder,
                  itemCount: count,
                  onTap: () => _selectFolder(folder.id),
                  onRenamePressed: () => _showRenameFolderDialog(folder),
                  onDeletePressed: () => _showDeleteFolderDialog(folder),
                  onWorkoutDropped: (templateId) =>
                      _moveTemplateToFolder(templateId, folder.id),
                  isDragging: _isDragging,
                );
              }),
              const SizedBox(height: 16),
            ],
          ],
          ReorderableWorkoutTemplateList(
            templates: templates,
            folderId: _selectedFolderId,
            onTemplateTap: _editWorkout,
            onTemplateDeletePressed: _showDeleteTemplateDialog,
            onTemplateReordered: _reorderTemplates,
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
              inFolder ? Icons.folder_open_outlined : Icons.fitness_center,
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
                  ? 'Drag workouts here or tap the + button to create one in this folder.'
                  : 'Tap the + button to create your first workout',
              style: context.appText.labelMedium!.copyWith(
                color: context.appColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

      // Refresh counts and current list
      await _loadCounts();
      await _loadTemplates();

      if (mounted) {
        final targetFolderName = folderId != null
            ? (_getFolderName(folderId))
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
                            );
                            if (!context.mounted || !mounted) return;
                            Navigator.pop(context);
                            await _loadCounts();
                            await _loadTemplates();
                            setState(() {});
                          } else {
                            if (mounted) Navigator.pop(context);
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
                            );
                            if (!context.mounted || !mounted) return;
                            Navigator.pop(context);
                            await _loadCounts();
                            await _loadTemplates();
                            setState(() {});
                          } else {
                            if (mounted) Navigator.pop(context);
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
                          } else {
                            if (mounted) Navigator.pop(context);
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
                          } else {
                            if (mounted) Navigator.pop(context);
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

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;

    // Always show pill when at the top
    if (currentOffset <= 0) {
      if (!_isPillMaximized) {
        setState(() {
          _isPillMaximized = true;
        });
      }
      _lastScrollOffset = currentOffset;
      return;
    }

    // Hysteresis check
    if (delta.abs() > AppConstants.SCROLL_HYSTERESIS_THRESHOLD) {
      if (delta > 0) {
        // Scrolling down
        if (_isPillMaximized) {
          setState(() {
            _isPillMaximized = false;
          });
        }
      } else {
        // Scrolling up
        if (!_isPillMaximized) {
          setState(() {
            _isPillMaximized = true;
          });
        }
      }
      _lastScrollOffset = currentOffset;
    }
  }

  Widget _buildPillFloatingActionButton() {
    final appScheme = context.appScheme;
    final onPrimary = appScheme.onPrimary;
    final double bottomPadding = MediaQuery.of(context).padding.bottom > 0
        ? MediaQuery.of(context).padding.bottom + 16.0
        : 24.0;

    // Maximized content with two separate tap targets
    final Widget maximizedContent = ClipRRect(
      borderRadius: BorderRadius.circular(28.0),
      child: Row(
        children: [
          // Left side - Create Workout (tappable)
          Expanded(
            child: Material(
              color: appScheme.surface.withValues(alpha: 0),
              child: InkWell(
                onTap: _createWorkout,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Only show content if there's enough space
                    if (constraints.maxWidth < 100) {
                      return const SizedBox.shrink();
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: onPrimary, size: 24.0),
                        if (constraints.maxWidth > 120) ...[
                          const SizedBox(width: 8.0),
                          Flexible(
                            child: Text(
                              'Create Workout',
                              style: context.appText.titleSmall!.copyWith(
                                color: onPrimary,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // Divider
          Container(
            width: 1.0,
            height: 32.0,
            color: onPrimary.withValues(alpha: 0.3),
          ),
          // Right side - More Options (tappable)
          PullDownButton(
            itemBuilder: (context) => [
              if (_selectedFolderId == null)
                PullDownMenuItem(
                  onTap: () => _showCreateFolderDialog(),
                  title: 'Create Folder',
                  icon: Icons.create_new_folder,
                ),
              PullDownMenuItem(
                onTap: () => _createWorkout(),
                title: 'Create Workout',
                icon: Icons.fitness_center,
              ),
            ],
            buttonBuilder: (context, showMenu) => Material(
              color: appScheme.surface.withValues(alpha: 0),
              child: InkWell(
                onTap: showMenu,
                child: SizedBox(
                  width: 56.0, // Fixed width for the tap target
                  height: 56.0,
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: onPrimary,
                    size: 24.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Minimized content
    final Widget minimizedContent = Material(
      color: appScheme.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: () {
          setState(() {
            _isPillMaximized = true;
          });
        },
        borderRadius: BorderRadius.circular(28.0),
        child: Center(child: Icon(Icons.add, color: onPrimary, size: 28.0)),
      ),
    );

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: 56.0,
        width: _isPillMaximized ? 230.0 : 56.0,
        decoration: BoxDecoration(
          color: appScheme.primary,
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow,
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Maximized state content
            IgnorePointer(
              ignoring: !_isPillMaximized,
              child: AnimatedOpacity(
                opacity: _isPillMaximized ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeIn,
                child: maximizedContent,
              ),
            ),
            // Minimized state content
            IgnorePointer(
              ignoring: _isPillMaximized,
              child: AnimatedOpacity(
                opacity: _isPillMaximized ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeIn,
                child: minimizedContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
