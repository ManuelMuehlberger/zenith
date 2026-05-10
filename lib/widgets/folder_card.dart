import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../constants/app_constants.dart';
import '../models/workout_folder.dart';
import '../services/workout_service.dart';
import '../theme/app_theme.dart';
import 'workout_builder_drag_payload.dart';
import 'workouts_page_menu_theme.dart';

class FolderCard extends StatelessWidget {
  final WorkoutFolder folder;
  final VoidCallback onTap;
  final VoidCallback onRenamePressed;
  final VoidCallback onDeletePressed;
  final ValueChanged<WorkoutBuilderDragPayload> onPayloadDropped;
  final bool Function(WorkoutBuilderDragPayload payload)? canAcceptPayload;
  final WorkoutBuilderDragPayload? activeDragPayload;
  final bool isDropTargetActive;
  final int? itemCount;
  final int? subfolderCount;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onRenamePressed,
    required this.onDeletePressed,
    required this.onPayloadDropped,
    this.canAcceptPayload,
    this.activeDragPayload,
    this.isDropTargetActive = false,
    this.itemCount,
    this.subfolderCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final transparentSurface = colorScheme.surface.withValues(alpha: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workoutCount =
        itemCount ??
        WorkoutService.instance.getWorkoutsInFolder(folder.id).length;
    final nestedFolderCount = subfolderCount ?? 0;

    return DragTarget<WorkoutBuilderDragPayload>(
      onAcceptWithDetails: (details) async {
        onPayloadDropped(details.data);
      },
      onWillAcceptWithDetails: (details) {
        if (details.data is TemplateDragPayload) {
          final validator = canAcceptPayload;
          return validator == null ? true : validator(details.data);
        }
        if (!isDropTargetActive) {
          return false;
        }
        final validator = canAcceptPayload;
        return validator == null ? true : validator(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final hoveringPayload = candidateData.isEmpty
            ? null
            : candidateData.first;
        final activePayload = hoveringPayload ?? activeDragPayload;
        final showDropHint = isHovering || isDropTargetActive;
        final iconTint = colorScheme.primary;
        final restingSurfaceColor = isDark
            ? colorScheme.surface
            : Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.025),
                colors.surfaceAlt,
              );
        final restingIconSurfaceColor = Color.alphaBlend(
          iconTint.withValues(alpha: isDark ? 0.1 : 0.06),
          colors.surfaceAlt,
        );
        final borderColor = showDropHint
            ? colorScheme.primary.withValues(alpha: isDark ? 0.5 : 0.28)
            : colors.textTertiary.withValues(alpha: isDark ? 0.16 : 0.08);
        final dropMeta = switch (activePayload) {
          FolderDragPayload() => 'Drop here to nest folder',
          TemplateDragPayload() => 'Drop here to move template',
          _ when isDropTargetActive => 'Drop here to nest folder',
          _ => '$workoutCount templates',
        };

        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
          decoration: BoxDecoration(
            color: restingSurfaceColor,
            borderRadius: AppTheme.workoutCardBorderRadius,
            border: Border.all(color: borderColor),
          ),
          child: Material(
            color: transparentSurface,
            child: InkWell(
              borderRadius: AppTheme.workoutCardBorderRadius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: restingIconSurfaceColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: iconTint,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            folder.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          if (showDropHint)
                            _buildMetaLine(
                              context,
                              icon: Icons.subdirectory_arrow_right_rounded,
                              label: dropMeta,
                              tint: colorScheme.primary,
                            )
                          else
                            _buildCountsLine(
                              context,
                              workoutCount: workoutCount,
                              subfolderCount: nestedFolderCount,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    buildWorkoutsPageMenuWrapper(
                      context,
                      child: PullDownButton(
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            onTap: onRenamePressed,
                            title: 'Rename Folder',
                            icon: Icons.edit_outlined,
                          ),
                          PullDownMenuItem(
                            onTap: onDeletePressed,
                            title: 'Delete Folder',
                            isDestructive: true,
                            icon: Icons.delete_outline_rounded,
                          ),
                        ],
                        buttonBuilder: (context, showMenu) =>
                            _buildMenuButton(context, onPressed: showMenu),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountsLine(
    BuildContext context, {
    required int workoutCount,
    required int subfolderCount,
  }) {
    final colors = context.appColors;
    final textTheme = context.appText;

    final workoutLabel = workoutCount == 1 ? 'template' : 'templates';
    final folderLabel = subfolderCount == 1 ? 'folder' : 'folders';

    return Text(
      '$workoutCount $workoutLabel, $subfolderCount $folderLabel',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.labelMedium?.copyWith(
        color: colors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildMetaLine(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? tint,
  }) {
    final colors = context.appColors;
    final badgeTint = tint ?? colors.textSecondary;

    return Row(
      children: [
        Icon(icon, size: 14, color: badgeTint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.appText.labelMedium?.copyWith(
              color: badgeTint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;
    final colorScheme = context.appScheme;
    final shellColor = isDark
        ? colors.surfaceAlt
        : Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.04),
            colors.surfaceAlt,
          );
    final shellBorderColor = isDark
        ? Colors.transparent
        : colors.textTertiary.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: shellColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: shellBorderColor),
          ),
          child: Center(
            child: Icon(
              Icons.more_horiz_rounded,
              color: colors.textSecondary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
