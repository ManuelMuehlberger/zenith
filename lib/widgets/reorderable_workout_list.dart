import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';
import 'expandable_workout_card.dart';

class ReorderableWorkoutList extends StatelessWidget {
  final List<Workout> workouts;
  final String? folderId;
  final Function(Workout) onWorkoutTap;
  final Function(Workout) onWorkoutMorePressed;
  final Function(String, String?) onWorkoutDroppedToFolder;
  final Function(int, int) onWorkoutReordered;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const ReorderableWorkoutList({
    super.key,
    required this.workouts,
    required this.folderId,
    required this.onWorkoutTap,
    required this.onWorkoutMorePressed,
    required this.onWorkoutDroppedToFolder,
    required this.onWorkoutReordered,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          folderId == null ? 'Workouts' : 'Workouts in folder',
          style: const TextStyle( 
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        _ReorderableWorkoutListView(
          workouts: workouts,
          folderId: folderId,
          onWorkoutTap: onWorkoutTap,
          onWorkoutMorePressed: onWorkoutMorePressed,
          onWorkoutDroppedToFolder: onWorkoutDroppedToFolder,
          onWorkoutReordered: onWorkoutReordered,
          onDragStarted: onDragStarted,
          onDragEnded: onDragEnded,
        ),
      ],
    );
  }
}

class _ReorderableWorkoutListView extends StatefulWidget {
  final List<Workout> workouts;
  final String? folderId;
  final Function(Workout) onWorkoutTap;
  final Function(Workout) onWorkoutMorePressed;
  final Function(String, String?) onWorkoutDroppedToFolder;
  final Function(int, int) onWorkoutReordered;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const _ReorderableWorkoutListView({
    required this.workouts,
    required this.folderId,
    required this.onWorkoutTap,
    required this.onWorkoutMorePressed,
    required this.onWorkoutDroppedToFolder,
    required this.onWorkoutReordered,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  State<_ReorderableWorkoutListView> createState() => _ReorderableWorkoutListViewState();
}

class _ReorderableWorkoutListViewState extends State<_ReorderableWorkoutListView> {
  int? _draggedIndex;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < widget.workouts.length; index++) ...[
          // Drop zone above each workout (except the first one)
          if (index > 0)
            _buildDropZone(index),
          
          // The workout card with drag target wrapper
          _buildWorkoutWithDropTarget(index),
        ],
        
        // Drop zone at the end
        _buildDropZone(widget.workouts.length),
      ],
    );
  }

  Widget _buildDropZone(int targetIndex) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] != 'workout') return false;
        
        final draggedIndex = data['index'] as int;
        setState(() {
          _hoveredIndex = targetIndex;
        });
        return draggedIndex != targetIndex && draggedIndex != targetIndex - 1;
      },
      onLeave: (data) {
        setState(() {
          _hoveredIndex = null;
        });
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final draggedIndex = data['index'] as int;
        
        int newIndex = targetIndex;
        if (targetIndex > draggedIndex) {
          newIndex = targetIndex - 1;
        }
        
        widget.onWorkoutReordered(draggedIndex, newIndex);
        
        setState(() {
          _hoveredIndex = null;
          _draggedIndex = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = _hoveredIndex == targetIndex && candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isHovering ? 60 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isHovering ? Colors.blue.withAlpha((255 * 0.3).round()) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isHovering ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: isHovering
              ? Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Drop here to reorder',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildWorkoutWithDropTarget(int index) {
    final workout = widget.workouts[index];
    final isCurrentlyDragged = _draggedIndex == index;

    final card = ExpandableWorkoutCard(
      workout: workout,
      index: index,
      onEditPressed: () => widget.onWorkoutTap(workout),
      onDeletePressed: () => widget.onWorkoutMorePressed(workout),
    );

    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'type': 'workout',
        'index': index,
        'id': workout.id,
      },
      onDragStarted: () {
        HapticFeedback.lightImpact();
        setState(() {
          _draggedIndex = index;
        });
        widget.onDragStarted?.call();
      },
      onDragEnd: (details) {
        setState(() {
          _draggedIndex = null;
          _hoveredIndex = null;
        });
        widget.onDragEnded?.call();
      },
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: card,
          ),
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isCurrentlyDragged ? 0.5 : 1.0,
        child: card,
      ),
    );
  }
}
