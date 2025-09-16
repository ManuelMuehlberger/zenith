import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import 'expandable_workout_card.dart';

class ReorderableWorkoutTemplateList extends StatelessWidget {
  final List<WorkoutTemplate> templates;
  final String? folderId;
  final Function(WorkoutTemplate) onTemplateTap;
  final Function(WorkoutTemplate) onTemplateMorePressed;
  final Function(String, String?) onTemplateDroppedToFolder;
  final Function(int, int) onTemplateReordered;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const ReorderableWorkoutTemplateList({
    super.key,
    required this.templates,
    required this.folderId,
    required this.onTemplateTap,
    required this.onTemplateMorePressed,
    required this.onTemplateDroppedToFolder,
    required this.onTemplateReordered,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
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
        _ReorderableWorkoutTemplateListView(
          templates: templates,
          folderId: folderId,
          onTemplateTap: onTemplateTap,
          onTemplateMorePressed: onTemplateMorePressed,
          onTemplateDroppedToFolder: onTemplateDroppedToFolder,
          onTemplateReordered: onTemplateReordered,
          onDragStarted: onDragStarted,
          onDragEnded: onDragEnded,
        ),
      ],
    );
  }
}

class _ReorderableWorkoutTemplateListView extends StatefulWidget {
  final List<WorkoutTemplate> templates;
  final String? folderId;
  final Function(WorkoutTemplate) onTemplateTap;
  final Function(WorkoutTemplate) onTemplateMorePressed;
  final Function(String, String?) onTemplateDroppedToFolder;
  final Function(int, int) onTemplateReordered;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const _ReorderableWorkoutTemplateListView({
    required this.templates,
    required this.folderId,
    required this.onTemplateTap,
    required this.onTemplateMorePressed,
    required this.onTemplateDroppedToFolder,
    required this.onTemplateReordered,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  State<_ReorderableWorkoutTemplateListView> createState() => _ReorderableWorkoutTemplateListViewState();
}

class _ReorderableWorkoutTemplateListViewState extends State<_ReorderableWorkoutTemplateListView> {
  int? _draggedIndex;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < widget.templates.length; index++) ...[
          // Drop zone above each template (except the first one)
          if (index > 0)
            _buildDropZone(index),
          
          // The template card with drag target wrapper
          _buildTemplateWithDropTarget(index),
        ],
        
        // Drop zone at the end
        _buildDropZone(widget.templates.length),
      ],
    );
  }

  Widget _buildDropZone(int targetIndex) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] != 'template') return false;
        
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
        
        widget.onTemplateReordered(draggedIndex, newIndex);
        
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

  Widget _buildTemplateWithDropTarget(int index) {
    final template = widget.templates[index];
    final isDragged = _draggedIndex == index;
    
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] != 'template') return false;
        
        final draggedIndex = data['index'] as int;
        setState(() {
          _draggedIndex = draggedIndex;
        });
        return false; // We handle reordering in the drop zones, not on the cards themselves
      },
      onLeave: (data) {
        setState(() {
          _draggedIndex = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDragged ? 0.5 : 1.0,
          child: ExpandableWorkoutCard(
            template: template,
            index: index,
            onEditPressed: () => widget.onTemplateTap(template),
            onMorePressed: () => widget.onTemplateMorePressed(template),
            onDragStartedCallback: widget.onDragStarted,
            onDragEndCallback: widget.onDragEnded,
          ),
        );
      },
    );
  }
}
