import 'dart:developer' as developer; // Add debug logging

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../models/workout_template.dart';
import '../theme/app_theme.dart';
import 'expandable_workout_card.dart';
import 'workout_builder_drag_payload.dart';

class ReorderableWorkoutTemplateList extends StatefulWidget {
  final List<WorkoutTemplate> templates;
  final String? folderId;
  final Function(WorkoutTemplate) onTemplateTap;
  final Function(WorkoutTemplate) onTemplateDeletePressed;
  final Function(int, int) onTemplateReordered;
  final VoidCallback? onAddWorkoutPressed;
  final ValueChanged<WorkoutBuilderDragPayload>? onDragStarted;
  final VoidCallback? onDragEnded;

  const ReorderableWorkoutTemplateList({
    super.key,
    required this.templates,
    required this.folderId,
    required this.onTemplateTap,
    required this.onTemplateDeletePressed,
    required this.onTemplateReordered,
    this.onAddWorkoutPressed,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  State<ReorderableWorkoutTemplateList> createState() =>
      _ReorderableWorkoutTemplateListState();
}

class _ReorderableWorkoutTemplateListState
    extends State<ReorderableWorkoutTemplateList> {
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
    final colors = context.appColors;
    final textTheme = context.appText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final addWorkoutButton = widget.onAddWorkoutPressed == null
                ? null
                : TextButton.icon(
                    onPressed: widget.onAddWorkoutPressed,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('Add workout'),
                  );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.folderId != null
                              ? 'Workouts in folder'
                              : 'Workouts',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceAlt,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${widget.templates.length}',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (addWorkoutButton != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: addWorkoutButton,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppConstants.SECTION_VERTICAL_GAP),
        if (widget.templates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: AppTheme.workoutCardBorderRadius,
            ),
            child: Text(
              widget.folderId != null
                  ? 'No workouts in this folder yet. Use Add workout to create one here.'
                  : 'No workouts created yet. Use Add workout to create your first one.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          )
        else ...[
          ...List.generate(widget.templates.length, (index) {
            return _buildReorderableItem(index);
          }),
          _buildDropZone(widget.templates.length),
        ],
      ],
    );
  }

  Widget _buildReorderableItem(int index) {
    final template = widget.templates[index];
    final itemKey = _itemKeyFor(template.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final card = ExpandableWorkoutCard(
          key: ValueKey(template.id),
          template: template,
          index: index,
          onEditPressed: () => widget.onTemplateTap(template),
          onDeletePressed: () => widget.onTemplateDeletePressed(template),
        );

        final payload = TemplateDragPayload(
          templateId: template.id,
          index: index,
          parentFolderId: widget.folderId,
        );

        final draggable = LongPressDraggable<WorkoutBuilderDragPayload>(
          data: payload,
          delay: const Duration(milliseconds: 300),
          onDragStarted: () {
            developer.log(
              'Drag started for template: ${template.id} at index: $index',
            );
            HapticFeedback.mediumImpact();
            _draggedIndex = index;
            _draggedOriginRectAtStart = _rectForTemplate(template.id);
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
              'Drag ended for template: ${template.id} at index: $index',
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
              'Drag canceled for template: ${template.id} at index: $index',
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

        return DragTarget<WorkoutBuilderDragPayload>(
          onWillAcceptWithDetails: (details) {
            final data = details.data;
            if (data is! TemplateDragPayload) return false;
            if (data.parentFolderId != widget.folderId) return false;
            final draggedIndex = data.index;
            developer.log(
              'Drag target will accept template at index: $index, draggedIndex: $draggedIndex',
            );
            return true;
          },
          onLeave: (data) {
            developer.log('Drag target leave at index: $index');
            _updateDropIndexFromPointer();
          },
          onAcceptWithDetails: (details) {
            final data = details.data;
            if (data is! TemplateDragPayload) {
              return;
            }
            developer.log(
              'Drag target accept template at index: $index for draggedIndex: ${data.index}',
            );
            _reorderUsingDropIndex(data.index);
            _setDropIndex(null);
          },
          builder: (context, candidateData, rejectedData) {
            final showGap = _dropIndex == index && _draggedIndex != index;

            return Column(
              children: [
                AnimatedContainer(
                  duration: AppConstants.DRAG_ANIMATION_DURATION,
                  curve: AppConstants.DRAG_ANIMATION_CURVE,
                  height: showGap ? _reorderGapHeight : 0,
                  width: double.infinity,
                  margin: showGap
                      ? const EdgeInsets.only(
                          bottom: AppConstants.CARD_VERTICAL_GAP,
                        )
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: context.appScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                KeyedSubtree(key: itemKey, child: draggable),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDropZone(int targetIndex) {
    return DragTarget<WorkoutBuilderDragPayload>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data is! TemplateDragPayload) return false;
        if (data.parentFolderId != widget.folderId) return false;
        final draggedIndex = data.index;
        if (draggedIndex == targetIndex) {
          return false;
        }
        return true;
      },
      onLeave: (data) {
        _updateDropIndexFromPointer();
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data is! TemplateDragPayload) {
          return;
        }
        _reorderUsingDropIndex(data.index);
        _setDropIndex(null);
      },
      builder: (context, candidateData, rejectedData) {
        final showGap = _dropIndex == targetIndex;

        return AnimatedContainer(
          duration: AppConstants.DRAG_ANIMATION_DURATION,
          curve: AppConstants.DRAG_ANIMATION_CURVE,
          height: showGap ? _reorderGapHeight : AppConstants.CARD_VERTICAL_GAP,
          width: double.infinity,
          margin: showGap
              ? const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: showGap
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
    if (widget.templates.isEmpty || _lastDragGlobalPosition == null) {
      return false;
    }

    final centers = <double>[];
    for (final template in widget.templates) {
      final rect = _rectForTemplate(template.id);
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

    var targetIndex = _dropIndex!.clamp(0, widget.templates.length);

    while (targetIndex > 0) {
      final upperBoundary = _boundaryForDropIndex(centers, targetIndex - 1);
      if (pointerY < upperBoundary - _dropIndexHysteresis) {
        targetIndex--;
        continue;
      }
      break;
    }

    while (targetIndex < widget.templates.length) {
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

    widget.onTemplateReordered(draggedIndex, newIndex);
  }

  Rect? _rectForTemplate(String templateId) {
    final key = _itemKeys[templateId];
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

  GlobalKey _itemKeyFor(String templateId) {
    return _itemKeys.putIfAbsent(templateId, GlobalKey.new);
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
