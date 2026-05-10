import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../models/workout_template.dart';
import '../theme/app_theme.dart';
import 'expandable_workout_card.dart';
import 'workout_builder_empty_state.dart';
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
  static const String _cardRepaintBoundaryKeyPrefix =
      'reorderable-template-card-repaint-';
  static const String _feedbackRepaintBoundaryKeyPrefix =
      'reorderable-template-feedback-repaint-';
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
  Map<String, Rect>? _cachedTemplateRects;
  bool _templateGeometryDirty = true;
  bool _templateGeometryRefreshScheduled = false;

  @override
  void didUpdateWidget(covariant ReorderableWorkoutTemplateList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final activeTemplateIds = widget.templates
        .map((template) => template.id)
        .toSet();
    _itemKeys.removeWhere(
      (templateId, _) => !activeTemplateIds.contains(templateId),
    );
    _cachedTemplateRects?.removeWhere(
      (templateId, _) => !activeTemplateIds.contains(templateId),
    );
    _markTemplateGeometryDirty(scheduleRefresh: false);
  }

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
          const WorkoutBuilderEmptyState(
            icon: Icons.fitness_center_rounded,
            title: 'No workouts yet',
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
        final card = _buildCard(template, index);

        final payload = TemplateDragPayload(
          templateId: template.id,
          index: index,
          parentFolderId: widget.folderId,
        );

        final draggable = LongPressDraggable<WorkoutBuilderDragPayload>(
          data: payload,
          delay: const Duration(milliseconds: 300),
          onDragStarted: () {
            HapticFeedback.mediumImpact();
            _draggedIndex = index;
            _draggedOriginRectAtStart = _rectForTemplate(template.id);
            _dragStartScrollPixels = Scrollable.maybeOf(
              context,
            )?.position.pixels;
            _lastDragGlobalPosition = null;
            _markTemplateGeometryDirty();
            _setDropIndex(null);
            widget.onDragStarted?.call(payload);
          },
          onDragUpdate: (details) {
            _lastDragGlobalPosition = details.globalPosition;
            _maybeAutoScroll(details.globalPosition);
            _updateDropIndexFromPointer();
          },
          onDragEnd: (details) {
            if (!details.wasAccepted) {
              _reorderUsingDropIndex(index);
            }
            _clearDragState();
            widget.onDragEnded?.call();
          },
          onDraggableCanceled: (velocity, offset) {
            _clearDragState();
          },
          feedback: SizedBox(
            width: constraints.maxWidth,
            child: RepaintBoundary(
              key: ValueKey('$_feedbackRepaintBoundaryKeyPrefix${template.id}'),
              child: Material(
                color: Colors.transparent,
                borderRadius: AppTheme.workoutCardBorderRadius,
                child: Opacity(
                  opacity: 0.92,
                  child: _buildCard(template, index),
                ),
              ),
            ),
          ),
          childWhenDragging: _buildAnimatedGapPlaceholder(
            context,
            visible: _dropIndex == index,
          ),
          child: card,
        );

        return DragTarget<WorkoutBuilderDragPayload>(
          onWillAcceptWithDetails: (details) {
            final data = details.data;
            if (data is! TemplateDragPayload) return false;
            if (data.parentFolderId != widget.folderId) return false;
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
            final showGap = _dropIndex == index && _draggedIndex != index;

            return Column(
              children: [
                _buildAnimatedGapPlaceholder(context, visible: showGap),
                KeyedSubtree(key: itemKey, child: draggable),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCard(WorkoutTemplate template, int index) {
    return RepaintBoundary(
      key: ValueKey('$_cardRepaintBoundaryKeyPrefix${template.id}'),
      child: ExpandableWorkoutCard(
        key: ValueKey(template.id),
        template: template,
        index: index,
        onEditPressed: () => widget.onTemplateTap(template),
        onDeletePressed: () => widget.onTemplateDeletePressed(template),
      ),
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

        return _buildAnimatedGapPlaceholder(
          context,
          visible: showGap,
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
    _markTemplateGeometryDirty();
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

      _markTemplateGeometryDirty(scheduleRefresh: false);
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

    _markTemplateGeometryDirty(scheduleRefresh: false);
    position.jumpTo(targetPixels);
  }

  bool _updateDropIndexFromPointer() {
    if (widget.templates.isEmpty || _lastDragGlobalPosition == null) {
      return false;
    }

    final centers = _templateCenters();
    if (centers.isEmpty) {
      return false;
    }

    final pointerY = _lastDragGlobalPosition!.dy;

    if (_dropIndex == null) {
      _setDropIndex(
        _normalizedReorderIndex(_rawDropIndexForPointer(pointerY, centers)),
      );
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

    _setDropIndex(_normalizedReorderIndex(targetIndex));
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

  void _clearDragState() {
    _draggedIndex = null;
    _draggedOriginRectAtStart = null;
    _dragStartScrollPixels = null;
    _lastDragGlobalPosition = null;
    _clearTemplateGeometryCache();
    _setDropIndex(null);
  }

  void _clearTemplateGeometryCache() {
    _cachedTemplateRects = null;
    _templateGeometryDirty = true;
    _templateGeometryRefreshScheduled = false;
  }

  void _markTemplateGeometryDirty({bool scheduleRefresh = true}) {
    _templateGeometryDirty = true;
    if (scheduleRefresh) {
      _scheduleTemplateGeometryRefresh();
    }
  }

  void _scheduleTemplateGeometryRefresh() {
    if (_templateGeometryRefreshScheduled ||
        !mounted ||
        _draggedIndex == null) {
      return;
    }

    _templateGeometryRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _templateGeometryRefreshScheduled = false;
      if (!mounted || _draggedIndex == null || !_templateGeometryDirty) {
        return;
      }
      _captureTemplateRects();
    });
  }

  Map<String, Rect>? _captureTemplateRects() {
    final templateRects = <String, Rect>{};
    for (final template in widget.templates) {
      final rect = _rectForTemplate(template.id);
      if (rect == null) {
        return null;
      }
      templateRects[template.id] = rect;
    }

    _cachedTemplateRects = templateRects;
    _templateGeometryDirty = false;
    return templateRects;
  }

  Map<String, Rect>? _ensureTemplateRects() {
    final cachedTemplateRects = _cachedTemplateRects;
    if (!_templateGeometryDirty &&
        cachedTemplateRects != null &&
        cachedTemplateRects.length == widget.templates.length) {
      return cachedTemplateRects;
    }

    return _captureTemplateRects();
  }

  List<double> _templateCenters() {
    final templateRects = _ensureTemplateRects();
    if (templateRects == null) {
      return const <double>[];
    }

    final centers = <double>[];
    for (final template in widget.templates) {
      final rect = templateRects[template.id];
      if (rect == null) {
        return const <double>[];
      }
      centers.add(rect.center.dy);
    }
    return centers;
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
