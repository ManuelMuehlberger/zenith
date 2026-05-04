import 'dart:developer' as developer; // Add debug logging

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
        developer.log('FolderCard onAcceptWithDetails: ${details.data}');
        onPayloadDropped(details.data);
      },
      onWillAcceptWithDetails: (details) {
        developer.log('FolderCard onWillAcceptWithDetails: ${details.data}');
        final validator = canAcceptPayload;
        return validator == null ? true : validator(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final hoveringPayload = candidateData.isEmpty
            ? null
            : candidateData.first;
        final activePayload = hoveringPayload ?? activeDragPayload;
        final acceptsActivePayload =
            activePayload != null &&
            (canAcceptPayload == null || canAcceptPayload!(activePayload));
        final showDropHint = isHovering || acceptsActivePayload;
        final highlightTint = colorScheme.primary.withValues(
          alpha: isDark ? 0.18 : 0.06,
        );
        final surfaceColor = showDropHint
            ? Color.alphaBlend(highlightTint, colors.surfaceAlt)
            : colors.surfaceAlt;
        final iconTint = colorScheme.primary;
        final dropMeta = switch (activePayload) {
          FolderDragPayload() => 'Release to nest folder',
          TemplateDragPayload() => 'Release to move workout',
          _ => '$workoutCount workouts',
        };

        return AnimatedContainer(
          duration: AppConstants.DRAG_ANIMATION_DURATION,
          curve: AppConstants.DRAG_ANIMATION_CURVE,
          margin: const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: AppTheme.workoutCardBorderRadius,
            border: Border.all(
              color: showDropHint
                  ? colorScheme.primary.withValues(alpha: isDark ? 0.5 : 0.28)
                  : Colors.transparent,
            ),
          ),
          child: Material(
            color: transparentSurface,
            child: InkWell(
              borderRadius: AppTheme.workoutCardBorderRadius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: iconTint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: iconTint,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Folder',
                            style: textTheme.labelMedium?.copyWith(
                              color: showDropHint
                                  ? colorScheme.primary
                                  : colors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            folder.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
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
                    if (showDropHint)
                      const SizedBox.shrink()
                    else
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
    final textStyle = context.appText.labelMedium?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w600,
    );

    Widget stat(IconData icon, int value) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textSecondary),
          const SizedBox(width: 6),
          Text('$value', style: textStyle),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        stat(Icons.fitness_center_rounded, workoutCount),
        const SizedBox(width: 14),
        stat(Icons.folder_copy_rounded, subfolderCount),
      ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: badgeTint),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.appText.labelMedium?.copyWith(
            color: badgeTint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    final colorScheme = context.appScheme;
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
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
