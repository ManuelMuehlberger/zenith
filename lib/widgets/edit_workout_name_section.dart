import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

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
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: selectedColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedColor.withValues(alpha: 0.4),
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
                color: context.appScheme.onPrimary,
                size: 32,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Workout name input
          Expanded(
            child: CupertinoTextField(
              controller: nameController,
              style: textTheme.displaySmall,
              placeholder: 'Workout Name',
              placeholderStyle: textTheme.displaySmall?.copyWith(
                color: colors.textTertiary,
              ),
              decoration: BoxDecoration(
                color: context.appScheme.surface.withValues(alpha: 0),
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
