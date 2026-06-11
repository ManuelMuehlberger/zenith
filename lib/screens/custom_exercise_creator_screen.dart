import 'dart:convert';

// policy: no-test-needed screen composition tested via integration tests

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../screens/exercise_image_gallery_screen.dart';
import '../services/exercise_service.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_media.dart';
import '../widgets/app_bottom_sheet.dart';

// policy: allow-public-api editor entry point for custom exercises.
class CustomExerciseCreatorScreen extends StatefulWidget {
  const CustomExerciseCreatorScreen({super.key, this.exercise});

  final Exercise? exercise;

  @override
  State<CustomExerciseCreatorScreen> createState() =>
      _CustomExerciseCreatorScreenState();
}

class _CustomExerciseCreatorScreenState
    extends State<CustomExerciseCreatorScreen> {
  static const double _sectionRadius = 20;
  static const double _controlRadius = 16;

  static const List<EquipmentType> _cardioEquipmentOptions = [
    EquipmentType.none,
    EquipmentType.machine,
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructionController = TextEditingController();
  final List<String> _instructions = [];
  final List<String> _imagePaths = [];

  late ExerciseType _type;
  MuscleGroup? _primaryMuscleGroup;
  late Set<MuscleGroup> _secondaryMuscleGroups;
  late EquipmentType _equipmentType;
  late bool _isBodyweight;
  bool _isSaving = false;

  bool get _isEditing => widget.exercise != null;
  bool get _hasPendingInstruction =>
      _instructionController.text.trim().isNotEmpty;
  List<EquipmentType> get _availableEquipmentOptions =>
      _type == ExerciseType.cardio
      ? _cardioEquipmentOptions
      : EquipmentType.values;

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _type = exercise?.type ?? ExerciseType.strength;
    _nameController.text = exercise?.name ?? '';
    _primaryMuscleGroup = exercise?.primaryMuscleGroup;
    _secondaryMuscleGroups = exercise?.secondaryMuscleGroups.toSet() ?? {};
    _instructions.addAll(exercise?.instructions ?? const []);
    _isBodyweight = exercise?.isBodyWeightExercise ?? true;
    _equipmentType = _normalizeEquipmentForType(
      _type,
      EquipmentType.fromString(exercise?.equipment ?? 'None'),
    );
    _imagePaths.addAll(decodeExerciseImagePaths(exercise?.image ?? ''));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  void _addInstruction() {
    final instruction = _instructionController.text.trim();
    if (instruction.isEmpty) return;

    setState(() {
      _instructions.add(instruction);
      _instructionController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_primaryMuscleGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a primary muscle first.')),
      );
      return;
    }

    _addInstruction();
    setState(() => _isSaving = true);

    try {
      final exercise = _isEditing
          ? await ExerciseService.instance.updateCustomExercise(
              original: widget.exercise!,
              name: _nameController.text,
              primaryMuscleGroup: _primaryMuscleGroup!.name,
              secondaryMuscleGroups: _secondaryMuscleGroups
                  .where((group) => group != _primaryMuscleGroup)
                  .map((group) => group.name)
                  .toList(),
              instructions: _instructions,
              equipment: _normalizeEquipmentForType(
                _type,
                _equipmentType,
              ).displayName,
              image: _imagePaths.isEmpty ? '' : jsonEncode(_imagePaths),
              isBodyWeightExercise: _isBodyweight,
              type: _type,
            )
          : await ExerciseService.instance.createCustomExercise(
              name: _nameController.text,
              primaryMuscleGroup: _primaryMuscleGroup!.name,
              secondaryMuscleGroups: _secondaryMuscleGroups
                  .where((group) => group != _primaryMuscleGroup)
                  .map((group) => group.name)
                  .toList(),
              instructions: _instructions,
              equipment: _normalizeEquipmentForType(
                _type,
                _equipmentType,
              ).displayName,
              image: _imagePaths.isEmpty ? '' : jsonEncode(_imagePaths),
              isBodyWeightExercise: _isBodyweight,
              type: _type,
            );

      if (!mounted) return;
      Navigator.of(context).pop<Exercise>(exercise);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save exercise: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Exercise' : 'Custom Exercise'),
        centerTitle: true,
        backgroundColor: colors.overlayStrong,
        surfaceTintColor: colors.transparent,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppConstants.PAGE_HORIZONTAL_PADDING,
            16,
            AppConstants.PAGE_HORIZONTAL_PADDING,
            MediaQuery.of(context).padding.bottom + 32,
          ),
          children: [
            _SectionPanel(
              title: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final pictureSize = constraints.maxWidth < 360
                          ? 84.0
                          : 96.0;
                      final nameRow = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: pictureSize,
                            height: pictureSize,
                            child: _TopPicturePanel(
                              imagePaths: _imagePaths,
                              onTap: _openImageGallery,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: const Key('custom_exercise_name_field'),
                              controller: _nameController,
                              textInputAction: TextInputAction.done,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Exercise name',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.only(top: 4),
                                hintStyle: textTheme.headlineSmall?.copyWith(
                                  color: colors.textTertiary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          nameRow,
                          const SizedBox(height: 10),
                          _PickerTile(
                            tileKey: const Key('primary_muscle_picker'),
                            iconKey: const Key('primary_muscle_picker_icon'),
                            icon: Icons.adjust,
                            title: 'Primary muscle',
                            value: _primaryMuscleGroup?.name ?? 'Choose',
                            isSelected: _primaryMuscleGroup != null,
                            onTap: _pickPrimaryMuscle,
                          ),
                          const SizedBox(height: 8),
                          _PickerTile(
                            tileKey: const Key('secondary_muscles_picker'),
                            iconKey: const Key('secondary_muscles_picker_icon'),
                            icon: Icons.hub_outlined,
                            title: 'Secondary muscles',
                            value: _secondaryMuscleGroups.isEmpty
                                ? 'Optional'
                                : _secondaryMuscleGroups
                                      .map((group) => group.name)
                                      .join(', '),
                            isSelected: _secondaryMuscleGroups.isNotEmpty,
                            onTap: _pickSecondaryMuscles,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionPanel(
              title: 'Setup',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<ExerciseType>(
                    key: const Key('custom_exercise_type_segmented_button'),
                    segments: const [
                      ButtonSegment(
                        value: ExerciseType.strength,
                        icon: Icon(Icons.fitness_center),
                        label: Text(
                          'Strength',
                          key: Key('strength_type_label'),
                        ),
                      ),
                      ButtonSegment(
                        value: ExerciseType.cardio,
                        icon: Icon(Icons.directions_run),
                        label: Text('Cardio', key: Key('cardio_type_label')),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _type = selection.single;
                        _equipmentType = _normalizeEquipmentForType(
                          _type,
                          _equipmentType,
                        );
                      });
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PickerTile(
                    tileKey: const Key('equipment_picker'),
                    iconKey: const Key('equipment_picker_icon'),
                    title: 'Machine / equipment',
                    value: _equipmentType.displayName,
                    icon: Icons.category_outlined,
                    isSelected: _equipmentType != EquipmentType.none,
                    onTap: _pickEquipment,
                  ),
                  const SizedBox(height: 10),
                  _MaterialSwitchRow(
                    title: 'Bodyweight',
                    subtitle: _type == ExerciseType.cardio
                        ? 'Use for runs, circuits, and movement-only cardio.'
                        : 'Hide weight inputs during workouts.',
                    value: _isBodyweight,
                    onChanged: (value) {
                      setState(() => _isBodyweight = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionPanel(
              title: 'Instructions',
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('custom_exercise_instruction_field'),
                          controller: _instructionController,
                          minLines: 1,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Add a step',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _addInstruction(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        key: const Key(
                          'custom_exercise_add_instruction_button',
                        ),
                        onPressed: _hasPendingInstruction
                            ? _addInstruction
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Add step',
                      ),
                    ],
                  ),
                  if (_instructions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _instructions.length,
                      // ignore: deprecated_member_use
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _instructions.removeAt(oldIndex);
                          _instructions.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        return ListTile(
                          key: ValueKey(_instructions[index]),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 13,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(_instructions[index]),
                          trailing: IconButton(
                            onPressed: () {
                              setState(() => _instructions.removeAt(index));
                            },
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove instruction',
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPrimaryMuscle() async {
    final selected = await showModalBottomSheet<MuscleGroup>(
      context: context,
      backgroundColor: context.appColors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => _MusclePickerSheet(
        selected: _primaryMuscleGroup == null
            ? const <MuscleGroup>{}
            : <MuscleGroup>{_primaryMuscleGroup!},
        multiSelect: false,
      ),
    );
    if (selected == null) return;
    setState(() {
      _primaryMuscleGroup = selected;
      _secondaryMuscleGroups.remove(selected);
    });
  }

  Future<void> _pickSecondaryMuscles() async {
    final selected = await showModalBottomSheet<Set<MuscleGroup>>(
      context: context,
      backgroundColor: context.appColors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => _MusclePickerSheet(
        selected: _secondaryMuscleGroups,
        excluded: _primaryMuscleGroup,
        multiSelect: true,
      ),
    );
    if (selected == null) return;
    setState(() => _secondaryMuscleGroups = selected);
  }

  Future<void> _pickEquipment() async {
    final selected = await showModalBottomSheet<EquipmentType>(
      context: context,
      backgroundColor: context.appColors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => _EquipmentPickerSheet(
        selected: _equipmentType,
        options: _availableEquipmentOptions,
      ),
    );
    if (selected == null) return;
    setState(
      () => _equipmentType = _normalizeEquipmentForType(_type, selected),
    );
  }

  EquipmentType _normalizeEquipmentForType(
    ExerciseType type,
    EquipmentType equipment,
  ) {
    if (type != ExerciseType.cardio) return equipment;
    return _cardioEquipmentOptions.contains(equipment)
        ? equipment
        : EquipmentType.none;
  }

  Future<void> _openImageGallery() async {
    final updatedPaths = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => ExerciseImageGalleryScreen(
          imagePaths: _imagePaths,
          editable: true,
          title: _nameController.text.trim().isEmpty
              ? 'Exercise Pictures'
              : _nameController.text.trim(),
        ),
      ),
    );
    if (updatedPaths == null) return;
    setState(() {
      _imagePaths
        ..clear()
        ..addAll(updatedPaths);
    });
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({required this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              title!.toUpperCase(),
              style: context.appText.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.all(AppConstants.CARD_PADDING),
          decoration: BoxDecoration(
            color: context.appScheme.surface,
            borderRadius: BorderRadius.circular(
              _CustomExerciseCreatorScreenState._sectionRadius,
            ),
            border: Border.all(
              color: colors.textPrimary.withValues(alpha: 0.08),
              width: AppConstants.CARD_STROKE_WIDTH,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    this.tileKey,
    this.iconKey,
    required this.icon,
    required this.title,
    required this.value,
    this.isSelected = false,
    required this.onTap,
  });

  final Key? tileKey;
  final Key? iconKey;
  final IconData icon;
  final String title;
  final String value;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final scheme = context.appScheme;

    return Material(
      color: colors.field.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          _CustomExerciseCreatorScreenState._controlRadius,
        ),
      ),
      child: ListTile(
        key: tileKey,
        enabled: onTap != null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            _CustomExerciseCreatorScreenState._controlRadius,
          ),
        ),
        tileColor: colors.transparent,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.14)
                : scheme.surface.withValues(alpha: 0.72),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            key: iconKey,
            size: 18,
            color: isSelected ? scheme.primary : colors.textSecondary,
          ),
        ),
        title: Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium,
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
        onTap: onTap,
      ),
    );
  }
}

class _MaterialSwitchRow extends StatelessWidget {
  const _MaterialSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final scheme = context.appScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.field.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(
          _CustomExerciseCreatorScreenState._controlRadius,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: value
                  ? scheme.primary.withValues(alpha: 0.14)
                  : scheme.surface.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              size: 18,
              color: value ? scheme.primary : colors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            trackOutlineColor: WidgetStatePropertyAll(colors.transparent),
            activeThumbColor: scheme.onPrimary,
            activeTrackColor: scheme.primary,
            inactiveThumbColor: scheme.onSurface,
            inactiveTrackColor: colors.field,
          ),
        ],
      ),
    );
  }
}

class _TopPicturePanel extends StatelessWidget {
  const _TopPicturePanel({required this.imagePaths, required this.onTap});

  final List<String> imagePaths;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = context.appScheme;
    final hasImage = imagePaths.isNotEmpty;

    return Material(
      color: colors.transparent,
      child: InkWell(
        key: const Key('custom_exercise_open_gallery'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          _CustomExerciseCreatorScreenState._controlRadius,
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.field.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(
              _CustomExerciseCreatorScreenState._controlRadius,
            ),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                          _CustomExerciseCreatorScreenState._controlRadius,
                        ),
                        child: Image(
                          image: exerciseImageProviderFor(imagePaths.first),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _GalleryPreviewPlaceholder(
                            imageCount: imagePaths.length,
                          ),
                        ),
                      )
                    : const _GalleryPreviewPlaceholder(imageCount: 0),
              ),
              if (hasImage)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.textPrimary.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryPreviewPlaceholder extends StatelessWidget {
  const _GalleryPreviewPlaceholder({required this.imageCount});

  final int imageCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Icon(
        imageCount == 0
            ? Icons.add_photo_alternate_outlined
            : Icons.photo_library_outlined,
        color: colors.textSecondary,
        size: 28,
      ),
    );
  }
}

