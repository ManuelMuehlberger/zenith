import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_exercise.dart';
import 'dart:async';

typedef OnReorder = void Function(int oldIndex, int newIndex);
typedef ExerciseCardBuilder = Widget Function(BuildContext context, int index, bool isDragging, int? draggingIndex);

class CustomReorderableExerciseList extends StatefulWidget {
  final List<WorkoutExercise> exercises;
  final OnReorder onReorder;
  final ExerciseCardBuilder itemBuilder;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final double itemExtent; 

  const CustomReorderableExerciseList({
    super.key,
    required this.exercises,
    required this.onReorder,
    required this.itemBuilder,
    this.padding,
    this.scrollController,
    this.itemExtent = 180.0,
  });

  @override
  State<CustomReorderableExerciseList> createState() => _CustomReorderableExerciseListState();
}

class _CustomReorderableExerciseListState extends State<CustomReorderableExerciseList> {
  int? _draggedActualIndex;
  int? _hoveredDropZoneIndex;

  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  double? _lastDragY;

  static const double _autoScrollEdgeThreshold = 70.0;
  static const double _autoScrollSpeed = 20.0;
  static const Duration _autoScrollTick = Duration(milliseconds: 16);

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _startAutoScroll(double globalY) {
    _lastDragY = globalY;
    if (_scrollController.hasClients) {
      _autoScrollTimer ??= Timer.periodic(_autoScrollTick, (_) => _autoScroll());
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _lastDragY = null;
  }

  void _autoScroll() {
    if (_lastDragY == null || !_scrollController.hasClients) return;
    
    final RenderBox? scrollBox = context.findRenderObject() as RenderBox?;
    if (scrollBox == null) return;

    final scrollOffset = scrollBox.localToGlobal(Offset.zero);
    final scrollAreaTop = scrollOffset.dy;
    final scrollAreaBottom = scrollAreaTop + scrollBox.size.height;

    double newScrollOffset = _scrollController.offset;
    bool scrolled = false;

    if (_lastDragY! < scrollAreaTop + _autoScrollEdgeThreshold) {
      newScrollOffset -= _autoScrollSpeed;
      scrolled = true;
    } else if (_lastDragY! > scrollAreaBottom - _autoScrollEdgeThreshold) {
      newScrollOffset += _autoScrollSpeed;
      scrolled = true;
    }

    if (scrolled) {
      newScrollOffset = newScrollOffset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      if (newScrollOffset != _scrollController.offset) {
        _scrollController.jumpTo(newScrollOffset);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        if (_draggedActualIndex != null) {
          _startAutoScroll(event.position.dy);
        }
      },
      onPointerUp: (_) => _stopAutoScroll(),
      onPointerCancel: (_) => _stopAutoScroll(),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: widget.padding,
        child: Column(
          children: [
            // Drop zone at the very top (index 0)
            _buildDropZone(context, 0), 
            for (int i = 0; i < widget.exercises.length; i++) ...[
              _buildDraggableItem(context, i),
              // Drop zone after each item (index i + 1)
              _buildDropZone(context, i + 1), 
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone(BuildContext context, int dropZoneIndex) {
    // dropZoneIndex: 0 means before the first item, 
    // 1 means after the first item (before the second), ..., exercises.length means after the last item.
    
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        final draggedItemActualIndex = details.data;
        if (draggedItemActualIndex == dropZoneIndex || draggedItemActualIndex == dropZoneIndex -1) {
          // Trying to drop item into its current position or the position immediately following it (which is the same logical move)
          return false;
        }
        setState(() {
          _hoveredDropZoneIndex = dropZoneIndex;
        });
        return true;
      },
      onLeave: (data) {
        if (_hoveredDropZoneIndex == dropZoneIndex) {
          setState(() {
            _hoveredDropZoneIndex = null;
          });
        }
      },
      onAcceptWithDetails: (details) {
        final draggedItemActualIndex = details.data; // This is the original index of the dragged item
        
        // Adjust target index for reordering logic:
        // If dropping at zone 0, new index is 0.
        // If dropping at zone 1 (after item 0), new index is 1.
        // ...
        // If dropping at zone `widget.exercises.length` (after last item), new index is `widget.exercises.length`.
        int newActualIndex = dropZoneIndex;

        widget.onReorder(draggedItemActualIndex, newActualIndex);
        HapticFeedback.mediumImpact();
        
        setState(() {
          _hoveredDropZoneIndex = null;
          // _draggedActualIndex is reset in Draggable's onDragEnd/onDraggableCanceled
        });
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = _hoveredDropZoneIndex == dropZoneIndex && candidateData.isNotEmpty;
        final bool isDraggingInProgress = _draggedActualIndex != null;

        if (!isDraggingInProgress && !isHovering) return const SizedBox.shrink(); // Only show if dragging or specifically hovered

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isHovering ? 60 : (isDraggingInProgress ? 12 : 0), // Smaller when not hovered but dragging
          margin: EdgeInsets.symmetric(
            vertical: isHovering ? 6.0 : (isDraggingInProgress ? 2.0 : 0),
            horizontal: (widget.padding?.horizontal ?? 32.0) / 2 // Use half of list padding
          ),
          decoration: BoxDecoration(
            color: isHovering ? Colors.blue.withAlpha((255 * 0.1).round()) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isHovering 
              ? Border.all(color: Colors.blue.withAlpha((255 * 0.3).round()), width: 1.5) 
              : (isDraggingInProgress ? Border.all(color: Colors.grey.withAlpha((255*0.15).round()), width: 1.0, style: BorderStyle.solid) : null),
          ),
          child: isHovering
              ? Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: Colors.blue.withAlpha(150), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Drop here',
                        style: TextStyle(
                          color: Colors.blue.withAlpha(200),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : (isDraggingInProgress ? SizedBox(
                  height: 10, 
                  child: Center(
                    child: Container(
                      width: 50, 
                      height: 2, 
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha((255*0.2).round()),
                        borderRadius: BorderRadius.circular(1)
                      ),
                    )
                  )
                ) : null),
        );
      },
    );
  }

  Widget _buildDraggableItem(BuildContext context, int itemActualIndex) {
    final bool isSelfDragging = _draggedActualIndex == itemActualIndex;
    
    // The item itself is not a DragTarget for reordering purposes,
    // reordering happens via the dedicated _buildDropZone widgets.
    // We can, however, change its appearance if something is dragged over it,
    // but the inspiration file doesn't do this for the cards themselves.

    return LongPressDraggable<int>(
      data: itemActualIndex, // The original index of this item
      axis: Axis.vertical,
      maxSimultaneousDrags: 1,
      feedback: Builder(
        builder: (context) {
          // Use a fixed width for feedback, or derive from screen/parent.
          // widget.itemExtent is for height, but can inform width if items are square-ish.
          final listWidth = MediaQuery.of(context).size.width - (widget.padding?.horizontal ?? 0);
          return Material(
            color: Colors.transparent,
            elevation: 6.0,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: listWidth, // Ensure feedback takes appropriate width
              height: widget.itemExtent * 0.7, // Reduced height to match visual consistency
              child: Opacity(
                opacity: 0.95,
                child: Transform.scale(
                  scale: 0.92,
                  alignment: Alignment.center,
                  child: widget.itemBuilder(context, itemActualIndex, true, _draggedActualIndex),
                ),
              ),
            ),
          );
        },
      ),
      childWhenDragging: const SizedBox.shrink(), // Completely hide the original item when dragging
      onDragStarted: () {
        HapticFeedback.lightImpact();
        setState(() {
          _draggedActualIndex = itemActualIndex;
        });
      },
      onDraggableCanceled: (_, __) {
        _stopAutoScroll();
        setState(() {
          _draggedActualIndex = null;
          _hoveredDropZoneIndex = null; 
        });
      },
      onDragEnd: (_) { // Called when drag ends, regardless of acceptance
        _stopAutoScroll();
        // If _draggedActualIndex is still set, it means it wasn't accepted or onDragCompleted wasn't called.
        // This state reset ensures cleanup.
        if (_draggedActualIndex != null) {
            setState(() {
                _draggedActualIndex = null;
                _hoveredDropZoneIndex = null;
            });
        }
      },
      onDragCompleted: () { // Called ONLY if accepted by a DragTarget
        _stopAutoScroll();
        // _draggedActualIndex and _hoveredDropZoneIndex are reset by onAcceptWithDetails in the DragTarget
        // and potentially by onDragEnd if it fires after.
        // To be safe, ensure they are cleared.
         setState(() {
            _draggedActualIndex = null;
            _hoveredDropZoneIndex = null;
        });
      },
      delay: const Duration(milliseconds: 300),
      child: AnimatedOpacity( // Apply opacity if this item is being dragged
        opacity: isSelfDragging ? 0.5 : (_draggedActualIndex != null ? 0.6 : 1.0), // Gray out other items when any item is being dragged
        duration: const Duration(milliseconds: 200),
        child: widget.itemBuilder(context, itemActualIndex, isSelfDragging, _draggedActualIndex),
      ),
    );
  }
}
