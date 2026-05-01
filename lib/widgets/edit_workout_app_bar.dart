import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../theme/app_theme.dart';

class EditWorkoutAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Workout? workout;
  final String workoutName;
  final int exerciseCount;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onCustomize;
  final VoidCallback onClose;

  const EditWorkoutAppBar({
    super.key,
    this.workout,
    required this.workoutName,
    required this.exerciseCount,
    required this.isLoading,
    required this.onSave,
    required this.onCustomize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing = workout != null;
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final appBarTheme = Theme.of(context).appBarTheme;

    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: AppBar(
        backgroundColor: appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top navigation bar
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Close button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onClose,
                      child: Text(
                        'Cancel',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Title
                    Text(
                      isEditing ? 'Edit Workout' : 'New Workout',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Customize button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: onCustomize,
                          child: Icon(
                            Icons.palette_outlined,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Save button
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: isLoading ? null : onSave,
                          child: isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CupertinoActivityIndicator(
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  'Save',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Stats row
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Exercise count
                    _buildInlineStatCard(
                      context,
                      '$exerciseCount ${exerciseCount == 1 ? 'Exercise' : 'Exercises'}',
                      Icons.fitness_center_outlined,
                    ),

                    if (workoutName.isNotEmpty) ...[
                      Container(
                        width: 1,
                        height: 20,
                        color: colorScheme.outline,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),

                      // Workout name
                      Expanded(
                        child: Text(
                          workoutName,
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineStatCard(
    BuildContext context,
    String value,
    IconData icon,
  ) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colorScheme.primary, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: textTheme.labelMedium?.copyWith(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
