import 'dart:convert';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../screens/exercise_image_gallery_screen.dart';
import '../services/exercise_service.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_media.dart';

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

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _type = exercise?.type ?? ExerciseType.strength;
    _nameController.text = exercise?.name ?? '';
    _primaryMuscleGroup = exercise?.primaryMuscleGroup;
    _secondaryMuscleGroups = exercise?.secondaryMuscleGroups.toSet() ?? {};
    _instructions.addAll(exercise?.instructions ?? const []);
    _equipmentType = EquipmentType.fromString(exercise?.equipment ?? 'None');
    _isBodyweight = exercise?.isBodyWeightExercise ?? true;
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
              equipment: _equipmentType.displayName,
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
              equipment: _equipmentType.displayName,
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
                      final useSideBySide = constraints.maxWidth > 580;
                      final nameBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            key: const Key('custom_exercise_name_field'),
                            controller: _nameController,
                            textInputAction: TextInputAction.done,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Exercise name',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
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
                          const SizedBox(height: 12),
                          _PickerTile(
                            tileKey: const Key('primary_muscle_picker'),
                            icon: Icons.adjust,
                            title: 'Primary muscle',
                            value: _primaryMuscleGroup?.name ?? 'Choose',
                            onTap: _pickPrimaryMuscle,
                          ),
                          const SizedBox(height: 8),
                          _PickerTile(
                            tileKey: const Key('secondary_muscles_picker'),
                            icon: Icons.hub_outlined,
                            title: 'Secondary muscles',
                            value: _secondaryMuscleGroups.isEmpty
                                ? 'Optional'
                                : _secondaryMuscleGroups
                                      .map((group) => group.name)
                                      .join(', '),
                            onTap: _pickSecondaryMuscles,
                          ),
                        ],
                      );
                      final pictureBlock = _TopPicturePanel(
                        imagePaths: _imagePaths,
                        height: useSideBySide ? 112 : 132,
                        onTap: _openImageGallery,
                      );

                      if (useSideBySide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: nameBlock),
                            const SizedBox(width: 10),
                            SizedBox(width: 112, child: pictureBlock),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          nameBlock,
                          const SizedBox(height: 10),
                          SizedBox(height: 132, child: pictureBlock),
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
                    title: 'Machine / equipment',
                    value: _equipmentType.displayName,
                    icon: Icons.category_outlined,
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
                  TextFormField(
                    key: const Key('custom_exercise_instruction_field'),
                    controller: _instructionController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Add a step',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    onFieldSubmitted: (_) => _addInstruction(),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      key: const Key('custom_exercise_add_instruction_button'),
                      onPressed: _addInstruction,
                      icon: const Icon(Icons.add),
                      label: const Text('Add step'),
                    ),
                  ),
                  if (_instructions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _instructions.length,
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
      builder: (context) => _EquipmentPickerSheet(selected: _equipmentType),
    );
    if (selected == null) return;
    setState(() => _equipmentType = selected);
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
            borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
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
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final Key? tileKey;
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;

    return ListTile(
      key: tileKey,
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: colors.field.withValues(alpha: 0.55),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.appScheme.surface.withValues(alpha: 0.72),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18),
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
        borderRadius: BorderRadius.circular(12),
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
  const _TopPicturePanel({
    required this.imagePaths,
    required this.height,
    required this.onTap,
  });

  final List<String> imagePaths;
  final double height;
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
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: colors.field.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
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
              Positioned(
                right: 8,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.appScheme.shadow.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Text(
                      hasImage ? '${imagePaths.length}' : 'Add',
                      style: context.appText.labelMedium?.copyWith(
                        color: context.appScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
    final textTheme = context.appText;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            imageCount == 0
                ? Icons.add_photo_alternate_outlined
                : Icons.photo_library_outlined,
            color: colors.textSecondary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            imageCount == 0 ? 'Add pictures' : 'Open gallery',
            style: textTheme.titleSmall,
          ),
          if (imageCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              '$imageCount images',
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
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

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.74,
        decoration: BoxDecoration(
          color: context.appScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.SHEET_RADIUS),
          ),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.18),
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
                  color: scheme.outline.withValues(alpha: 0.45),
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
        ),
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
  const _EquipmentPickerSheet({required this.selected});

  final EquipmentType selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final scheme = context.appScheme;

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.52,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.SHEET_RADIUS),
          ),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.18),
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
                  color: scheme.outline.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
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
                  itemCount: EquipmentType.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final option = EquipmentType.values[index];
                    return _EquipmentOptionTile(
                      label: option.displayName,
                      selected: option == selected,
                      onTap: () => Navigator.of(context).pop(option),
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

class _EquipmentOptionTile extends StatelessWidget {
  const _EquipmentOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = context.appScheme;

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.12)
          : colors.field.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.appText.titleSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              _SelectionIndicator(selected: selected, multiSelect: false),
            ],
          ),
        ),
      ),
    );
  }
}
