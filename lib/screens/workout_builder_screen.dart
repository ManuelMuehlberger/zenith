import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import '../models/workout.dart';
import '../models/workout_folder.dart';
import '../services/workout_service.dart';
import '../services/workout_session_service.dart';
import '../widgets/folder_card.dart';
import '../widgets/reorderable_workout_list.dart';
import 'create_workout_screen.dart';
import 'active_workout_screen.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  const WorkoutBuilderScreen({super.key});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  String? _selectedFolderId;
  final bool _isLoading = false;
  Timer? _timer;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    height: headerHeight,
                    color: Colors.black54,
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
        floatingActionButton: FloatingActionButton(
          onPressed: _createWorkout,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
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
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 28),
              onPressed: () => _showCreateActionSheet(),
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
      ],
    );
  }

  Widget _buildBreadcrumbNavigation() {
    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) async {
        final data = details.data;
        if (data['type'] == 'workout') {
          await _moveWorkoutToFolder(data['workoutId'], null);
        }
        _onDragEnded(); 
      },
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data['type'] == 'workout';
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
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
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
    final folders = WorkoutService.instance.folders;
    final workouts = _selectedFolderId == null
        ? WorkoutService.instance.getWorkoutsNotInFolder()
        : WorkoutService.instance.getWorkoutsInFolder(_selectedFolderId);

    if (folders.isEmpty && workouts.isEmpty && _selectedFolderId == null) {
      return _buildEmptyState();
    }
     if (workouts.isEmpty && _selectedFolderId != null) {
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
              ...folders.map((folder) => FolderCard(
                folder: folder,
                onTap: () => _selectFolder(folder.id),
                onMorePressed: () => _showFolderActionSheet(folder),
                onWorkoutDropped: (workoutId) => _moveWorkoutToFolder(workoutId, folder.id),
              )),
              const SizedBox(height: 16),
            ],
          ],
          
          ReorderableWorkoutList(
            workouts: workouts,
            folderId: _selectedFolderId,
            onWorkoutTap: _editWorkout,
            onWorkoutMorePressed: _showWorkoutActionSheet,
            onWorkoutDroppedToFolder: _moveWorkoutToFolder,
            onWorkoutReordered: _reorderWorkouts,
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
              inFolder ? 'Drag workouts here or tap + to create one in this folder.' : 'Tap the + button to create your first workout',
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
  }

  Future<void> _moveWorkoutToFolder(String workoutId, String? folderId) async {
    try {
      await WorkoutService.instance.moveWorkoutToFolder(workoutId, folderId);
      HapticFeedback.lightImpact();
      
      if (folderId == null && _selectedFolderId != null) {
        // No state change needed here if moving to root, breadcrumb will disappear
        // _selectedFolderId will be set to null by the onTap of "All Workouts" or back button
      } else {
        setState(() {}); // Refresh current folder or root
      }
      
      if (mounted) {
        final workout = WorkoutService.instance.getWorkoutById(workoutId);
        final String targetFolderName = folderId != null 
            ? (_getFolderName(folderId)) 
            : 'All Workouts';
        final message = 'Moved "${workout?.name}" to "$targetFolderName"';
        
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

  Future<void> _reorderWorkouts(int oldIndex, int newIndex) async {
    try {
      await WorkoutService.instance.reorderWorkoutsInFolder(_selectedFolderId, oldIndex, newIndex);
      HapticFeedback.lightImpact();
      setState(() {});
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
    final folder = WorkoutService.instance.getFolderById(folderId);
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

  void _showWorkoutActionSheet(Workout workout) {
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
                    color: Colors.green.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.green, size: 20),
                ),
                title: const Text('Start Workout', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _startWorkout(workout);
                },
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
                title: const Text('Edit Workout', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _editWorkout(workout);
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
                  _showDeleteWorkoutDialog(workout);
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
                            await WorkoutService.instance.createFolder(name);
                            if (mounted) {
                              Navigator.pop(context);
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
                            await WorkoutService.instance.createFolder(name);
                            if (mounted) {
                              Navigator.pop(context);
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
                            await WorkoutService.instance.updateFolder(updatedFolder);
                            if (mounted) {
                              Navigator.pop(context);
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
                            await WorkoutService.instance.updateFolder(updatedFolder);
                            if (mounted) {
                              Navigator.pop(context);
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
    final workoutCount = WorkoutService.instance.getWorkoutsInFolder(folder.id).length;
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
              await WorkoutService.instance.deleteFolder(folder.id);
              if (mounted) {
                Navigator.pop(context);
                if (_selectedFolderId == folder.id) {
                  _selectedFolderId = null;
                }
                setState(() {});
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteWorkoutDialog(Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Workout', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${workout.name}"?\n\nThis action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () async {
              await WorkoutService.instance.deleteWorkout(workout.id);
              if (mounted) {
                Navigator.pop(context);
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
      setState(() {});
    }
  }

  void _editWorkout(Workout workout) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutScreen(workout: workout),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _startWorkout(Workout workout) async {
    try {
      await WorkoutSessionService.instance.startWorkout(workout);
      HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start workout: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
