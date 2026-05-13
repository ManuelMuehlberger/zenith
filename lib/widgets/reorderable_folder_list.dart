import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../models/workout_folder.dart';
import '../theme/app_theme.dart';
import 'folder_card.dart';
import 'workout_builder_drag_payload.dart';

// policy: no-test-needed drag integration is covered at the higher workout drag list level.
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
  static const double _autoScrollTriggerExtent = 96;
  static const double _autoScrollStep = 18;
  static const double _nestedDropMargin = 14;

  int? _dropIndex;
  int? _draggedIndex;
  int? _activeNestedHoverIndex;
  FolderDragPayload? _draggedPayload;
  Offset? _lastDragGlobalPosition;
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
      isDropTargetActive: _activeNestedHoverIndex == index,
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
            _draggedPayload = payload;
            _lastDragGlobalPosition = null;
            _resetNestedHoverState();
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
            final nestedHoverIndex = _activeNestedHoverIndex;
            if (!details.wasAccepted && nestedHoverIndex != null) {
              widget.onPayloadDroppedIntoFolder(
                payload,
                widget.folders[nestedHoverIndex],
              );
            } else if (!details.wasAccepted) {
              _reorderUsingDropIndex(index);
            }
            _draggedIndex = null;
            _draggedPayload = null;
            _lastDragGlobalPosition = null;
            _resetNestedHoverState();
            _setDropIndex(null);
            widget.onDragEnded?.call();
          },
          onDraggableCanceled: (velocity, offset) {
            developer.log(
              'Drag canceled for folder: ${folder.id} at index: $index',
            );
            _draggedIndex = null;
            _draggedPayload = null;
            _lastDragGlobalPosition = null;
            _resetNestedHoverState();
            _setDropIndex(null);
          },
          feedback: SizedBox(
            width: constraints.maxWidth,
            child: Material(
              color: context.appScheme.surface.withValues(alpha: 0),
              borderRadius: AppTheme.workoutCardBorderRadius,
              child: Opacity(opacity: 0.92, child: card),
            ),
          ),
          childWhenDragging: _buildAnimatedGapPlaceholder(
            context,
            visible: _dropIndex == index,
          ),
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

        return _buildAnimatedGapPlaceholder(context, visible: showPlaceholder);
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

        return _buildAnimatedGapPlaceholder(
          context,
          visible: showPlaceholder,
          collapsedHeight: AppConstants.CARD_VERTICAL_GAP,
        );
      },
    );
  }

  Widget _buildAnimatedGapPlaceholder(
    BuildContext context, {
    required bool visible,
    double collapsedHeight = 0,
  }) {
    return AnimatedOpacity(
      duration: AppConstants.DRAG_ANIMATION_DURATION,
      curve: AppConstants.DRAG_ANIMATION_CURVE,
      opacity: visible ? 1 : 0,
      child: AnimatedContainer(
        duration: AppConstants.DRAG_ANIMATION_DURATION,
        curve: AppConstants.DRAG_ANIMATION_CURVE,
        height: visible ? _reorderGapHeight : collapsedHeight,
        width: double.infinity,
        margin: visible
            ? const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: context.appScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
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
    const topThreshold = _autoScrollTriggerExtent;
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

    final classification = _classifyPointer(_lastDragGlobalPosition!);
    if (classification == null) {
      if ((_activeNestedHoverIndex != null || _dropIndex != null) && mounted) {
        setState(() {
          _activeNestedHoverIndex = null;
          _dropIndex = null;
        });
      }
      return false;
    }

    if (classification.nestedFolderIndex != null) {
      final nestedIndex = classification.nestedFolderIndex;
      if (_activeNestedHoverIndex != nestedIndex && mounted) {
        setState(() {
          _activeNestedHoverIndex = nestedIndex;
          _dropIndex = null;
        });
      } else {
        _setDropIndex(null);
      }
      return true;
    }

    final reorderIndex = classification.reorderIndex;
    final effectiveDropIndex = _normalizedReorderIndex(reorderIndex);

    if ((_activeNestedHoverIndex != null || _dropIndex != effectiveDropIndex) &&
        mounted) {
      setState(() {
        _activeNestedHoverIndex = null;
        _dropIndex = effectiveDropIndex;
      });
    }
    return false;
  }

  void _resetNestedHoverState() {
    _activeNestedHoverIndex = null;
  }

  _FolderDragClassification? _classifyPointer(Offset globalPosition) {
    final payload = _draggedPayload;
    if (payload == null) {
      return null;
    }

    final contentRects = <Rect>[];
    for (final folder in widget.folders) {
      final rect = _contentRectForFolder(folder.id);
      if (rect == null) {
        return null;
      }
      contentRects.add(rect);
    }

    if (contentRects.isEmpty) {
      return null;
    }

    for (var index = 0; index < contentRects.length; index++) {
      if (index == _draggedIndex) {
        continue;
      }

      final folder = widget.folders[index];
      final nestedRect = _nestedRectForContent(contentRects[index]);
      if (!nestedRect.contains(globalPosition)) {
        continue;
      }

      if (!widget.canDropIntoFolder(payload, folder)) {
        break;
      }

      return _FolderDragClassification(nestedFolderIndex: index);
    }

    final firstRect = contentRects.first;
    if (globalPosition.dy < firstRect.top) {
      return const _FolderDragClassification(reorderIndex: 0);
    }

    for (var index = 0; index < contentRects.length; index++) {
      final rect = contentRects[index];
      if (globalPosition.dy < rect.top) {
        return _FolderDragClassification(reorderIndex: index);
      }

      if (rect.contains(globalPosition)) {
        final nestedRect = _nestedRectForContent(rect);
        if (globalPosition.dy < nestedRect.top) {
          return _FolderDragClassification(reorderIndex: index);
        }
        if (globalPosition.dy > nestedRect.bottom) {
          return _FolderDragClassification(reorderIndex: index + 1);
        }
      }
    }

    return _FolderDragClassification(reorderIndex: contentRects.length);
  }

  Rect? _contentRectForFolder(String folderId) {
    final rect = _rectForFolder(folderId);
    if (rect == null) {
      return null;
    }

    return Rect.fromLTRB(
      rect.left,
      rect.top,
      rect.right,
      rect.bottom - AppConstants.CARD_VERTICAL_GAP,
    );
  }

  Rect _nestedRectForContent(Rect contentRect) {
    final inset = _nestedDropMargin.clamp(0, contentRect.height / 2);
    return Rect.fromLTRB(
      contentRect.left,
      contentRect.top + inset,
      contentRect.right,
      contentRect.bottom - inset,
    );
  }

  int? _normalizedReorderIndex(int? reorderIndex) {
    final draggedIndex = _draggedIndex;
    if (reorderIndex == null || draggedIndex == null) {
      return reorderIndex;
    }

    if (reorderIndex == draggedIndex || reorderIndex == draggedIndex + 1) {
      return draggedIndex;
    }

    return reorderIndex;
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
}

class _FolderDragClassification {
  const _FolderDragClassification({this.nestedFolderIndex, this.reorderIndex})
    : assert(
        (nestedFolderIndex == null) != (reorderIndex == null),
        'Provide exactly one drag classification.',
      );

  final int? nestedFolderIndex;
  final int? reorderIndex;
}
