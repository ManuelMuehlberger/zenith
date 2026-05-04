import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../models/workout_folder.dart';
import '../theme/app_theme.dart';
import 'folder_card.dart';
import 'workout_builder_drag_payload.dart';

class ReorderableFolderList extends StatefulWidget {
  const ReorderableFolderList({
    super.key,
    required this.folders,
    required this.currentParentFolderId,
    required this.itemCountByFolder,
    required this.subfolderCountByFolder,
    required this.activeDragPayload,
    required this.onFolderTap,
    required this.onRenamePressed,
    required this.onDeletePressed,
    required this.onFolderReordered,
    required this.onPayloadDroppedIntoFolder,
    required this.canDropIntoFolder,
    this.onDragStarted,
    this.onDragEnded,
  });

  final List<WorkoutFolder> folders;
  final String? currentParentFolderId;
  final Map<String?, int> itemCountByFolder;
  final Map<String, int> subfolderCountByFolder;
  final WorkoutBuilderDragPayload? activeDragPayload;
  final ValueChanged<WorkoutFolder> onFolderTap;
  final ValueChanged<WorkoutFolder> onRenamePressed;
  final ValueChanged<WorkoutFolder> onDeletePressed;
  final void Function(int oldIndex, int newIndex) onFolderReordered;
  final void Function(WorkoutBuilderDragPayload payload, WorkoutFolder folder)
  onPayloadDroppedIntoFolder;
  final bool Function(WorkoutBuilderDragPayload payload, WorkoutFolder folder)
  canDropIntoFolder;
  final ValueChanged<WorkoutBuilderDragPayload>? onDragStarted;
  final VoidCallback? onDragEnded;

  @override
  State<ReorderableFolderList> createState() => _ReorderableFolderListState();
}

class _ReorderableFolderListState extends State<ReorderableFolderList> {
  static const double _reorderGapHeight = 18;
  static const double _dropIndexHysteresis = 16;
  static const double _autoScrollTriggerExtent = 96;
  static const double _autoScrollStep = 18;

