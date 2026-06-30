import 'dart:developer' as developer; // Add debug logging

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../models/workout_template.dart';
import '../theme/app_theme.dart';
import 'expandable_workout_card.dart';
import 'workout_builder_drag_payload.dart';
import 'workout_builder_empty_state.dart';

// policy: no-test-needed drag integration is covered by higher-level workout drag list tests.
class ReorderableWorkoutTemplateList extends StatefulWidget {
  final List<WorkoutTemplate> templates;
  final String? folderId;
  final Function(WorkoutTemplate) onTemplateTap;
  final Function(WorkoutTemplate) onTemplateDeletePressed;
  final Function(int, int) onTemplateReordered;
  final VoidCallback? onAddWorkoutPressed;
  final VoidCallback? onStartFreeWorkoutPressed;
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
    this.onStartFreeWorkoutPressed,
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
  static const double _headerActionButtonWidth = 176;
  static const double _headerActionSpacing = 2;
  static const double _headerActionPeekWidth = 64;
  static const double _headerActionLeadingInset = 36;
  static const double _headerActionEdgeFadeWidth = 72;
  static const double _headerActionLeftEdgeFadeWidth = 120;
  static const double _headerActionEdgeFadeMidOpacity = 0.46;
  static const double _headerActionEdgeFadeEndOpacity = 0.8;

