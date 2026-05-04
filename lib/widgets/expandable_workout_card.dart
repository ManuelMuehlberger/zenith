import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../constants/app_constants.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_template.dart';
import '../services/workout_session_service.dart';
import '../services/workout_template_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../utils/workout_metrics.dart';
import 'workouts_page_menu_theme.dart';

class ExpandableWorkoutCard extends StatefulWidget {
  // Unified: support either a concrete Workout (legacy usage) or a WorkoutTemplate (preferred)
  final Workout? workout;
  final WorkoutTemplate? template;
  final Future<List<WorkoutExercise>> Function(String templateId)?
  loadTemplateExercises;

  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;
  final int index;

  const ExpandableWorkoutCard({
    super.key,
    this.workout,
    this.template,
    this.loadTemplateExercises,
    required this.onEditPressed,
    required this.onDeletePressed,
    required this.index,
  }) : assert(
         (workout != null) != (template != null),
         'Provide exactly one of workout or template',
       );

  @override
  State<ExpandableWorkoutCard> createState() => _ExpandableWorkoutCardState();
}

class _ExpandableWorkoutCardState extends State<ExpandableWorkoutCard> {
  List<WorkoutExercise>? _templateExercises;
  bool _loadingTemplateExercises = false;

  bool get _isTemplate => widget.template != null;

  String get _displayName =>
      _isTemplate ? widget.template!.name : widget.workout!.name;

  String? get _displayDescription {
    final rawValue = _isTemplate
        ? widget.template!.description
        : widget.workout!.description;
    if (rawValue == null) {
      return null;
    }
    final trimmed = rawValue.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  IconData get _displayIcon => _isTemplate
      ? WorkoutIcons.getIconDataFromCodePoint(widget.template!.iconCodePoint)
      : widget.workout!.icon;

  Color _resolveDisplayColor(Color fallbackColor) {
    if (!_isTemplate) {
      return widget.workout!.color;
    }

    final templateColorValue = widget.template!.colorValue;
    if (templateColorValue == null) {
      return fallbackColor;
    }

    return Workout(
      id: widget.template!.id,
      name: widget.template!.name,
      colorValue: templateColorValue,
    ).color;
  }

  List<WorkoutExercise> get _effectiveExercises => _isTemplate
      ? (_templateExercises ?? const [])
      : widget.workout!.exercises;

  int get _exerciseCount => _effectiveExercises.length;

  int get _totalSets =>
      _effectiveExercises.fold(0, (sum, e) => sum + e.sets.length);

  @override
  void initState() {
    super.initState();
    if (_isTemplate) {
      _loadTemplateExercises();
    }
  }

  @override
  void didUpdateWidget(covariant ExpandableWorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool wasTemplate = oldWidget.template != null;
    final bool isTemplate = widget.template != null;

    // If switching between modes (template vs workout), reset and (re)load as needed
    if (wasTemplate != isTemplate) {
      setState(() {
        _templateExercises = null;
        _loadingTemplateExercises = false;
      });
      if (isTemplate) {
        _loadTemplateExercises();
      }
      return;
    }

    // In template mode, refresh the lazily-cached exercises when the template instance changes
    if (isTemplate) {
      final oldId = oldWidget.template!.id;
      final newId = widget.template!.id;

      // Reload if the id changed or we received a new template instance (e.g., after editing)
      if (oldId != newId || oldWidget.template != widget.template) {
        setState(() {
          _templateExercises = null;
          _loadingTemplateExercises = false;
        });
        _loadTemplateExercises();
      }
    }
  }

  Future<void> _loadTemplateExercises() async {
    if (_loadingTemplateExercises || !_isTemplate) return;
    setState(() {
      _loadingTemplateExercises = true;
    });
    try {
      final items = await (widget.loadTemplateExercises != null
          ? widget.loadTemplateExercises!(widget.template!.id)
          : WorkoutTemplateService.instance.getTemplateExercises(
              widget.template!.id,
            ));
      if (mounted) {
        setState(() {
          _templateExercises = items;
        });
      }
    } catch (_) {
      // Fail silently for preview
      if (mounted) {
        setState(() {
          _templateExercises = const [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTemplateExercises = false;
        });
      }
    }
  }

  Future<void> _startWorkout() async {
    try {
      if (_isTemplate) {
        // Ensure exercises are loaded
        if (_templateExercises == null) {
          await _loadTemplateExercises();
        }
        final exercises = _templateExercises ?? const <WorkoutExercise>[];

        // Build a transient Workout from the template to start the session
        final template = widget.template!;
        final templateAsWorkout = Workout(
          id: template.id, // use template id as linkage
          name: template.name,
          description: template.description,
          iconCodePoint: template.iconCodePoint,
          colorValue: template.colorValue,
          folderId: template.folderId,
          notes: template.notes,
          status: WorkoutStatus.template,
          exercises: exercises,
        );

        await WorkoutSessionService.instance.startWorkout(templateAsWorkout);
      } else {
        // Backward compatibility: start from a Workout if provided
        await WorkoutSessionService.instance.startWorkout(widget.workout!);
      }

      unawaited(HapticFeedback.mediumImpact());

      if (mounted) {
        // Navigate to the Workouts tab (index 1)
        // The WorkoutBuilderScreen on that tab will then display the ActiveWorkoutScreen
        NavigationHelper.goToTab(1);
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = context.appScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start workout: $e'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final displayColor = _resolveDisplayColor(colorScheme.primary);
    final description = _displayDescription;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppTheme.workoutCardBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: displayColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(_displayIcon, color: displayColor, size: 28),
                ),
                const SizedBox(width: AppConstants.ITEM_HORIZONTAL_GAP),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isTemplate ? 'Template' : 'Workout',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _displayName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                buildWorkoutsPageMenuWrapper(
                  context,
                  child: PullDownButton(
                    itemBuilder: (context) => [
                      PullDownMenuItem(
                        onTap: widget.onEditPressed,
                        title: 'Edit Workout',
                        icon: Icons.edit_outlined,
                      ),
                      PullDownMenuItem(
                        onTap: widget.onDeletePressed,
                        title: 'Delete Workout',
                        isDestructive: true,
                        icon: Icons.delete_outline_rounded,
                      ),
                    ],
                    buttonBuilder: (context, showMenu) => _buildIconShell(
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                      onTap: showMenu,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCenteredMetric(
                    value: '${_exerciseCount}',
                    label: 'EX',
                  ),
                ),
                _buildMetricDivider(),
                Expanded(
                  child: _buildCenteredMetric(
                    value: '${_totalSets}',
                    label: 'SETS',
                  ),
                ),
                _buildMetricDivider(),
                Expanded(
                  child: _buildCenteredMetric(
                    value: _compactDurationLabel(
                      WorkoutMetrics.getFormattedDuration(_effectiveExercises),
                    ),
                    label: 'TIME',
                  ),
                ),
              ],
            ),
            if (_loadingTemplateExercises) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: displayColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading template details',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _startWorkout,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  'Start Workout',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compactDurationLabel(String value) {
    return value
        .replaceAll('~', '')
        .replaceAll(' hrs', 'h')
        .replaceAll(' hr', 'h')
        .replaceAll(' mins', 'm')
        .replaceAll(' min', 'm')
        .replaceAll(' ', ' ')
        .trim();
  }

  Widget _buildCenteredMetric({required String value, required String label}) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    final colors = context.appColors;

    return Container(
      width: 1,
      height: 28,
      color: colors.textTertiary.withValues(alpha: 0.18),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildIconShell({required Widget child, required VoidCallback onTap}) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