  int? _dropIndex;
  int? _draggedIndex;
  Offset? _lastDragGlobalPosition;
  Rect? _draggedOriginRectAtStart;
  double? _dragStartScrollPixels;
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};

  @override
  Widget build(BuildContext context) {
    if (widget.folders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ...List.generate(widget.folders.length, _buildReorderableItem),
        _buildDropZone(widget.folders.length),
      ],
    );
  }

  Widget _buildReorderableItem(int index) {
    final folder = widget.folders[index];
    final itemKey = _itemKeyFor(folder.id);
    final card = FolderCard(
      key: ValueKey(folder.id),
      folder: folder,
      itemCount: widget.itemCountByFolder[folder.id] ?? 0,
      subfolderCount: widget.subfolderCountByFolder[folder.id] ?? 0,
      activeDragPayload: widget.activeDragPayload,
      canAcceptPayload: (payload) => widget.canDropIntoFolder(payload, folder),
      onPayloadDropped: (payload) =>
          widget.onPayloadDroppedIntoFolder(payload, folder),
      onTap: () => widget.onFolderTap(folder),
      onRenamePressed: () => widget.onRenamePressed(folder),
      onDeletePressed: () => widget.onDeletePressed(folder),
    );

    final payload = FolderDragPayload(
      folderId: folder.id,
      index: index,
      parentFolderId: widget.currentParentFolderId,
      depth: folder.depth,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final draggable = LongPressDraggable<WorkoutBuilderDragPayload>(
          data: payload,
          delay: const Duration(milliseconds: 300),
          onDragStarted: () {
            developer.log(
              'Drag started for folder: ${folder.id} at index: $index',
            );
            HapticFeedback.mediumImpact();
            _draggedIndex = index;
            _draggedOriginRectAtStart = _rectForFolder(folder.id);
            _dragStartScrollPixels = Scrollable.maybeOf(
              context,
            )?.position.pixels;
            _lastDragGlobalPosition = null;
            _setDropIndex(null);
            widget.onDragStarted?.call(payload);
          },
          onDragUpdate: (details) {
            _lastDragGlobalPosition = details.globalPosition;
            _maybeAutoScroll(details.globalPosition);
            _updateDropIndexFromPointer();
          },
          onDragEnd: (details) {
            developer.log(
              'Drag ended for folder: ${folder.id} at index: $index',
            );
            if (!details.wasAccepted) {
              _reorderUsingDropIndex(index);
            }
            _draggedIndex = null;
            _draggedOriginRectAtStart = null;
            _dragStartScrollPixels = null;
            _lastDragGlobalPosition = null;
            _setDropIndex(null);
            widget.onDragEnded?.call();
          },
          onDraggableCanceled: (velocity, offset) {
            developer.log(
              'Drag canceled for folder: ${folder.id} at index: $index',
            );
            _draggedIndex = null;
            _draggedOriginRectAtStart = null;
            _dragStartScrollPixels = null;
            _lastDragGlobalPosition = null;
            _setDropIndex(null);
          },
          feedback: SizedBox(
            width: constraints.maxWidth,
            child: Material(
              color: Colors.transparent,
              borderRadius: AppTheme.workoutCardBorderRadius,
              child: Opacity(opacity: 0.92, child: card),
            ),
          ),
          childWhenDragging: _dropIndex == index
              ? Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.CARD_VERTICAL_GAP,
                  ),
                  child: Container(
                    height: _reorderGapHeight,
                    decoration: BoxDecoration(
                      color: context.appScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          child: card,
        );

        return Column(
          children: [
            _buildReorderZone(index),
            KeyedSubtree(key: itemKey, child: draggable),
          ],
        );
      },
    );
  }

  Widget _buildReorderZone(int targetIndex) {
    return DragTarget<WorkoutBuilderDragPayload>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data is! FolderDragPayload) {
          return false;
        }
        if (data.parentFolderId != widget.currentParentFolderId) {
          return false;
        }
        return true;
      },
      onLeave: (data) {
        _updateDropIndexFromPointer();
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data is! FolderDragPayload) {
          return;
        }
        _reorderUsingDropIndex(data.index);
        _setDropIndex(null);
      },
      builder: (context, candidateData, rejectedData) {
        final showPlaceholder =
            _dropIndex == targetIndex && _draggedIndex != targetIndex;

        return AnimatedContainer(
          duration: AppConstants.DRAG_ANIMATION_DURATION,
          curve: AppConstants.DRAG_ANIMATION_CURVE,
          height: showPlaceholder ? _reorderGapHeight : 0,
          width: double.infinity,
          margin: showPlaceholder
              ? const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: context.appScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      },
    );
  }

  Widget _buildDropZone(int targetIndex) {
    return DragTarget<WorkoutBuilderDragPayload>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data is! FolderDragPayload) {
          return false;
        }
        if (data.parentFolderId != widget.currentParentFolderId) {
          return false;
        }
        if (data.index == targetIndex) {
          return false;
        }
        return true;
      },
      onLeave: (data) {
        _updateDropIndexFromPointer();
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data is! FolderDragPayload) {
          return;
        }
        _reorderUsingDropIndex(data.index);
        _setDropIndex(null);
      },
      builder: (context, candidateData, rejectedData) {
        final showPlaceholder = _dropIndex == targetIndex;

        return AnimatedContainer(
          duration: AppConstants.DRAG_ANIMATION_DURATION,
          curve: AppConstants.DRAG_ANIMATION_CURVE,
          height: showPlaceholder
              ? _reorderGapHeight
              : AppConstants.CARD_VERTICAL_GAP,
          width: double.infinity,
          margin: showPlaceholder
              ? const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: showPlaceholder
                ? context.appScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      },
    );
  }

  void _setDropIndex(int? value) {
    if (_dropIndex == value || !mounted) {
      return;
    }
    setState(() {
      _dropIndex = value;
    });
  }

  void _maybeAutoScroll(Offset globalPosition) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      return;
    }

    final renderObject = scrollable.context.findRenderObject();
    if (renderObject is! RenderBox) {
      return;
    }

    final localPosition = renderObject.globalToLocal(globalPosition);
    final position = scrollable.position;
    final topThreshold = _autoScrollTriggerExtent;
    final bottomThreshold = renderObject.size.height - _autoScrollTriggerExtent;

    if (localPosition.dy <= topThreshold) {
      final targetPixels = (position.pixels - _autoScrollStep).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      if ((targetPixels - position.pixels).abs() < 0.5) {
        return;
      }

      position.jumpTo(targetPixels);
      return;
    }

    if (localPosition.dy < bottomThreshold) {
      return;
    }

    final targetPixels = (position.pixels + _autoScrollStep).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((targetPixels - position.pixels).abs() < 0.5) {
      return;
    }

    position.jumpTo(targetPixels);
  }

  bool _updateDropIndexFromPointer() {
    if (widget.folders.isEmpty || _lastDragGlobalPosition == null) {
      return false;
    }

    final centers = <double>[];
    for (final folder in widget.folders) {
      final rect = _rectForFolder(folder.id);
      if (rect == null) {
        return false;
      }
      centers.add(rect.center.dy);
    }

    if (centers.isEmpty) {
      return false;
    }

    final pointerY = _lastDragGlobalPosition!.dy;

    if (_dropIndex == null) {
      _setDropIndex(_rawDropIndexForPointer(pointerY, centers));
      return true;
    }

    var targetIndex = _dropIndex!.clamp(0, widget.folders.length);

    while (targetIndex > 0) {
      final upperBoundary = _boundaryForDropIndex(centers, targetIndex - 1);
      if (pointerY < upperBoundary - _dropIndexHysteresis) {
        targetIndex--;
        continue;
      }
      break;
    }

    while (targetIndex < widget.folders.length) {
      final lowerBoundary = _boundaryForDropIndex(centers, targetIndex);
      if (pointerY > lowerBoundary + _dropIndexHysteresis) {
        targetIndex++;
        continue;
      }
      break;
    }

    final draggedIndex = _draggedIndex;
    final draggedOriginRect = _currentDraggedOriginRect();
    if (draggedIndex != null && draggedOriginRect != null) {
      final originalZoneTop = draggedOriginRect.top - _dropIndexHysteresis;
      final originalZoneBottom =
          draggedOriginRect.bottom + _dropIndexHysteresis;
      if (pointerY >= originalZoneTop && pointerY <= originalZoneBottom) {
        targetIndex = draggedIndex;
      }
    }

    _setDropIndex(targetIndex);
    return false;
  }

  int _rawDropIndexForPointer(double pointerY, List<double> centers) {
    for (var index = 0; index < centers.length; index++) {
      if (pointerY <= _boundaryForDropIndex(centers, index)) {
        return index;
      }
    }
    return centers.length;
  }

  double _boundaryForDropIndex(List<double> centers, int index) {
    if (index >= centers.length - 1) {
      return centers.last;
    }
    return (centers[index] + centers[index + 1]) / 2;
  }

  void _reorderUsingDropIndex(int draggedIndex) {
    final targetIndex = _dropIndex;
    if (targetIndex == null) {
      return;
    }

    if (targetIndex == draggedIndex || targetIndex == draggedIndex + 1) {
      return;
    }

    var newIndex = targetIndex;
    if (draggedIndex < targetIndex) {
      newIndex--;
    }

    if (newIndex == draggedIndex) {
      return;
    }

    widget.onFolderReordered(draggedIndex, newIndex);
  }

  Rect? _rectForFolder(String folderId) {
    final key = _itemKeys[folderId];
    final context = key?.currentContext;
    if (context == null) {
      return null;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }

    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  GlobalKey _itemKeyFor(String folderId) {
    return _itemKeys.putIfAbsent(folderId, GlobalKey.new);
  }

  Rect? _currentDraggedOriginRect() {
    final originRect = _draggedOriginRectAtStart;
    final dragStartScrollPixels = _dragStartScrollPixels;
    final currentScrollPixels = Scrollable.maybeOf(context)?.position.pixels;

    if (originRect == null ||
        dragStartScrollPixels == null ||
        currentScrollPixels == null) {
      return originRect;
    }

    final scrollDelta = currentScrollPixels - dragStartScrollPixels;
    return originRect.shift(Offset(0, -scrollDelta));
  }
}
