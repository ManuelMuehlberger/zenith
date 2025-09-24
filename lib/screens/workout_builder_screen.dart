import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:pull_down_button/pull_down_button.dart';
import '../models/workout_template.dart';
import '../models/workout_folder.dart';
import '../services/workout_template_service.dart';
import '../services/workout_session_service.dart';
import '../widgets/folder_card.dart';
import '../widgets/reorderable_workout_template_list.dart';
import 'create_workout_screen.dart';
import 'active_workout_screen.dart';
import '../constants/app_constants.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  const WorkoutBuilderScreen({super.key});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedFolderId;
  bool _isLoading = true;
  Timer? _timer;
  bool _isDragging = false;
  bool _isPillMaximized = true;

  // Local caches for templates and counts (to keep the UI responsive and consistent)
  List<WorkoutTemplate> _templates = [];
  Map<String?, int> _templateCountByFolder = {};

  @override
  void initState() {
    super.initState();
    _startTimer();
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
    final counts = await WorkoutTemplateService.instance.getTemplateCountByFolder();
    if (mounted) {
      setState(() {
        _templateCountByFolder = counts;
      });
    }
  }

  Future<void> _loadTemplates() async {
    List<WorkoutTemplate> templates;
    if (_selectedFolderId == null) {
      templates = await WorkoutTemplateService.instance.getWorkoutTemplatesWithoutFolder();
    } else {
      templates = await WorkoutTemplateService.instance.getWorkoutTemplatesByFolder(_selectedFolderId!);
    }
    if (mounted) {
      setState(() {
        _templates = templates;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (WorkoutSessionService.instance.hasActiveSession) {
        setState(() {});
      }
    });
  }

  void _onDragStarted() {
    // Only set _isDragging if we are inside a folder,
    // as the "drop out" animation is only relevant then.
    if (_selectedFolderId != null) {
      setState(() {
        _isDragging = true;
      });
    }
  }

  void _onDragEnded() {
    // Always reset _isDragging on drag end.
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionService = WorkoutSessionService.instance;
    
    if (sessionService.hasActiveSession) {
      return ActiveWorkoutScreen(session: sessionService.currentSession!);
    }
    
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight;
    
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
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: _buildMainContent(headerHeight),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                  child: Container(
                    height: headerHeight,
                    color: AppConstants.HEADER_BG_COLOR_MEDIUM,
                    child: SafeArea(
                      bottom: false,
                      child: _buildHeaderContent(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildPillFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildHeaderContent() {
    final bool isInsideFolder = _selectedFolderId != null;
    String title = 'Workouts';
    if (isInsideFolder) {
      title = _getFolderName(_selectedFolderId!);
    }

    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: EdgeInsets.only(left: isInsideFolder ? 0 : 16.0, right: 16.0),
        child: Row(
          children: [
            if (isInsideFolder)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedFolderId = null;
                  });
                  _loadTemplates();
                },
              ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: isInsideFolder ? TextAlign.center : TextAlign.start, 
              ),
            ),
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
              buttonBuilder: (context, showMenu) => IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
                onPressed: showMenu,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double headerHeight) {
    if (_isLoading) {
      return Column(
        children: [
          SizedBox(height: headerHeight),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: headerHeight),
        ),
        if (_selectedFolderId != null)
          SliverToBoxAdapter(
            child: _buildBreadcrumbNavigation(),
          ),
        SliverToBoxAdapter(
          child: _buildContent(),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbNavigation() {
    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) async {
        final data = details.data;
        if (data['type'] == 'template') {
          await _moveTemplateToFolder(data['templateId'], null);
        }
        _onDragEnded(); 
      },
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data['type'] == 'template';
      },
      onLeave: (data) {
      },
      builder: (context, candidateData, rejectedData) {
        final isHoveringOverDropTarget = candidateData.isNotEmpty;
        final showAnimation = _isDragging || isHoveringOverDropTarget;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(showAnimation ? 1.02 : 1.0),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0, 
                  vertical: showAnimation ? 16.0 : 12.0,
                ),
                decoration: BoxDecoration(
                  color: showAnimation 
                      ? Colors.blue.withAlpha((255 * 0.25).round())
                      : Colors.black.withAlpha((255 * 0.3).round()),
                  border: Border.all(
                    color: showAnimation 
                        ? Colors.blue.withAlpha((255 * 0.6).round())
                        : Colors.white.withAlpha((255 * 0.1).round()),
                    width: showAnimation ? 2.0 : 0.5,
                  ),
                  borderRadius: showAnimation 
                      ? BorderRadius.circular(12.0) 
                      : BorderRadius.zero,
                  boxShadow: showAnimation ? [
                    BoxShadow(
                      color: Colors.blue.withAlpha((255 * 0.3).round()),
                      blurRadius: 8.0,
                      spreadRadius: 2.0,
                    ),
                  ] : null,
                ),
                child: Column( //Column for vertical arrangement
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
                                ? Colors.blue.withAlpha((255 * 0.4).round())
                                : Colors.white.withAlpha((255 * 0.1).round()),
                            borderRadius: BorderRadius.circular(showAnimation ? 10 : 6),
                          ),
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: showAnimation ? 0.1 : 0.0,
                            child: Icon(
                              Icons.arrow_upward,
                              color: showAnimation ? Colors.white : Colors.grey[400],
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
                              style: TextStyle(
                                color: showAnimation ? Colors.white : Colors.blue,
                                fontSize: showAnimation ? 17 : 15,
                                fontWeight: showAnimation ? FontWeight.w600 : FontWeight.w500,
                              ),
                              child: const Text('All Workouts'),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.grey[500],
                            size: 16,
                          ),
                        ),
                        Flexible(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: showAnimation ? Colors.grey[300] : Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.2).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha((255 * 0.3).round()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.move_down_outlined,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          const Text(
            'Drop workout here',
            style: TextStyle(
              color: Colors.white,
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
              const Text(
                'Folders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...folders.map((folder) {
                final count = _templateCountByFolder[folder.id] ?? 0;
                return FolderCard(
                  folder: folder,
                  itemCount: count,
                  onTap: () => _selectFolder(folder.id),
                  onMorePressed: () => _showFolderActionSheet(folder),
                  onWorkoutDropped: (templateId) => _moveTemplateToFolder(templateId, folder.id),
                );
              }),
              const SizedBox(height: 16),
            ],
          ],
          
          ReorderableWorkoutTemplateList(
            templates: templates,
            folderId: _selectedFolderId,
            onTemplateTap: _editWorkout,
            onTemplateMorePressed: _showTemplateActionSheet,
            onTemplateDroppedToFolder: _moveTemplateToFolder,
            onTemplateReordered: _reorderTemplates,
            onDragStarted: _onDragStarted,
            onDragEnded: _onDragEnded,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({bool inFolder = false}) {
    return Container(
      height: 400, 
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              inFolder ? Icons.folder_open_outlined : Icons.fitness_center,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              inFolder ? 'This folder is empty' : 'No workouts created yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              inFolder ? 'Drag workouts here or tap the + button to create one in this folder.' : 'Tap the + button to create your first workout',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
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

  Future<void> _moveTemplateToFolder(String templateId, String? folderId) async {
    try {
      await WorkoutTemplateService.instance.moveTemplateToFolder(templateId, folderId);
      HapticFeedback.lightImpact();

      // Refresh counts and current list
      await _loadCounts();
      await _loadTemplates();
      
      if (mounted) {
        final targetFolderName = folderId != null 
            ? (_getFolderName(folderId)) 
            : 'All Workouts';
        final message = 'Moved to "$targetFolderName"';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move workout: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _reorderTemplates(int oldIndex, int newIndex) async {
    try {
      await WorkoutTemplateService.instance.reorderTemplatesInFolder(_selectedFolderId, oldIndex, newIndex);
      HapticFeedback.lightImpact();
      await _loadTemplates();
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder workouts: $e'),
            backgroundColor: Colors.red,
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

  void _showCreateActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (_selectedFolderId == null)
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha((255 * 0.2).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.create_new_folder, color: Colors.blue, size: 20),
                  ),
                  title: const Text('Create Folder', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateFolderDialog();
                  },
                ),
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.green, size: 20),
                ),
                title: const Text('Create Workout', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _createWorkout();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showFolderActionSheet(WorkoutFolder folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                ),
                title: const Text('Rename Folder', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameFolderDialog(folder);
                },
              ),
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
                title: const Text('Delete Folder', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteFolderDialog(folder);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateActionSheet(WorkoutTemplate template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Keeping actions visually similar: Edit and Delete
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                ),
                title: const Text('Edit Workout', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _editWorkout(template);
                },
              ),
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
                title: const Text('Delete Workout', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteTemplateDialog(template);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    int currentLength = 0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Theme.of(context).platform == TargetPlatform.iOS
                ? CupertinoAlertDialog(
                    title: const Text('Create Folder'),
                    content: Column(
                      children: [
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: controller,
                          maxLength: 30,
                          autofocus: true,
                          placeholder: 'Folder Name',
                          placeholderStyle: TextStyle(color: CupertinoColors.systemGrey),
                          style: TextStyle(color: CupertinoColors.white),
                          cursorColor: CupertinoColors.activeBlue,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (value) {
                            setState(() {
                              currentLength = value.length;
                            });
                          },
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${controller.text.length}/30',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
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
                            await WorkoutTemplateService.instance.createFolder(name);
                            if (mounted) {
                              Navigator.pop(context);
                              await _loadCounts();
                              await _loadTemplates();
                              setState(() {});
                            }
                          } else {
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  )
                : AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: const Text('Create Folder', style: TextStyle(color: Colors.white)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          maxLength: 30,
                          decoration: InputDecoration(
                            labelText: 'Folder Name',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            counterText: '${controller.text.length}/30',
                          ),
                          onChanged: (value) {
                            setState(() {
                              currentLength = value.length;
                            });
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
                      ),
                      TextButton(
                        onPressed: () async {
                          final name = controller.text.trim();
                          if (name.isNotEmpty && name.length <= 30) {
                            await WorkoutTemplateService.instance.createFolder(name);
                            if (mounted) {
                              Navigator.pop(context);
                              await _loadCounts();
                              await _loadTemplates();
                              setState(() {});
                            }
                          } else {
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text('Create', style: TextStyle(color: Colors.blue)),
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
    int currentLength = folder.name.length;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Theme.of(context).platform == TargetPlatform.iOS
                ? CupertinoAlertDialog(
                    title: const Text('Rename Folder'),
                    content: Column(
                      children: [
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: controller,
                          maxLength: 30,
                          autofocus: true,
                          placeholder: 'Folder Name',
                          placeholderStyle: TextStyle(color: CupertinoColors.systemGrey),
                          style: TextStyle(color: CupertinoColors.white),
                          cursorColor: CupertinoColors.activeBlue,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (value) {
                            setState(() {
                              currentLength = value.length;
                            });
                          },
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${controller.text.length}/30',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
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
                            await WorkoutTemplateService.instance.updateFolder(updatedFolder);
                            if (mounted) {
                              Navigator.pop(context);
                              await _loadCounts();
                              setState(() {});
                            }
                          } else {
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  )
                : AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: const Text('Rename Folder', style: TextStyle(color: Colors.white)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          maxLength: 30,
                          decoration: InputDecoration(
                            labelText: 'Folder Name',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            counterText: '${controller.text.length}/30',
                          ),
                          onChanged: (value) {
                            setState(() {
                              currentLength = value.length;
                            });
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
                      ),
                      TextButton(
                        onPressed: () async {
                          final name = controller.text.trim();
                          if (name.isNotEmpty &&
                              name != folder.name &&
                              name.length <= 30) {
                            final updatedFolder = folder.copyWith(name: name);
                            await WorkoutTemplateService.instance.updateFolder(updatedFolder);
                            if (mounted) {
                              Navigator.pop(context);
                              await _loadCounts();
                              setState(() {});
                            }
                          } else {
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text('Save', style: TextStyle(color: Colors.blue)),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Folder', style: TextStyle(color: Colors.white)),
        content: Text(
          workoutCount > 0
              ? 'Are you sure you want to delete "${folder.name}"?\n\n$workoutCount workout${workoutCount != 1 ? 's' : ''} will be moved to All Workouts.'
              : 'Are you sure you want to delete "${folder.name}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () async {
              await WorkoutTemplateService.instance.deleteFolder(folder.id);
              if (mounted) {
                Navigator.pop(context);
                if (_selectedFolderId == folder.id) {
                  _selectedFolderId = null;
                }
                await _loadCounts();
                await _loadTemplates();
                setState(() {});
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteTemplateDialog(WorkoutTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Workout', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${template.name}"?\n\nThis action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () async {
              await WorkoutTemplateService.instance.deleteWorkoutTemplate(template.id);
              if (mounted) {
                Navigator.pop(context);
                await _loadCounts();
                await _loadTemplates();
                setState(() {});
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _createWorkout() async {
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

  void _editWorkout(WorkoutTemplate template) async {
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

    final offset = _scrollController.offset;
    const double threshold = 50.0;

    // At the top, always maximize the pill
    if (offset < threshold) {
      if (!_isPillMaximized) {
        setState(() {
          _isPillMaximized = true;
        });
      }
      return;
    }

    // Scrolling down, minimize the pill
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isPillMaximized) {
        setState(() {
          _isPillMaximized = false;
        });
      }
    }
    // Scrolling up, maximize the pill
    else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isPillMaximized) {
        setState(() {
          _isPillMaximized = true;
        });
      }
    }
  }

  Widget _buildPillFloatingActionButton() {
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
              color: Colors.transparent,
              child: InkWell(
                onTap: _createWorkout,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add, color: Colors.white, size: 24.0),
                    SizedBox(width: 8.0),
                    Flexible(
                      child: Text(
                        'Create Workout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Divider
          Container(
            width: 1.0,
            height: 32.0,
            color: Colors.white.withOpacity(0.3),
          ),
          // Right side - More Options (tappable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showMoreOptionsSheet,
              child: const SizedBox(
                width: 56.0, // Fixed width for the tap target
                height: 56.0,
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white,
                  size: 24.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Minimized content
    final Widget minimizedContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isPillMaximized = true;
          });
        },
        borderRadius: BorderRadius.circular(28.0),
        child: const Center(
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 28.0,
          ),
        ),
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
          color: AppConstants.ACCENT_COLOR,
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Maximized state content
            AnimatedOpacity(
              opacity: _isPillMaximized ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: maximizedContent,
            ),
            // Minimized state content
            AnimatedOpacity(
              opacity: _isPillMaximized ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: minimizedContent,
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppConstants.CARD_BG_COLOR,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppConstants.SHEET_RADIUS),
            topRight: Radius.circular(AppConstants.SHEET_RADIUS),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Freeform Workout option (placeholder for future implementation)
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppConstants.ACCENT_COLOR.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: AppConstants.ACCENT_COLOR,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Freeform Workout',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Coming soon',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement freeform workout
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Freeform workout coming soon!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
              // Create Folder option (only show when not in a folder)
              if (_selectedFolderId == null)
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.create_new_folder,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Create Folder',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateFolderDialog();
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
