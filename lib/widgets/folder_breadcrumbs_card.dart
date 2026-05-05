import 'package:flutter/material.dart';

import '../models/workout_folder.dart';
import '../widgets/workout_builder_drag_payload.dart';

class FolderBreadcrumbsCard extends StatelessWidget {
  const FolderBreadcrumbsCard({
    super.key,
    required this.folder,
    required this.ancestors,
    required this.activeDragPayload,
    required this.onMovePayloadToParent,
    required this.canMovePayloadToParent,
    required this.onNavigateToFolder,
    required this.onDragEnded,
    required this.parentFolderName,
    required this.isDragging,
  });

  final WorkoutFolder folder;
  final List<WorkoutFolder> ancestors;
  final WorkoutBuilderDragPayload? activeDragPayload;
  final Future<void> Function(WorkoutBuilderDragPayload) onMovePayloadToParent;
  final bool Function(WorkoutBuilderDragPayload) canMovePayloadToParent;
  final void Function(String?) onNavigateToFolder;
  final VoidCallback onDragEnded;
  final String parentFolderName;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DragTarget<WorkoutBuilderDragPayload>(
      onAcceptWithDetails: (details) async {
        await onMovePayloadToParent(details.data);
        onDragEnded();
      },
      onWillAcceptWithDetails: (details) {
        return canMovePayloadToParent(details.data);
      },
      onLeave: (data) {},
      builder: (context, candidateData, rejectedData) {
        final isHoveringOverDropTarget = candidateData.isNotEmpty;
        final showAnimation = isDragging || isHoveringOverDropTarget;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.diagonal3Values(
            showAnimation ? 1.01 : 1.0,
            showAnimation ? 1.01 : 1.0,
            1.0,
          ),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: showAnimation
                ? colorScheme.primary.withValues(alpha: 0.12)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: showAnimation
                  ? colorScheme.primary.withValues(alpha: 0.28)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFolderPathLinks(context),
              if (showAnimation) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_left_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drop here for $parentFolderName',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFolderPathLinks(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildFolderPathLink(
          context,
          label: 'All Workouts',
          color: colorScheme.primary,
          onTap: () => onNavigateToFolder(null),
        ),
        for (final ancestor in ancestors) ...[
          Text(
            '/',
            style: textTheme.titleSmall?.copyWith(
              color: textTheme.bodySmall?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          _buildFolderPathLink(
            context,
            label: ancestor.name,
            color: colorScheme.primary,
            onTap: () => onNavigateToFolder(ancestor.id),
          ),
        ],
        Text(
          '/',
          style: textTheme.titleSmall?.copyWith(
            color: textTheme.bodySmall?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        _buildFolderPathLink(
          context,
          label: folder.name,
          color: textTheme.bodyLarge?.color ?? Colors.black,
          onTap: () {},
          isCurrent: true,
        ),
      ],
    );
  }

  Widget _buildFolderPathLink(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isCurrent = false,
  }) {
    return GestureDetector(
      onTap: isCurrent ? null : onTap,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
