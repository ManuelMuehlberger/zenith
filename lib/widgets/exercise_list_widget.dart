import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../constants/app_constants.dart';
import '../models/exercise.dart';
import '../screens/exercise_info_screen.dart';
import '../services/exercise_service.dart';
import '../theme/app_theme.dart';

class ExerciseListWidget extends StatefulWidget {
  final Function(Exercise) onExerciseSelected;
  final String? title;
  final Widget? trailing;
  final double additionalTopPadding;
  final List<Exercise>? selectedExercises;

  const ExerciseListWidget({
    super.key,
    required this.onExerciseSelected,
    this.title,
    this.trailing,
    this.additionalTopPadding = 0.0,
    this.selectedExercises,
  });

  @override
  State<ExerciseListWidget> createState() => _ExerciseListWidgetState();
}

class _ExerciseListWidgetState extends State<ExerciseListWidget> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  bool?
  _selectedBodyweight; // null = all, true = bodyweight only, false = non-bodyweight only
  List<Exercise> _filteredExercises = [];

  // Scroll controller to detect scroll direction
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = true;
  final double _searchBarHeight = 56.0; // Height of the search bar
  final double _filterRowHeight = 52.0;
  double _lastScrollOffset = 0.0; // Last scroll offset to track scroll distance

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filterExercises);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadExercises() async {
    // If exercises are already loaded, use them directly
    if (ExerciseService.instance.exercises.isNotEmpty) {
      setState(() {
        _filteredExercises = ExerciseService.instance.exercises;
      });
      return;
    }

    // Otherwise, load them from the service
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

    // Hysteresis check
    if (delta.abs() > AppConstants.SCROLL_HYSTERESIS_THRESHOLD) {
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

  Widget _buildMuscleGroupChip(
    BuildContext context,
    String muscleGroup,
    bool isPrimary,
  ) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary
            ? colorScheme.primary.withValues(alpha: 0.2)
            : colors.field,
        border: Border.all(
          color: isPrimary ? colorScheme.primary : colors.textSecondary,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        muscleGroup,
        style: textTheme.labelMedium?.copyWith(
          color: isPrimary ? colorScheme.primary : colors.textSecondary,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  void _filterExercises() {
    setState(() {
      final query = _searchController.text;
      List<Exercise> exercises = ExerciseService.instance.exercises;

      if (query.isNotEmpty) {
        exercises = ExerciseService.instance.searchExercises(query);
      }

      // Filter by muscle group (single selection)
      if (_selectedMuscleGroup != null) {
        exercises = exercises
            .where(
              (exercise) =>
                  exercise.primaryMuscleGroup.name == _selectedMuscleGroup,
            )
            .toList();
      }

      // Filter by equipment (single selection)
      if (_selectedEquipment != null) {
        exercises = exercises.where((exercise) {
          // Handle the spelling variation in the data ("Dumbell" vs "Dumbbell")
          final exerciseEquipment = exercise.equipment;
          final normalizedExerciseEquipment = exerciseEquipment == 'Dumbell'
              ? 'Dumbbell'
              : exerciseEquipment;
          return normalizedExerciseEquipment == _selectedEquipment;
        }).toList();
      }

      // Filter by bodyweight
      if (_selectedBodyweight != null) {
        exercises = exercises
            .where(
              (exercise) =>
                  exercise.isBodyWeightExercise == _selectedBodyweight,
            )
            .toList();
      }

      _filteredExercises = exercises;
    });
  }

  void _toggleMuscleGroup(String muscleGroup) {
    setState(() {
      if (_selectedMuscleGroup == muscleGroup) {
        _selectedMuscleGroup = null;
      } else {
        _selectedMuscleGroup = muscleGroup;
      }
      _filterExercises();
    });
  }

  void _toggleEquipment(String equipment) {
    setState(() {
      if (_selectedEquipment == equipment) {
        _selectedEquipment = null;
      } else {
        _selectedEquipment = equipment;
      }
      _filterExercises();
    });
  }

  void _toggleBodyweight() {
    setState(() {
      _selectedBodyweight = _selectedBodyweight == true ? null : true;
      _filterExercises();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedMuscleGroup = null;
      _selectedEquipment = null;
      _selectedBodyweight = null;
      _filterExercises();
    });
  }

  void _navigateToExerciseInfo(BuildContext context, Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseInfoScreen(exercise: exercise),
      ),
    );
  }

  Widget _buildFilterTag({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required List<String> items,
    required Function(String) onItemSelected,
    required String? selectedItem,
  }) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return PullDownButton(
      itemBuilder: (context) => items
          .map(
            (item) => PullDownMenuItem.selectable(
              title: item,
              selected: selectedItem == item,
              onTap: () => onItemSelected(item),
            ),
          )
          .toList(),
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: showMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colors.field.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colors.textSecondary,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSelected ? selectedItem! : title,
                style: textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                CupertinoIcons.chevron_down,
                size: 14,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colors.textSecondary,
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
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return CupertinoButton(
      key: const Key('bodyweight_tag_button'),
      padding: EdgeInsets.zero,
      onPressed: _toggleBodyweight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colors.field.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colors.textSecondary,
            width: 1,
          ),
        ),
        child: Text(
          'Bodyweight',
          style: textTheme.bodyMedium?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

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
    final bool hasAnyFilter =
        _selectedMuscleGroup != null ||
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
    internalHeaderHeight += _filterRowHeight; // Tag filter row height

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
                      color: colors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No exercises found',
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or filters',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textTertiary,
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
                  final bool isSelected =
                      widget.selectedExercises?.contains(exercise) ?? false;
                  final bool isMultiSelectMode =
                      widget.selectedExercises != null;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.CARD_VERTICAL_GAP,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppConstants.CARD_RADIUS,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : Theme.of(context).dividerColor,
                          width: AppConstants.CARD_STROKE_WIDTH,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Main tappable area for selection
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () =>
                                  widget.onExerciseSelected(exercise),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppConstants.CARD_PADDING,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exercise.name,
                                            style: textTheme.titleSmall,
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              _buildMuscleGroupChip(
                                                context,
                                                exercise
                                                    .primaryMuscleGroup
                                                    .name,
                                                true,
                                              ),
                                              if (exercise
                                                  .secondaryMuscleGroups
                                                  .isNotEmpty)
                                                _buildMuscleGroupChip(
                                                  context,
                                                  exercise.secondaryMuscleGroups
                                                      .map((g) => g.name)
                                                      .join(', '),
                                                  false,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12.0,
                                        ),
                                        child: Icon(
                                          CupertinoIcons
                                              .check_mark_circled_solid,
                                          color: colorScheme.primary,
                                          size: 24,
                                        ),
                                      )
                                    else if (!isMultiSelectMode)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12.0,
                                        ),
                                        child: Icon(
                                          CupertinoIcons.chevron_right,
                                          color: colors.textSecondary,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Info button (always visible in multi-select mode, or when not selected in single-select mode)
                          if (isMultiSelectMode)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: IconButton(
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    _navigateToExerciseInfo(context, exercise),
                                icon: Icon(
                                  CupertinoIcons.info_circle,
                                  color: colors.textSecondary,
                                  size: 28,
                                ),
                                tooltip: 'Exercise Info',
                              ),
                            ),
                        ],
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
                    filter: ImageFilter.blur(
                      sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                      sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                    ),
                    child: Container(
                      color: colors.overlayMedium,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.PAGE_HORIZONTAL_PADDING,
                        vertical: 8.0,
                      ),
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
                    filter: ImageFilter.blur(
                      sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                      sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                    ),
                    child: Container(
                      color: colors.overlayStrong,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.PAGE_HORIZONTAL_PADDING,
                        vertical: 6.0,
                      ),
                      child: CupertinoSearchTextField(
                        controller: _searchController,
                        placeholder: 'Search exercises...',
                        placeholderStyle: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        decoration: BoxDecoration(
                          color: colors.field.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // iOS-style tag filters with dropdown functionality
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                    sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                  ),
                  child: Container(
                    height: _filterRowHeight,
                    color: colors.overlayMedium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.PAGE_HORIZONTAL_PADDING,
                    ),
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
                        if (hasAnyFilter) ...[
                          const SizedBox(width: 8),
                          CupertinoButton(
                            key: const Key('clear_all_button'),
                            padding: EdgeInsets.zero,
                            onPressed: _clearAllFilters,
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
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
