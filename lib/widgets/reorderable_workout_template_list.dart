import 'dart:developer' as developer; // Add debug logging

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../models/workout_template.dart';
import '../theme/app_theme.dart';
import 'expandable_workout_card.dart';

class ReorderableWorkoutTemplateList extends StatefulWidget {
  final List<WorkoutTemplate> templates;
  final String? folderId;
  final Function(WorkoutTemplate) onTemplateTap;
  final Function(WorkoutTemplate) onTemplateDeletePressed;
  final Function(int, int) onTemplateReordered;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const ReorderableWorkoutTemplateList({
    super.key,
    required this.templates,
    required this.folderId,
    required this.onTemplateTap,
    required this.onTemplateDeletePressed,
    required this.onTemplateReordered,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  State<ReorderableWorkoutTemplateList> createState() =>
      _ReorderableWorkoutTemplateListState();
}

class _ReorderableWorkoutTemplateListState
    extends State<ReorderableWorkoutTemplateList> {
  int? _dropIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;

    if (widget.templates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.folderId != null)
          Text(
            'Workouts in folder',
            style: textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Text(
            'Workouts',
            style: textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: AppConstants.SECTION_VERTICAL_GAP),
        ...List.generate(widget.templates.length, (index) {
          return _buildReorderableItem(index);
        }),
        _buildDropZone(widget.templates.length), // Add drop zone at the end
      ],
    );
  }

  Widget _buildReorderableItem(int index) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    final template = widget.templates[index];

    final card = ExpandableWorkoutCard(
      key: ValueKey(template.id),
      template: template,
      index: index,
      onEditPressed: () => widget.onTemplateTap(template),
      onDeletePressed: () => widget.onTemplateDeletePressed(template),
    );

    final draggable = LongPressDraggable<Map<String, dynamic>>(
      data: {'templateId': template.id, 'index': index, 'type': 'template'},
      delay: const Duration(milliseconds: 300),
      onDragStarted: () {
        developer.log(
          'Drag started for template: ${template.id} at index: $index',
        );
        HapticFeedback.mediumImpact();
        widget.onDragStarted?.call();
      },
      onDragEnd: (details) {
        developer.log(
          'Drag ended for template: ${template.id} at index: $index',
        );
        setState(() {
          _dropIndex = null;
        });
        widget.onDragEnded?.call();
      },
      onDraggableCanceled: (velocity, offset) {
        developer.log(
          'Drag canceled for template: ${template.id} at index: $index',
        );
        setState(() {
          _dropIndex = null;
        });
      },
      feedback: SizedBox(
        width: MediaQuery.of(context).size.width - 32, // padding
        child: Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(16.0),
          child: Opacity(opacity: 0.8, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: card),
      child: card,
    );

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] != 'template') return false;
        final draggedIndex = data['index'] as int;
        if (draggedIndex == index) return false;
        developer.log(
          'Drag target will accept template at index: $index, draggedIndex: $draggedIndex',
        );
        setState(() {
          _dropIndex = index;
        });
        return true;
      },
      onLeave: (data) {
        developer.log('Drag target leave at index: $index');
        setState(() {
          _dropIndex = null;
        });
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final draggedIndex = data['index'] as int;
        int newIndex = index;
        if (draggedIndex < index) {
          newIndex--;
        }
        developer.log(
          'Drag target accept template: draggedIndex: $draggedIndex, newIndex: $newIndex',
        );
        widget.onTemplateReordered(draggedIndex, newIndex);
        setState(() {
          _dropIndex = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final showPlaceholder = isHovering && _dropIndex == index;

        return Column(
          children: [
            AnimatedContainer(
              duration: AppConstants.DRAG_ANIMATION_DURATION,
              curve: AppConstants.DRAG_ANIMATION_CURVE,
              height: showPlaceholder ? 80 : 0,
              width: double.infinity,
              margin: showPlaceholder
                  ? const EdgeInsets.only(
                      bottom: AppConstants.CARD_VERTICAL_GAP,
                    )
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
                border: Border.all(color: colorScheme.primary, width: 2),
              ),
              child: showPlaceholder
                  ? Center(
                      child: Text(
                        'Move here',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            draggable,
          ],
        );
      },
    );
  }

  Widget _buildDropZone(int targetIndex) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] != 'template') return false;
        final draggedIndex = data['index'] as int;
        if (draggedIndex == targetIndex || draggedIndex == targetIndex - 1) {
          return false;
        }
        setState(() {
          _dropIndex = targetIndex;
        });
        return true;
      },
      onLeave: (data) {
        setState(() {
          _dropIndex = null;
        });
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final draggedIndex = data['index'] as int;
        int newIndex = targetIndex;
        if (draggedIndex < targetIndex) {
          newIndex--;
        }
        widget.onTemplateReordered(draggedIndex, newIndex);
        setState(() {
          _dropIndex = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final showPlaceholder = isHovering && _dropIndex == targetIndex;

        return AnimatedContainer(
          duration: AppConstants.DRAG_ANIMATION_DURATION,
          curve: AppConstants.DRAG_ANIMATION_CURVE,
          height: showPlaceholder ? 80 : 0,
          width: double.infinity,
          margin: showPlaceholder
              ? const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
            border: Border.all(color: colorScheme.primary, width: 2),
          ),
          child: showPlaceholder
              ? Center(
                  child: Text(
                    'Move to end',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
