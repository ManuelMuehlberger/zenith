import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer; // Add debug logging
import 'package:pull_down_button/pull_down_button.dart';
import '../models/workout_folder.dart';
import '../services/workout_service.dart';
import '../constants/app_constants.dart';

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
    final workoutCount = itemCount ?? WorkoutService.instance.getWorkoutsInFolder(folder.id).length;
    
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
          transform: Matrix4.identity()..scale(showDropHint ? 1.02 : 1.0),
          margin: const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
          decoration: BoxDecoration(
            color: showDropHint
                ? AppConstants.ACCENT_COLOR.withAlpha((255 * 0.25).round())
                : AppConstants.CARD_BG_COLOR,
            borderRadius: BorderRadius.circular(showDropHint ? 16.0 : AppConstants.CARD_RADIUS),
            border: Border.all(
              color: showDropHint
                  ? AppConstants.ACCENT_COLOR.withAlpha((255 * 0.8).round())
                  : AppConstants.CARD_STROKE_COLOR,
              width: showDropHint ? 1.5 : AppConstants.CARD_STROKE_WIDTH,
            ),
            boxShadow: showDropHint
                ? [
                    BoxShadow(
                      color: AppConstants.ACCENT_COLOR.withAlpha((255 * 0.3).round()),
                      blurRadius: 12.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.15).round()),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(showDropHint ? 16.0 : AppConstants.CARD_RADIUS),
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
                            ? Colors.white.withAlpha((255 * 0.2).round())
                            : AppConstants.ACCENT_COLOR.withAlpha((255 * 0.15).round()),
                        borderRadius: BorderRadius.circular(26), // Fully rounded
                        border: Border.all(
                          color: showDropHint 
                              ? Colors.white.withAlpha((255 * 0.3).round())
                              : AppConstants.ACCENT_COLOR.withAlpha((255 * 0.3).round()),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: showDropHint ? Colors.white : AppConstants.ACCENT_COLOR,
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
                            style: AppConstants.CARD_TITLE_TEXT_STYLE,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Workout count with modern pill styling
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: showDropHint 
                                  ? Colors.white.withAlpha((255 * 0.15).round())
                                  : AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.1).round()),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fitness_center_outlined,
                                  size: 12,
                                  color: showDropHint 
                                      ? Colors.white.withAlpha((255 * 0.8).round())
                                      : AppConstants.TEXT_SECONDARY_COLOR,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$workoutCount',
                                  style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: showDropHint 
                                        ? Colors.white.withAlpha((255 * 0.9).round())
                                        : AppConstants.TEXT_SECONDARY_COLOR,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withAlpha((255 * 0.3).round()),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.move_down_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Drop here',
                              style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                            color: AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.1).round()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CupertinoButton(
                            onPressed: showMenu,
                            padding: EdgeInsets.zero,
                            child: Icon(
                              CupertinoIcons.ellipsis,
                              color: AppConstants.TEXT_SECONDARY_COLOR,
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
