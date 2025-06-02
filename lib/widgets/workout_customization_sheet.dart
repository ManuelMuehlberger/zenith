import 'package:flutter/material.dart';

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
  State<WorkoutCustomizationSheet> createState() => _WorkoutCustomizationSheetState();
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
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
            const Text(
              'Customize Workout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color selection
                    const Text(
                      'Color',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Icon selection
                    const Text(
                      'Icon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              color: isSelected ? _selectedColor.withAlpha((255 * 0.3).round()) : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: _selectedColor, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? _selectedColor : Colors.grey[400],
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Image upload placeholder
                    const Text(
                      'Custom Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[600]!, width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.grey[500],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload Image (Coming Soon)',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
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
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
