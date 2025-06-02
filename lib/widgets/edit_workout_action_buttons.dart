import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class EditWorkoutActionButtons extends StatelessWidget {
  final VoidCallback onAddExercise;

  const EditWorkoutActionButtons({
    super.key,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: CupertinoButton(
          color: Colors.green.withAlpha((255 * 0.1).round()),
          borderRadius: BorderRadius.circular(12),
          padding: EdgeInsets.zero,
          onPressed: onAddExercise,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha((255 * 0.2).round()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Add Exercise',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
