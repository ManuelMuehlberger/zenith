import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class WorkoutCustomizationSheet extends StatefulWidget {
  final Color selectedColor;
  final IconData selectedIcon;
  final List<Color> availableColors;
  final List<IconData> availableIcons;
  final Function(Color) onColorChanged;
  final Function(IconData) onIconChanged;

  const WorkoutCustomizationSheet({
    super.key,
    required this.selectedColor,
    required this.selectedIcon,
    required this.availableColors,
    required this.availableIcons,
    required this.onColorChanged,
    required this.onIconChanged,
  });

  @override
  State<WorkoutCustomizationSheet> createState() =>
      _WorkoutCustomizationSheetState();
}

class _WorkoutCustomizationSheetState extends State<WorkoutCustomizationSheet> {
  late Color _selectedColor;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
    _selectedIcon = widget.selectedIcon;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppConstants.SHEET_RADIUS),
        topRight: Radius.circular(AppConstants.SHEET_RADIUS),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppConstants.GLASS_BLUR_SIGMA,
          sigmaY: AppConstants.GLASS_BLUR_SIGMA,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          color: colors.overlayMedium,
          child: SafeArea(
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Text('Customize Workout', style: textTheme.titleSmall),

                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Color selection
                        Text('Color', style: textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: widget.availableColors.map((color) {
                            final isSelected = color == _selectedColor;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColor = color;
                                });
                                widget.onColorChanged(color);
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: colors.textPrimary,
                                          width: 3,
                                        )
                                      : null,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: colors.textPrimary,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // Icon selection
                        Text('Icon', style: textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                          itemCount: widget.availableIcons.length,
                          itemBuilder: (context, index) {
                            final icon = widget.availableIcons[index];
                            final isSelected = icon == _selectedIcon;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = icon;
                                });
                                widget.onIconChanged(icon);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _selectedColor.withValues(alpha: 0.3)
                                      : colors.field,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: _selectedColor,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected
                                      ? _selectedColor
                                      : colors.textSecondary,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Done button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CupertinoButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(12),
                      child: Text(
                        'Done',
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