class _MusclePickerSheet extends StatefulWidget {
  const _MusclePickerSheet({
    required this.selected,
    required this.multiSelect,
    this.excluded,
  });

  final Set<MuscleGroup> selected;
  final bool multiSelect;
  final MuscleGroup? excluded;

  @override
  State<_MusclePickerSheet> createState() => _MusclePickerSheetState();
}

class _MusclePickerSheetState extends State<_MusclePickerSheet> {
  final _searchController = TextEditingController();
  late Set<MuscleGroup> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selected};
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final colors = context.appColors;
    final textTheme = context.appText;
    final scheme = context.appScheme;
    final groups = MuscleGroup.values.where((group) {
      if (group == MuscleGroup.na || group == widget.excluded) return false;
      return query.isEmpty || group.name.toLowerCase().contains(query);
    }).toList();

    return AppBottomSheet(
      height: MediaQuery.of(context).size.height * 0.74,
      child: Column(
        children: [
          const AppBottomSheetHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.multiSelect
                              ? 'Secondary muscles'
                              : 'Primary muscle')
                          .toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.multiSelect
                          ? 'Choose every muscle that supports the movement.'
                          : 'Choose the muscle the exercise is mainly built around.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (widget.multiSelect)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text('Done'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SearchBar(
            controller: _searchController,
            leading: const Icon(Icons.search),
            hintText: 'Search muscles',
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(
              colors.field.withValues(alpha: 0.55),
            ),
            side: WidgetStatePropertyAll(
              BorderSide(color: scheme.outline.withValues(alpha: 0.16)),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final group = groups[index];
                final selected = _selected.contains(group);
                return _MuscleOptionTile(
                  label: group.name,
                  selected: selected,
                  multiSelect: widget.multiSelect,
                  onTap: () {
                    if (!widget.multiSelect) {
                      Navigator.of(context).pop(group);
                      return;
                    }
                    setState(() {
                      if (selected) {
                        _selected.remove(group);
                      } else {
                        _selected.add(group);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleOptionTile extends StatelessWidget {
  const _MuscleOptionTile({
    required this.label,
    required this.selected,
    required this.multiSelect,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final scheme = context.appScheme;

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.12)
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
              _SelectionIndicator(selected: selected, multiSelect: multiSelect),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.selected,
    required this.multiSelect,
  });

  final bool selected;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = context.appScheme;

    if (multiSelect) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.6)
                : scheme.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          selected ? 'Selected' : 'Add',
          style: context.appText.labelMedium?.copyWith(
            color: selected ? scheme.primary : colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : scheme.surface,
        border: Border.all(
          color: selected
              ? scheme.primary
              : scheme.outline.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 14, color: scheme.onPrimary)
          : null,
    );
  }
}

class _EquipmentPickerSheet extends StatelessWidget {
  const _EquipmentPickerSheet({required this.selected, required this.options});

  final EquipmentType selected;
  final List<EquipmentType> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;

    return AppBottomSheet(
      height: MediaQuery.of(context).size.height * 0.52,
      child: Column(
        children: [
          const AppBottomSheetHandle(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MACHINE / EQUIPMENT',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose what the movement depends on.',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                return AppBottomSheetOptionTile(
                  label: option.displayName,
                  selected: option == selected,
                  onTap: () => Navigator.of(context).pop(option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
