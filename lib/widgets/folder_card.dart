import 'package:flutter/material.dart';
import '../models/workout_folder.dart';
import '../services/workout_service.dart';
import '../constants/app_constants.dart';

class FolderCard extends StatelessWidget {
  final WorkoutFolder folder;
  final VoidCallback onTap;
  final VoidCallback onMorePressed;
  final Function(String) onWorkoutDropped;
  final int? itemCount;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onMorePressed,
    required this.onWorkoutDropped,
    this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final workoutCount = itemCount ?? WorkoutService.instance.getWorkoutsInFolder(folder.id).length;
    
    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) async {
        final data = details.data;
        if (data['type'] == 'workout') {
          onWorkoutDropped(data['workoutId']);
        } else if (data['type'] == 'template') {
          onWorkoutDropped(data['templateId']);
        }
      },
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data['type'] == 'workout' || data['type'] == 'template';
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(isHovering ? 1.05 : 1.0),
          margin: EdgeInsets.only(
            bottom: isHovering ? AppConstants.CARD_VERTICAL_GAP + 4.0 : AppConstants.CARD_VERTICAL_GAP,
            left: isHovering ? 4.0 : 0.0,
            right: isHovering ? 4.0 : 0.0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isHovering ? Colors.blue.withAlpha((255 * 0.3).round()) : Colors.grey[900],
              borderRadius: BorderRadius.circular(isHovering ? 20.0 : 12.0),
              border: Border.all(
                color: isHovering 
                    ? Colors.blue.withAlpha((255 * 0.8).round())
                    : Colors.grey[800]!,
                width: isHovering ? 2.0 : 1.0,
              ),
              boxShadow: isHovering ? [
                BoxShadow(
                  color: Colors.blue.withAlpha((255 * 0.4).round()),
                  blurRadius: 12.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 4),
                ),
              ] : [
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
                borderRadius: BorderRadius.circular(isHovering ? 20.0 : 12.0),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.all(isHovering ? 20.0 : 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isHovering 
                              ? Colors.blue.withAlpha((255 * 0.4).round()) 
                              : Colors.blue.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: isHovering ? 0.05 : 0.0,
                          child: Icon(
                            Icons.folder_rounded,
                            color: isHovering ? Colors.white : Colors.blue,
                            size: 32,
                          ),
                        ),
                      ),
                      SizedBox(width: isHovering ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              child: Text(folder.name),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              child: Text('$workoutCount workout${workoutCount != 1 ? 's' : ''}'),
                            ),
                            if (isHovering) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha((255 * 0.2).round()),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withAlpha((255 * 0.3).round()),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.move_down_outlined,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Drop workout here',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isHovering ? 0.0 : 1.0,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: IgnorePointer(
                            ignoring: isHovering,
                            child: IconButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                                size: 24,
                              ),
                              onPressed: onMorePressed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
