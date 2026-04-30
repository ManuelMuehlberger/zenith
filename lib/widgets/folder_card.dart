import 'dart:developer' as developer; // Add debug logging

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../constants/app_constants.dart';
import '../models/workout_folder.dart';
import '../services/workout_service.dart';
import '../theme/app_theme.dart';

class FolderCard extends StatelessWidget {
  final WorkoutFolder folder;
  final VoidCallback onTap;
  final VoidCallback onRenamePressed;
  final VoidCallback onDeletePressed;
  final Function(String) onWorkoutDropped;
  final int? itemCount;
  final bool isDragging;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onRenamePressed,
    required this.onDeletePressed,
    required this.onWorkoutDropped,
    this.itemCount,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final workoutCount =
        itemCount ??
        WorkoutService.instance.getWorkoutsInFolder(folder.id).length;

    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) async {
        final data = details.data;
        developer.log('FolderCard onAcceptWithDetails: $data');
        if (data['type'] == 'workout') {
          onWorkoutDropped(data['workoutId']);
        } else if (data['type'] == 'template') {
          onWorkoutDropped(data['templateId']);
        }
      },
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        developer.log('FolderCard onWillAcceptWithDetails: $data');
        return data['type'] == 'workout' || data['type'] == 'template';
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final showDropHint = isHovering || isDragging;

        return AnimatedContainer(
          duration: AppConstants.DRAG_ANIMATION_DURATION,
          curve: AppConstants.DRAG_ANIMATION_CURVE,
          transform: Matrix4.diagonal3Values(
            showDropHint ? 1.02 : 1.0,
            showDropHint ? 1.02 : 1.0,
            1.0,
          ),
          margin: const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
          decoration: BoxDecoration(
            color: showDropHint
                ? colorScheme.primary.withValues(alpha: 0.25)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: showDropHint
                  ? colorScheme.primary.withValues(alpha: 0.8)
                  : Theme.of(context).dividerColor,
              width: showDropHint ? 1.5 : AppConstants.CARD_STROKE_WIDTH,
            ),
            boxShadow: showDropHint
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.18),
                      blurRadius: 10.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: AppThemeColors.clear,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.0),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.CARD_PADDING),
                child: Row(
                  children: [
                    // Folder icon with rounded modern styling
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: showDropHint
                            ? colors.textPrimary.withValues(alpha: 0.2)
                            : colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          26,
                        ), // Fully rounded
                        border: Border.all(
                          color: showDropHint
                              ? colors.textPrimary.withValues(alpha: 0.3)
                              : colorScheme.primary.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: showDropHint
                            ? colors.textPrimary
                            : colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppConstants.ITEM_HORIZONTAL_GAP),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Workout count with modern pill styling
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: showDropHint
                                  ? colors.textPrimary.withValues(alpha: 0.15)
                                  : colors.textTertiary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fitness_center_outlined,
                                  size: 12,
                                  color: showDropHint
                                      ? colors.textPrimary.withValues(
                                          alpha: 0.8,
                                        )
                                      : colors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$workoutCount',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: showDropHint
                                        ? colors.textPrimary.withValues(
                                            alpha: 0.9,
                                          )
                                        : colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showDropHint)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.textPrimary.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.move_down_outlined,
                              color: colors.textPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Drop here',
                              style: textTheme.labelMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Menu button with consistent styling
                      PullDownButton(
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            onTap: onRenamePressed,
                            title: 'Rename Folder',
                            icon: CupertinoIcons.pencil,
                          ),
                          PullDownMenuItem(
                            onTap: onDeletePressed,
                            title: 'Delete Folder',
                            isDestructive: true,
                            icon: CupertinoIcons.delete,
                          ),
                        ],
                        buttonBuilder: (context, showMenu) => Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.textTertiary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CupertinoButton(
                            onPressed: showMenu,
                            padding: EdgeInsets.zero,
                            child: Icon(
                              CupertinoIcons.ellipsis,
                              color: colors.textSecondary,
                              size: 16,
                            ),
                          ),
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
}
