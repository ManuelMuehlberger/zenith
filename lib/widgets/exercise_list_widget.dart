import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/exercise.dart';
import '../screens/exercise_image_gallery_screen.dart';
import '../screens/exercise_info_screen.dart';
import '../services/exercise_service.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_media.dart';

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

  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = true;
  final double _searchBarHeight = 56.0;
  final double _filterRowHeight = 52.0;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filterExercises);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadExercises() async {
    if (ExerciseService.instance.exercises.isNotEmpty) {
      setState(() {
        _filteredExercises = ExerciseService.instance.exercises;
      });
      return;
    }

    await ExerciseService.instance.loadExercises();
    setState(() {
      _filteredExercises = ExerciseService.instance.exercises;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;

    if (currentOffset <= 0) {
      if (!_showSearchBar) {
        setState(() {
          _showSearchBar = true;
        });
      }
      _lastScrollOffset = currentOffset;
      return;
    }

    if (delta.abs() > AppConstants.SCROLL_HYSTERESIS_THRESHOLD) {
      if (delta > 0) {
        if (_showSearchBar) {
          setState(() {
            _showSearchBar = false;
          });
        }
      } else {
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
            ? colorScheme.primary.withValues(alpha: 0.14)
            : colors.field.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
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

  Widget _buildExerciseMetaPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    Color? accentColor,
  }) {
    final colors = context.appColors;
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final tone = accentColor ?? colors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor != null
            ? tone.withValues(alpha: 0.12)
            : colors.field.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: accentColor != null ? tone : colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: accentColor != null ? tone : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePreview(BuildContext context, Exercise exercise) {
    final colors = context.appColors;
    final scheme = context.appScheme;
    final imagePaths = decodeExerciseImagePaths(exercise.image);
    final imagePath = imagePaths.isEmpty ? null : imagePaths.first;
    final hasAnimation = exercise.animation.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        key: Key('exercise_card_image_${exercise.slug}'),
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.textPrimary.withValues(alpha: 0.1)),
        ),
        child: imagePath == null
            ? Center(
                child: Icon(
                  hasAnimation ? Icons.play_circle_outline : Icons.image,
                  color: colors.textTertiary,
                  size: 28,
                ),
              )
            : Image(
                image: exerciseImageProviderFor(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image,
                      color: colors.textTertiary,
                      size: 28,
                    ),
                  );
                },
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

      if (_selectedMuscleGroup != null) {
        exercises = exercises
            .where(
              (exercise) =>
                  exercise.primaryMuscleGroup.name == _selectedMuscleGroup,
            )
            .toList();
      }

      if (_selectedEquipment != null) {
        exercises = exercises.where((exercise) {
          final exerciseEquipment = exercise.equipment;
          final normalizedExerciseEquipment = exerciseEquipment == 'Dumbell'
              ? 'Dumbbell'
              : exerciseEquipment;
          return normalizedExerciseEquipment == _selectedEquipment;
        }).toList();
      }

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

  Future<void> _showMuscleGroupSheet(List<String> items) async {
    final selected = await _showSingleSelectFilterSheet(
      title: 'Muscles',
      eyebrow: 'MUSCLE GROUP',
      description: 'Choose the muscle you want to focus on.',
      items: items,
      selectedItem: _selectedMuscleGroup,
      searchHint: 'Search muscles',
      heightFactor: 0.74,
    );
    if (selected == null || !mounted) return;
    _toggleMuscleGroup(selected);
  }

  Future<void> _showEquipmentSheet(List<String> items) async {
    final selected = await _showSingleSelectFilterSheet(
      title: 'Equipment',
      eyebrow: 'MACHINE / EQUIPMENT',
      description: 'Choose what the movement depends on.',
      items: items,
      selectedItem: _selectedEquipment,
      heightFactor: 0.52,
    );
    if (selected == null || !mounted) return;
    _toggleEquipment(selected);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedMuscleGroup = null;
      _selectedEquipment = null;
      _selectedBodyweight = null;
      _filterExercises();
    });
  }

  Future<String?> _showSingleSelectFilterSheet({
    required String title,
    required String eyebrow,
    required String description,
    required List<String> items,
    required String? selectedItem,
    String? searchHint,
    required double heightFactor,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.appColors.transparent,
      elevation: 0,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      builder: (context) => _ExerciseFilterSheet(
        title: title,
        eyebrow: eyebrow,
        description: description,
        items: items,
        selectedItem: selectedItem,
        searchHint: searchHint,
        heightFactor: heightFactor,
      ),
    );
  }

  Future<void> _navigateToExerciseInfo(
    BuildContext context,
    Exercise exercise,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseInfoScreen(exercise: exercise),
      ),
    );
    if (!mounted) return;
    setState(() {
      _filteredExercises = ExerciseService.instance.exercises;
    });
    _filterExercises();
  }

  Future<void> _openExerciseGallery(
    BuildContext context,
    Exercise exercise,
  ) async {
    final imagePaths = decodeExerciseImagePaths(exercise.image);
    if (imagePaths.isEmpty) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ExerciseImageGalleryScreen(
          imagePaths: imagePaths,
          title: exercise.name,
        ),
      ),
    );
  }

  Widget _buildFilterTag({
    required BuildContext context,
    required Key buttonKey,
    required String title,
    required bool isSelected,
    required String? selectedItem,
    required VoidCallback onPressed,
  }) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return CupertinoButton(
      key: buttonKey,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      onPressed: onPressed,
      minimumSize: Size.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSelected ? selectedItem! : title,
            style: textTheme.bodyMedium?.copyWith(
              color: isSelected ? colorScheme.primary : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_down,
            size: 12,
            color: isSelected ? colorScheme.primary : colors.textTertiary,
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      onPressed: _toggleBodyweight,
      minimumSize: Size.zero,
      child: Text(
        'Bodyweight',
        style: textTheme.bodyMedium?.copyWith(
          color: isSelected ? colorScheme.primary : colors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    final muscleGroups = AppMuscleGroup.values
        .where((group) => group != AppMuscleGroup.na)
        .map((group) => group.displayName)
        .toList();

    final equipmentList = EquipmentType.values
        .map((equipment) => equipment.displayName)
        .toList();

    final bool hasAnyFilter =
        _selectedMuscleGroup != null ||
        _selectedEquipment != null ||
        _selectedBodyweight != null;

    double internalHeaderHeight = 0;
    if (widget.title != null || widget.trailing != null) {
      internalHeaderHeight += 48;
    }
    if (_showSearchBar) {
      internalHeaderHeight += _searchBarHeight;
    }
    internalHeaderHeight += _filterRowHeight;

    return Stack(
      children: [
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
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.08)
                            : colorScheme.surface,
                        borderRadius: AppTheme.workoutCardBorderRadius,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.42)
                              : colorScheme.outline.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 0, 14),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  _openExerciseGallery(context, exercise),
                              child: _buildExercisePreview(context, exercise),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () =>
                                  widget.onExerciseSelected(exercise),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  8,
                                  16,
                                  8,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exercise.name,
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                      color: isSelected
                                                          ? colorScheme.primary
                                                          : colorScheme
                                                                .onSurface,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (!isMultiSelectMode)
                                          Icon(
                                            key: Key(
                                              'exercise_card_chevron_${exercise.slug}',
                                            ),
                                            CupertinoIcons.chevron_right,
                                            color: colors.textSecondary,
                                            size: 18,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _buildMuscleGroupChip(
                                          context,
                                          exercise.primaryMuscleGroup.name,
                                          true,
                                        ),
                                        if (exercise.equipment.isNotEmpty)
                                          _buildExerciseMetaPill(
                                            context,
                                            label: exercise.equipment,
                                            icon: Icons.category_outlined,
                                          ),
                                        if (exercise.isBodyWeightExercise)
                                          _buildExerciseMetaPill(
                                            context,
                                            label: 'Bodyweight',
                                            icon:
                                                Icons.accessibility_new_rounded,
                                          ),
                                        if (exercise.isCustom)
                                          _buildExerciseMetaPill(
                                            context,
                                            label: 'Custom',
                                            icon: Icons.auto_awesome_rounded,
                                            accentColor: colors.info,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (isMultiSelectMode)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 14,
                                right: 14,
                                bottom: 14,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: IconButton(
                                    key: Key(
                                      'exercise_card_info_${exercise.slug}',
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 24,
                                      height: 24,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _navigateToExerciseInfo(
                                      context,
                                      exercise,
                                    ),
                                    icon: Icon(
                                      CupertinoIcons.info_circle,
                                      color: colors.textSecondary,
                                      size: 22,
                                    ),
                                    tooltip: 'Exercise Info',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          top: widget.additionalTopPadding,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.title != null || widget.trailing != null)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
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
              AnimatedContainer(
                key: const Key('exercise_search_container'),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _showSearchBar ? _searchBarHeight : 0,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.PAGE_HORIZONTAL_PADDING,
                    vertical: 6.0,
                  ),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    prefixInsets: const EdgeInsetsDirectional.fromSTEB(
                      10,
                      8,
                      0,
                      8,
                    ),
                    suffixInsets: const EdgeInsetsDirectional.fromSTEB(
                      0,
                      8,
                      12,
                      8,
                    ),
                    placeholder: 'Search exercises...',
                    placeholderStyle: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: BoxDecoration(
                      color: colors.field.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(22.0),
                      border: Border.all(color: colors.transparent, width: 0),
                    ),
                  ),
                ),
              ),
              Container(
                height: _filterRowHeight,
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.PAGE_HORIZONTAL_PADDING,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key('tags_scroll'),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterTag(
                              context: context,
                              buttonKey: const Key('muscle_filter_tag_button'),
                              title: 'Muscles',
                              isSelected: _selectedMuscleGroup != null,
                              selectedItem: _selectedMuscleGroup,
                              onPressed: () =>
                                  _showMuscleGroupSheet(muscleGroups),
                            ),
                            const SizedBox(width: 12),
                            _buildFilterTag(
                              context: context,
                              buttonKey: const Key(
                                'equipment_filter_tag_button',
                              ),
                              title: 'Equipment',
                              isSelected: _selectedEquipment != null,
                              selectedItem: _selectedEquipment,
                              onPressed: () =>
                                  _showEquipmentSheet(equipmentList),
                            ),
                            const SizedBox(width: 12),
                            _buildBodyweightTag(
                              context: context,
                              isSelected: _selectedBodyweight == true,
                            ),
                            SizedBox(width: hasAnyFilter ? 12 : 8),
                          ],
                        ),
                      ),
                    ),
                    if (hasAnyFilter) ...[
                      const SizedBox(width: 8),
                      CupertinoButton(
                        key: const Key('clear_all_button'),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: _clearAllFilters,
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseFilterSheet extends StatefulWidget {
  final String title;
  final String eyebrow;
  final String description;
  final List<String> items;
  final String? selectedItem;
  final String? searchHint;
  final double heightFactor;

  const _ExerciseFilterSheet({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.items,
    required this.selectedItem,
    this.searchHint,
    required this.heightFactor,
  });

  @override
  State<_ExerciseFilterSheet> createState() => _ExerciseFilterSheetState();
}

class _ExerciseFilterSheetState extends State<_ExerciseFilterSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final query = _searchController.text.trim().toLowerCase();
    final filteredItems = widget.items.where((item) {
      return query.isEmpty || item.toLowerCase().contains(query);
    }).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * widget.heightFactor,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.SHEET_RADIUS),
          ),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.18),
            width: AppConstants.CARD_STROKE_WIDTH,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.eyebrow,
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.description, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (widget.selectedItem != null)
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(widget.selectedItem),
                      child: const Text('Clear'),
                    ),
                ],
              ),
              if (widget.searchHint != null) ...[
                const SizedBox(height: 14),
                SearchBar(
                  controller: _searchController,
                  leading: const Padding(
                    padding: EdgeInsetsDirectional.only(start: 4),
                    child: Icon(Icons.search),
                  ),
                  hintText: widget.searchHint,
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    colors.field.withValues(alpha: 0.55),
                  ),
                  side: WidgetStatePropertyAll(
                    BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.16),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isSelected = item == widget.selectedItem;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == filteredItems.length - 1 ? 0 : 8,
                      ),
                      child: _ExerciseFilterOptionTile(
                        key: Key(
                          '${widget.title.toLowerCase()}_filter_option_${item.toLowerCase().replaceAll(' ', '_')}',
                        ),
                        label: item,
                        selected: isSelected,
                        onTap: () => Navigator.of(context).pop(item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseFilterOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ExerciseFilterOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final colorScheme = context.appScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.12)
          : colors.field.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ExerciseFilterSelectionIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseFilterSelectionIndicator extends StatelessWidget {
  final bool selected;

  const _ExerciseFilterSelectionIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colorScheme.primary : colorScheme.surface,
        border: Border.all(
          color: selected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 14, color: colorScheme.onPrimary)
          : null,
    );
  }
}
