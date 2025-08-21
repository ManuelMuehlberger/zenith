import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../models/workout.dart';
import '../services/workout_session_service.dart';

class ActiveWorkoutAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Workout session;
  final bool isReorderMode;
  final String weightUnit;
  final VoidCallback onReorderToggle;
  final VoidCallback onFinishWorkout;

  static const double _statsRowHeight = 36.0;

  const ActiveWorkoutAppBar({
    super.key,
    required this.session,
    required this.isReorderMode,
    required this.weightUnit,
    required this.onReorderToggle,
    required this.onFinishWorkout,
  });

  // Helper to calculate the content height (excluding SafeArea top padding)
  static double getContentHeight() {
    return kToolbarHeight + _statsRowHeight;
  }

  // preferredSize must be accessible without a BuildContext directly here.
  // It informs the Scaffold how much space to allocate.
  // We pass the context-dependent topPadding to the constructor or calculate it inside build for the actual rendering.
  // For preferredSize, we need a fixed value or one derived from passed-in parameters.
  // The actual rendered height will be dynamic in build().

  @override
  Size get preferredSize {
    // This is what the Scaffold will use to allocate space.
    // It needs to be the total height including a typical or max safe area.
    // Using a fixed large value can lead to too much space on devices with no/small safe area.
    // A better approach for dynamic preferredSize is more complex, often involving LayoutBuilder
    // or passing MediaQuery.padding.top to the constructor.
    // For simplicity and to ensure enough space, we use _staticPreferredHeight.
    // The actual rendered container will use the precise dynamic height.
    const double maxExpectedTopPadding = 64.0; // A generous estimate
    return const Size.fromHeight(kToolbarHeight + _statsRowHeight + maxExpectedTopPadding);
  }

  @override
  Widget build(BuildContext context) {
    final progress = session.completedSets / session.totalSets;
    final duration = session.completedAt != null 
        ? session.completedAt!.difference(session.startedAt ?? DateTime.now()) 
        : DateTime.now().difference(session.startedAt ?? DateTime.now());
    final double topPadding = MediaQuery.of(context).padding.top;

    // This is the height of the visible content area, AFTER SafeArea insets.
    final double contentRenderHeight = kToolbarHeight + _statsRowHeight;
    
    // This is the total height the PreferredSize widget's child (ClipRRect) will occupy.
    // It should match what the Scaffold allocates based on preferredSize getter,
    // or at least be what we intend for the BackdropFilter's extent.
    // The Container inside BackdropFilter will then be `contentRenderHeight`
    // and SafeArea will place the Column within that.
    final double totalWidgetHeight = topPadding + contentRenderHeight;


    return PreferredSize(
      preferredSize: Size.fromHeight(totalWidgetHeight), // Inform parent of our actual, dynamic size
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            // This container is the one being blurred. Its height should be the total widget height.
            height: totalWidgetHeight, 
            color: Colors.black54,
            child: SafeArea(
              bottom: false,
              child: Column( // This Column's height will be contentRenderHeight
                children: [
                  // Top row
                  SizedBox(
                    height: kToolbarHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  onReorderToggle();
                                  HapticFeedback.lightImpact();
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: isReorderMode
                                      ? Colors.orange.withAlpha((255 * 0.2).round())
                                      : Colors.grey.withAlpha((255 * 0.1).round()),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(32, 32),
                                ),
                                icon: Icon(
                                  Icons.reorder,
                                  color: isReorderMode ? Colors.orange : Colors.grey[400],
                                  size: 18,
                                ),
                                tooltip: isReorderMode ? 'Exit reorder mode' : 'Reorder exercises',
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: onFinishWorkout,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.green.withAlpha((255 * 0.1).round()),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  'Finish',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stats and progress row
                  SizedBox(
                    height: _statsRowHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildInlineStatCard(
                            WorkoutSessionService.instance.formatDuration(duration),
                            Icons.timer_outlined,
                          ),
                          Container(
                            width: 1, height: 20, color: Colors.grey[800],
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          _buildInlineStatCard(
                            '${session.completedSets}/${session.totalSets}',
                            Icons.fitness_center_outlined,
                          ),
                          Container(
                            width: 1, height: 20, color: Colors.grey[800],
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          _buildInlineStatCard(
                            '${WorkoutSessionService.instance.formatWeight(session.totalWeight)}$weightUnit',
                            Icons.monitor_weight_outlined,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(1),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[800],
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                minHeight: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
  }

  Widget _buildInlineStatCard(String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
