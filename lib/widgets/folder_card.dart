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
          transform: Matrix4.identity()..scale(showDropHint ? 1.03 : 1.0),
          margin: const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
          decoration: BoxDecoration(
            color: showDropHint
                ? Colors.blue.withAlpha((255 * 0.3).round())
                : Colors.grey[900],
            borderRadius: BorderRadius.circular(showDropHint ? 20.0 : 12.0),
            border: Border.all(
              color: showDropHint
                  ? Colors.blue.withAlpha((255 * 0.8).round())
                  : Colors.grey[800]!,
              width: showDropHint ? 2.0 : 1.0,
            ),
            boxShadow: showDropHint
                ? [
                    BoxShadow(
                      color: Colors.blue.withAlpha((255 * 0.4).round()),
                      blurRadius: 12.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.3).round()),
                      blurRadius: 4.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(showDropHint ? 20.0 : 12.0),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_rounded,
                      color: showDropHint ? Colors.white : Colors.blue,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$workoutCount workout${workoutCount != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showDropHint)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.move_down_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Drop to move',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
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
                        buttonBuilder: (context, showMenu) => CupertinoButton(
                          onPressed: showMenu,
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.ellipsis_circle,
                            color: Colors.grey,
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
