import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_constants.dart';

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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: selectedColor.withAlpha((255 * 0.2).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedColor.withAlpha((255 * 0.4).round()),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Workout icon preview
          GestureDetector(
            onTap: onIconTap,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(30), // Fully rounded
              ),
              child: Icon(
                selectedIcon,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Workout name input
          Expanded(
            child: CupertinoTextField(
              controller: nameController,
              style: AppConstants.HEADER_EXTRA_LARGE_TITLE_TEXT_STYLE.copyWith(
                color: Colors.white,
              ),
              placeholder: 'Workout Name',
              placeholderStyle: AppConstants.HEADER_EXTRA_LARGE_TITLE_TEXT_STYLE.copyWith(
                color: Colors.white.withAlpha((255 * 0.6).round()),
              ),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
