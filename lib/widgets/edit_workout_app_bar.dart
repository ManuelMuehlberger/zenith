import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/workout.dart';

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
    
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: AppBar(
        backgroundColor: Colors.black,
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Title
                    Text(
                      isEditing ? 'Edit Workout' : 'New Workout',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Save button
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: isLoading ? null : onSave,
                          child: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CupertinoActivityIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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
                      '$exerciseCount ${exerciseCount == 1 ? 'Exercise' : 'Exercises'}',
                      Icons.fitness_center_outlined,
                    ),
                    
                    if (workoutName.isNotEmpty) ...[
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.grey[800],
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      
                      // Workout name
                      Expanded(
                        child: Text(
                          workoutName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
