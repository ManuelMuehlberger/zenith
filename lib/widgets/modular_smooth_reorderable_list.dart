import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;
import '../services/reorder_service.dart';

class ModularSmoothReorderableList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;
  final EdgeInsets? padding;
  final ScrollController? scrollController;

  const ModularSmoothReorderableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.padding,
    this.scrollController,
  });

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    // This decorator is applied by ReorderableListView when an item is visually lifted.
    // The ReorderService's 1-second delay will control custom animations on the card itself,
    // but this proxyDecorator applies to the lifted representation.
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 10, animValue)!;
        final double scale = lerpDouble(1, 1.03, animValue)!;
        
        return Transform.scale(
          scale: scale,
          child: Material(
            elevation: elevation,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12), 
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reorderService = ReorderService.instance;

    return ReorderableListView.builder(
      padding: padding,
      itemCount: itemCount,
      scrollController: scrollController,
      buildDefaultDragHandles: false,
      
      // This is called by ReorderableListView when ReorderableDragStartListener
      // (or default handle) successfully initiates a drag (after its internal ~500ms delay).
      onReorderStart: (int index) {
        reorderService.onDragStarted(index); // This starts our 1-second timer in the service
      },
      
      // Called when the item is dropped, regardless of whether it was reordered.
      onReorderEnd: (int index) {
         reorderService.onDragCancelled(); // Reset service state if drag ends without reorder
      },
      
      // Called when an item is dropped in a new position.
      onReorder: (int oldIndex, int newIndex) {
        onReorder(oldIndex, newIndex); // Actual data reordering
        reorderService.onReorderCompleted(); // Notify service that reorder is done
      },
      
      proxyDecorator: _proxyDecorator,
      
      itemBuilder: (BuildContext context, int index) {
        // Wrap the actual item (ModularReorderableExerciseCard) with ReorderableDragStartListener.
        // This listener handles the long-press gesture to initiate the drag with ReorderableListView.
        // The key for ReorderableListView items must be on this direct child (ReorderableDragStartListener).
        return ReorderableDragStartListener(
          key: ValueKey('reorderable_drag_listener_$index'), // Unique key for the listener
          index: index,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