  int? _dropIndex;
  int? _draggedIndex;
  Offset? _lastDragGlobalPosition;
  Rect? _draggedOriginRectAtStart;
  double? _dragStartScrollPixels;
  late final ScrollController _headerActionScrollController;
  int _headerActionPage = 0;
  bool _showHeaderActionLeftFade = false;
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _headerActionScrollController = ScrollController()
      ..addListener(_handleHeaderActionScroll);
  }

  @override
  void dispose() {
    _headerActionScrollController
      ..removeListener(_handleHeaderActionScroll)
      ..dispose();
    super.dispose();
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
            final actionRail = _buildHeaderActionRail();
            final actionRailWidth = constraints.maxWidth < 360
                ? _headerActionButtonWidth + _headerActionPeekWidth - 10
                : _headerActionButtonWidth + _headerActionPeekWidth;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.folderId != null
                              ? 'WORKOUTS IN FOLDER'
                              : 'WORKOUTS',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w800,
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
                if (actionRail != null) ...[
                  const SizedBox(width: 12),
                  SizedBox(width: actionRailWidth, child: actionRail),
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

  Widget? _buildHeaderActionRail() {
    final actions = <_HeaderActionSpec>[];

    if (widget.onAddWorkoutPressed != null) {
      actions.add(
        _HeaderActionSpec(
          key: const Key('add_workout_button'),
          label: 'Add workout',
          icon: Icons.playlist_add_rounded,
          onPressed: widget.onAddWorkoutPressed!,
        ),
      );
    }

    if (widget.onStartFreeWorkoutPressed != null) {
      actions.add(
        _HeaderActionSpec(
          key: const Key('start_free_workout_button'),
          label: 'Start free',
          icon: Icons.play_arrow_rounded,
          onPressed: widget.onStartFreeWorkoutPressed!,
        ),
      );
    }

    if (actions.isEmpty) {
      return null;
    }

    return SizedBox(
      height: actions.length > 1 ? 54 : 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SingleChildScrollView(
            controller: _headerActionScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                if (actions.length > 1)
                  const SizedBox(width: _headerActionLeadingInset),
                ...List.generate(actions.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    return const SizedBox(width: _headerActionSpacing);
                  }
                  return _HeaderActionButton(spec: actions[index ~/ 2]);
                }),
              ],
            ),
          ),
          if (actions.length > 1)
            Positioned(
              top: 0,
              left: 0,
              bottom: 12,
              width: _headerActionLeftEdgeFadeWidth,
              child: AnimatedOpacity(
                key: const Key('header_action_left_edge_fade'),
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                opacity: _showHeaderActionLeftFade ? 1 : 0,
                child: const _HeaderActionEdgeFade(fadeFromLeftEdge: true),
              ),
            ),
          if (actions.length > 1)
            const Positioned(
              key: Key('header_action_edge_fade'),
              top: 0,
              right: 0,
              bottom: 12,
              width: _headerActionEdgeFadeWidth,
              child: _HeaderActionEdgeFade(),
            ),
          if (actions.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _HeaderActionDots(
                key: const Key('header_action_scroll_indicator'),
                currentPage: _headerActionPage,
                pageCount: actions.length,
              ),
            ),
        ],
      ),
    );
  }

  void _handleHeaderActionScroll() {
    if (!_headerActionScrollController.hasClients) {
      return;
    }

    final maxScrollExtent =
        _headerActionScrollController.position.maxScrollExtent;
    final nextPage = maxScrollExtent <= 0
        ? 0
        : _headerActionScrollController.offset >= maxScrollExtent / 2
        ? 1
        : 0;
    final showLeftFade = _headerActionScrollController.offset > 1;

    if ((nextPage == _headerActionPage &&
            showLeftFade == _showHeaderActionLeftFade) ||
        !mounted) {
      return;
    }

    setState(() {
      _headerActionPage = nextPage;
      _showHeaderActionLeftFade = showLeftFade;
    });
  }

  @override
  void didUpdateWidget(covariant ReorderableWorkoutTemplateList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final actionCount =
        (widget.onAddWorkoutPressed != null ? 1 : 0) +
        (widget.onStartFreeWorkoutPressed != null ? 1 : 0);
    if (actionCount <= 1 &&
        (_headerActionPage != 0 || _showHeaderActionLeftFade)) {
      _headerActionPage = 0;
      _showHeaderActionLeftFade = false;
    }
  }

  Widget _buildReorderableItem(int index) {
    final template = widget.templates[index];
    final itemKey = _itemKeyFor(template.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final card = _buildTemplateCard(template, index);
        final payload = _buildTemplatePayload(template, index);
        final draggable = _buildTemplateDraggable(
          context: context,
          constraints: constraints,
          template: template,
          index: index,
          card: card,
          payload: payload,
        );

        return _buildTemplateDragTarget(
          context: context,
          index: index,
          payload: payload,
          draggable: draggable,
          itemKey: itemKey,
        );
      },
    );
  }

  ExpandableWorkoutCard _buildTemplateCard(
    WorkoutTemplate template,
    int index,
  ) {
    return ExpandableWorkoutCard(
      key: ValueKey(template.id),
      template: template,
      index: index,
      onEditPressed: () => widget.onTemplateTap(template),
      onDeletePressed: () => widget.onTemplateDeletePressed(template),
    );
  }

  TemplateDragPayload _buildTemplatePayload(
    WorkoutTemplate template,
    int index,
  ) {
    return TemplateDragPayload(
      templateId: template.id,
      index: index,
      parentFolderId: widget.folderId,
    );
  }

  Widget _buildTemplateDraggable({
    required BuildContext context,
    required BoxConstraints constraints,
    required WorkoutTemplate template,
    required int index,
    required ExpandableWorkoutCard card,
    required TemplateDragPayload payload,
  }) {
    return LongPressDraggable<WorkoutBuilderDragPayload>(
      data: payload,
      delay: const Duration(milliseconds: 300),
      onDragStarted: () {
        developer.log(
          'Drag started for template: ${template.id} at index: $index',
        );
        HapticFeedback.mediumImpact();
        _draggedIndex = index;
        _draggedOriginRectAtStart = _rectForTemplate(template.id);
        _dragStartScrollPixels = Scrollable.maybeOf(context)?.position.pixels;
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
  }

  Widget _buildTemplateDragTarget({
    required BuildContext context,
    required int index,
    required TemplateDragPayload payload,
    required Widget draggable,
    required GlobalKey itemKey,
  }) {
    return DragTarget<WorkoutBuilderDragPayload>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data is! TemplateDragPayload) return false;
        if (data.parentFolderId != widget.folderId) return false;
        developer.log(
          'Drag target will accept template at index: $index, draggedIndex: ${data.index}',
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
            _buildAnimatedGapPlaceholder(context, visible: showGap),
            KeyedSubtree(key: itemKey, child: draggable),
          ],
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

class _HeaderActionSpec {
  final Key key;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderActionSpec({
    required this.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class _HeaderActionButton extends StatelessWidget {
  final _HeaderActionSpec spec;

  const _HeaderActionButton({required this.spec});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ReorderableWorkoutTemplateListState._headerActionButtonWidth,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: spec.key,
          onPressed: spec.onPressed,
          icon: Icon(spec.icon, size: 18),
          label: Text(spec.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(
              _ReorderableWorkoutTemplateListState._headerActionButtonWidth,
              0,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderActionDots extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _HeaderActionDots({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: isActive ? 16 : 6,
          height: 6,
          margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
          decoration: BoxDecoration(
            color: isActive
                ? colors.textSecondary.withValues(alpha: 0.72)
                : colors.textTertiary.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(999),
            border: isActive
                ? null
                : Border.all(
                    color: colors.textTertiary.withValues(alpha: 0.18),
                  ),
          ),
        );
      }),
    );
  }
}

class _HeaderActionEdgeFade extends StatelessWidget {
  const _HeaderActionEdgeFade({this.fadeFromLeftEdge = false});

  final bool fadeFromLeftEdge;

  @override
  Widget build(BuildContext context) {
    final fadeColor = Theme.of(context).scaffoldBackgroundColor;

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: fadeFromLeftEdge
                ? Alignment.centerRight
                : Alignment.centerLeft,
            end: fadeFromLeftEdge
                ? Alignment.centerLeft
                : Alignment.centerRight,
            stops: const [0, AppTheme.mainDockEdgeFadeMidStop, 1],
            colors: [
              fadeColor.withValues(alpha: 0),
              fadeColor.withValues(
                alpha: _ReorderableWorkoutTemplateListState
                    ._headerActionEdgeFadeMidOpacity,
              ),
              fadeColor.withValues(
                alpha: _ReorderableWorkoutTemplateListState
                    ._headerActionEdgeFadeEndOpacity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
