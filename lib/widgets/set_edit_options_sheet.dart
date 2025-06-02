import 'package:flutter/material.dart';
import '../models/workout_set.dart';

class SetEditOptionsSheet extends StatelessWidget {
  final WorkoutSet set;
  final int setIndex;
  final bool canRemoveSet;
  final VoidCallback onToggleRepRange;
  final VoidCallback? onRemoveSet;

  const SetEditOptionsSheet({
    super.key,
    required this.set,
    required this.setIndex,
    required this.canRemoveSet,
    required this.onToggleRepRange,
    this.onRemoveSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Text(
              'Set ${setIndex + 1} Options',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha((255 * 0.2).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  set.isRepRange ? Icons.looks_one : Icons.swap_horiz,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              title: Text(
                set.isRepRange ? 'Switch to Single Reps' : 'Switch to Rep Range',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                onToggleRepRange();
              },
            ),
            
            if (canRemoveSet && onRemoveSet != null)
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
                title: const Text(
                  'Remove Set',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onRemoveSet!();
                },
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
