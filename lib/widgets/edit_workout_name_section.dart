import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class EditWorkoutNameSection extends StatelessWidget {
  final TextEditingController nameController;
  final Color selectedColor;
  final IconData selectedIcon;
  final VoidCallback? onIconTap;

  const EditWorkoutNameSection({
    super.key,
    required this.nameController,
    required this.selectedColor,
    required this.selectedIcon,
    this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Workout icon preview
          GestureDetector(
            onTap: onIconTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selectedColor.withAlpha((255 * 0.2).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedColor.withAlpha((255 * 0.3).round()),
                  width: 1,
                ),
              ),
              child: Icon(
                selectedIcon,
                color: selectedColor,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Workout name input
          Expanded(
            child: CupertinoTextField(
              controller: nameController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              placeholder: 'Workout name',
              placeholderStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
