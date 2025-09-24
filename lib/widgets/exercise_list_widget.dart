import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:pull_down_button/pull_down_button.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../constants/app_constants.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

class ExerciseListWidget extends StatefulWidget {
  final Function(Exercise) onExerciseSelected;
  final String? title;
  final Widget? trailing;
  final double additionalTopPadding;

  const ExerciseListWidget({
    super.key,
    required this.onExerciseSelected,
    this.title,
    this.trailing,
    this.additionalTopPadding = 0.0,
  });

  @override
  State<ExerciseListWidget> createState() => _ExerciseListWidgetState();
}

class _ExerciseListWidgetState extends State<ExerciseListWidget> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  bool? _selectedBodyweight; // null = all, true = bodyweight only, false = non-bodyweight only
  List<Exercise> _filteredExercises = [];
  
  // Scroll controller to detect scroll direction
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = true;
  double _searchBarHeight = 68.0; // Height of the search bar
  double _scrollThreshold = 20.0; // Scroll distance threshold before triggering animation
  double _lastScrollOffset = 0.0; // Last scroll offset to track scroll distance

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filterExercises);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadExercises() async {
    await ExerciseService.instance.loadExercises();
    setState(() {
      _filteredExercises = ExerciseService.instance.exercises;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;
    
    // Always show search bar when at the top
    if (currentOffset <= 0) {
      if (!_showSearchBar) {
        setState(() {
          _showSearchBar = true;
        });
      }
      _lastScrollOffset = currentOffset;
      return;
    }
    
    // Only trigger animation if scrolled more than threshold
    if (delta.abs() > _scrollThreshold) {
      if (delta > 0) {
        // Scrolling down - hide search bar
        if (_showSearchBar) {
          setState(() {
            _showSearchBar = false;
          });
        }
      } else {
        // Scrolling up - show search bar
        if (!_showSearchBar) {
          setState(() {
            _showSearchBar = true;
          });
        }
      }
      _lastScrollOffset = currentOffset;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMuscleGroupChip(BuildContext context, String muscleGroup, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary ? AppConstants.ACCENT_COLOR.withAlpha((255 * 0.2).round()) : Colors.grey[800],
        border: Border.all(
          color: isPrimary ? AppConstants.ACCENT_COLOR : Colors.grey[600]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        muscleGroup,
        style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
              color: isPrimary ? AppConstants.ACCENT_COLOR : AppConstants.TEXT_SECONDARY_COLOR,
              fontWeight: isPrimary ? FontWeight.w600 : AppConstants.IOS_LABEL_FONT_WEIGHT,
            ),
      ),
    );
  }

  void _filterExercises() {
    setState(() {
      final query = _searchController.text;
      debugPrint('ExerciseListWidget: _filterExercises called with query="$query"');
      List<Exercise> exercises = ExerciseService.instance.exercises;
      
      if (query.isNotEmpty) {
        debugPrint('ExerciseListWidget: Calling searchExercises with query="$query"');
        exercises = ExerciseService.instance.searchExercises(query);
        debugPrint('ExerciseListWidget: searchExercises returned ${exercises.length} results');
      }
      
      // Filter by muscle group (single selection)
      if (_selectedMuscleGroup != null) {
        debugPrint('ExerciseListWidget: Filtering by muscle group: $_selectedMuscleGroup');
        final before = exercises.length;
        exercises = exercises.where((exercise) =>
            exercise.primaryMuscleGroup.name == _selectedMuscleGroup
        ).toList();
        debugPrint('ExerciseListWidget: Muscle group filter reduced results from $before to ${exercises.length}');
      }
      
      // Filter by equipment (single selection)
      if (_selectedEquipment != null) {
        debugPrint('ExerciseListWidget: Filtering by equipment: $_selectedEquipment');
        final before = exercises.length;
        exercises = exercises.where((exercise) {
          // Handle the spelling variation in the data ("Dumbell" vs "Dumbbell")
          final exerciseEquipment = exercise.equipment;
          final normalizedExerciseEquipment = exerciseEquipment == 'Dumbell' ? 'Dumbbell' : exerciseEquipment;
          return normalizedExerciseEquipment == _selectedEquipment;
        }).toList();
        debugPrint('ExerciseListWidget: Equipment filter reduced results from $before to ${exercises.length}');
      }
      
      // Filter by bodyweight
      if (_selectedBodyweight != null) {
        debugPrint('ExerciseListWidget: Filtering by bodyweight: $_selectedBodyweight');
        final before = exercises.length;
        exercises = exercises.where((exercise) =>
            exercise.isBodyWeightExercise == _selectedBodyweight
        ).toList();
        debugPrint('ExerciseListWidget: Bodyweight filter reduced results from $before to ${exercises.length}');
      }
      
      _filteredExercises = exercises;
      debugPrint('ExerciseListWidget: _filterExercises completed with ${_filteredExercises.length} final results');
    });
  }

  void _toggleMuscleGroup(String muscleGroup) {
    setState(() {
      if (_selectedMuscleGroup == muscleGroup) {
        _selectedMuscleGroup = null;
        debugPrint('ExerciseListWidget: Deselecting muscle group "$muscleGroup"');
      } else {
        _selectedMuscleGroup = muscleGroup;
        debugPrint('ExerciseListWidget: Selecting muscle group "$muscleGroup"');
      }
      _filterExercises();
    });
  }

  void _toggleEquipment(String equipment) {
    setState(() {
      if (_selectedEquipment == equipment) {
        _selectedEquipment = null;
        debugPrint('ExerciseListWidget: Deselecting equipment "$equipment"');
      } else {
        _selectedEquipment = equipment;
        debugPrint('ExerciseListWidget: Selecting equipment "$equipment"');
      }
      _filterExercises();
    });
  }

  void _toggleBodyweight() {
    setState(() {
      _selectedBodyweight = _selectedBodyweight == true ? null : true;
      debugPrint('ExerciseListWidget: Bodyweight filter toggled to $_selectedBodyweight');
      _filterExercises();
    });
  }

  void _clearAllFilters() {
    setState(() {
      debugPrint('ExerciseListWidget: Clearing all filters');
      _selectedMuscleGroup = null;
      _selectedEquipment = null;
      _selectedBodyweight = null;
      _filterExercises();
    });
  }

  Widget _buildFilterTag({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required List<String> items,
    required Function(String) onItemSelected,
    required String? selectedItem,
  }) {
    return PullDownButton(
      itemBuilder: (context) => items
          .map((item) => PullDownMenuItem.selectable(
                title: item,
                selected: selectedItem == item,
                onTap: () => onItemSelected(item),
              ))
          .toList(),
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: showMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.ACCENT_COLOR : Colors.grey[800]?.withAlpha(178),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: isSelected ? AppConstants.ACCENT_COLOR : Colors.grey[600]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSelected ? selectedItem! : title,
                style: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(
                  color: isSelected ? Colors.white : AppConstants.TEXT_SECONDARY_COLOR,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                CupertinoIcons.chevron_down,
                size: 14,
                color: isSelected ? Colors.white : AppConstants.TEXT_SECONDARY_COLOR,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyweightTag({
    required BuildContext context,
    required bool isSelected,
  }) {
    return CupertinoButton(
      key: const Key('bodyweight_tag_button'),
      padding: EdgeInsets.zero,
      onPressed: _toggleBodyweight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.ACCENT_COLOR : Colors.grey[800]?.withAlpha(178),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? AppConstants.ACCENT_COLOR : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Text(
          'Bodyweight',
          style: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(
            color: isSelected ? Colors.white : AppConstants.TEXT_SECONDARY_COLOR,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use predefined muscle groups from AppMuscleGroup enum (excluding NA)
    final muscleGroups = AppMuscleGroup.values
        .where((group) => group != AppMuscleGroup.na)
        .map((group) => group.displayName)
        .toList();
    
    // Use predefined equipment types from EquipmentType enum
    final equipmentList = EquipmentType.values
        .map((equipment) => equipment.displayName)
        .toList();

    // Determine if any filter is active to enable/disable Clear All
    final bool hasAnyFilter = _selectedMuscleGroup != null ||
        _selectedEquipment != null ||
        _selectedBodyweight != null;

    // Calculate internal header height for ExerciseListWidget's own search/filter bars
    double internalHeaderHeight = 0;
    if (widget.title != null || widget.trailing != null) {
      // This title/trailing is for the ExerciseListWidget itself, if provided.
      // Currently, ExercisePickerScreen doesn't pass these, so this might be 0.
      internalHeaderHeight += 48; 
    }
    if (_showSearchBar) {
      internalHeaderHeight += _searchBarHeight; // Search bar height
    }
    internalHeaderHeight += 60; // Tag filter row height

    return Stack(
      children: [
        // Exercise list (behind everything)
        _filteredExercises.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 64,
                      color: AppConstants.TEXT_TERTIARY_COLOR,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No exercises found',
                      style: AppConstants.IOS_TITLE_TEXT_STYLE.copyWith(
                        color: AppConstants.TEXT_SECONDARY_COLOR,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or filters',
                      style: AppConstants.IOS_BODY_TEXT_STYLE.copyWith(
                        color: AppConstants.TEXT_TERTIARY_COLOR,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: AppConstants.PAGE_HORIZONTAL_PADDING,
                  right: AppConstants.PAGE_HORIZONTAL_PADDING,
                  // Add space for ExerciseListWidget's own headers AND any additional top padding from parent
                  top: internalHeaderHeight + widget.additionalTopPadding + 20, 
                  bottom: AppConstants.PAGE_HORIZONTAL_PADDING,
                ),
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = _filteredExercises[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => widget.onExerciseSelected(exercise),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppConstants.EXERCISE_CARD_BG_COLOR,
                          borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
                          border: Border.all(
                            color: AppConstants.CARD_STROKE_COLOR,
                            width: AppConstants.CARD_STROKE_WIDTH,
                          ),
                        ),
                        padding: EdgeInsets.all(AppConstants.CARD_PADDING),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: AppConstants.IOS_TITLE_TEXT_STYLE,
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildMuscleGroupChip(context, exercise.primaryMuscleGroup.name, true),
                                      if (exercise.secondaryMuscleGroups.isNotEmpty)
                                        _buildMuscleGroupChip(
                                          context,
                                          exercise.secondaryMuscleGroups.map((g) => g.name).join(', '),
                                          false,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              CupertinoIcons.chevron_right,
                              color: AppConstants.TEXT_SECONDARY_COLOR,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

        // Glass header overlay for search/filter bars (on top of the list, but below screen header)
        // This Column itself is positioned at the top of the ExerciseListWidget's Stack.
        // If additionalTopPadding is > 0, this whole Column needs to be pushed down.
        Positioned(
          top: widget.additionalTopPadding,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Optional Title/Trailing for ExerciseListWidget itself (currently not used by ExercisePickerScreen)
              if (widget.title != null || widget.trailing != null)
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                    child: Container(
                      color: AppConstants.HEADER_BG_COLOR_MEDIUM,
                      padding: EdgeInsets.symmetric(horizontal: AppConstants.PAGE_HORIZONTAL_PADDING, vertical: 8.0),
                      child: Row(
                        children: [
                          if (widget.title != null)
                            Expanded(
                              child: Text(
                                widget.title!,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          if (widget.trailing != null) widget.trailing!,
                        ],
                      ),
                    ),
                  ),
                ),

              // Search bar with glass effect (collapses on scroll with animation)
              AnimatedContainer(
                key: const Key('exercise_search_container'),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _showSearchBar ? _searchBarHeight : 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                    child: Container(
                      color: AppConstants.HEADER_BG_COLOR_STRONG, // Changed to fully opaque
                      padding: EdgeInsets.symmetric(horizontal: AppConstants.PAGE_HORIZONTAL_PADDING, vertical: 12.0),
                      child: CupertinoSearchTextField(
                        controller: _searchController,
                        placeholder: 'Search exercises...',
                        placeholderStyle: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(color: AppConstants.TEXT_SECONDARY_COLOR),
                        style: AppConstants.IOS_NORMAL_TEXT_STYLE.copyWith(color: AppConstants.TEXT_PRIMARY_COLOR),
                        decoration: BoxDecoration(
                          color: Colors.grey[900]?.withAlpha(153),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // iOS-style tag filters with dropdown functionality
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                  child: Container(
                    height: 60,
                    color: AppConstants.HEADER_BG_COLOR_MEDIUM,
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.PAGE_HORIZONTAL_PADDING),
                    child: Row(
                      children: [
                        // Scrollable tags section
                        Expanded(
                          child: SingleChildScrollView(
                            key: const Key('tags_scroll'),
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // Muscle Groups Tag
                                _buildFilterTag(
                                  context: context,
                                  title: 'Muscles',
                                  isSelected: _selectedMuscleGroup != null,
                                  items: muscleGroups,
                                  onItemSelected: _toggleMuscleGroup,
                                  selectedItem: _selectedMuscleGroup,
                                ),
                                const SizedBox(width: 8),
                                // Equipment Tag
                                _buildFilterTag(
                                  context: context,
                                  title: 'Equipment',
                                  isSelected: _selectedEquipment != null,
                                  items: equipmentList,
                                  onItemSelected: _toggleEquipment,
                                  selectedItem: _selectedEquipment,
                                ),
                                const SizedBox(width: 8),
                                // Bodyweight Tag
                                _buildBodyweightTag(
                                  context: context,
                                  isSelected: _selectedBodyweight == true,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Clear All icon button (always visible)
                        CupertinoButton(
                          key: const Key('clear_all_button'),
                          padding: EdgeInsets.zero,
                          onPressed: hasAnyFilter ? _clearAllFilters : null,
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            size: 24,
                            color: hasAnyFilter ? AppConstants.ACCENT_COLOR : AppConstants.TEXT_TERTIARY_COLOR,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
