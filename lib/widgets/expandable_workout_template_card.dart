import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';
import '../models/workout_template.dart';
import '../theme/app_theme.dart';

class ExpandableWorkoutTemplateCard extends StatefulWidget {
  final WorkoutTemplate template;
  final int index;
  final VoidCallback onEditPressed;
  final VoidCallback onMorePressed;
  final VoidCallback? onDragStartedCallback;
  final VoidCallback? onDragEndCallback;

  const ExpandableWorkoutTemplateCard({
    super.key,
    required this.template,
    required this.index,
    required this.onEditPressed,
    required this.onMorePressed,
    this.onDragStartedCallback,
    this.onDragEndCallback,
  });

  @override
  State<ExpandableWorkoutTemplateCard> createState() =>
      _ExpandableWorkoutTemplateCardState();
}

class _ExpandableWorkoutTemplateCardState
    extends State<ExpandableWorkoutTemplateCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Draggable<Map<String, dynamic>>(
        data: {
          'type': 'template',
          'templateId': widget.template.id,
          'index': widget.index,
        },
        onDragStarted: () {
          HapticFeedback.lightImpact();
          widget.onDragStartedCallback?.call();
        },
        onDragEnd: (details) {
          widget.onDragEndCallback?.call();
        },
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: MediaQuery.of(context).size.width - 32,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _templateColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.template.iconCodePoint != null
                        ? IconData(
                            widget.template.iconCodePoint!,
                            fontFamily: 'MaterialIcons',
                          )
                        : Icons.fitness_center,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.template.name,
                    style: context.appText.titleSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: _buildCard()),
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return GestureDetector(
      onTap: _toggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isExpanded
                ? colorScheme.primary
                : Theme.of(context).dividerColor,
            width: _isExpanded ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _templateColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.template.iconCodePoint != null
                          ? IconData(
                              widget.template.iconCodePoint!,
                              fontFamily: 'MaterialIcons',
                            )
                          : Icons.fitness_center,
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.template.name, style: textTheme.titleSmall),
                        if (widget.template.description != null &&
                            widget.template.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.template.description!,
                              style: textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    if (widget.template.notes != null &&
                        widget.template.notes!.isNotEmpty) ...[
                      Text('Notes', style: textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(widget.template.notes!, style: textTheme.bodyLarge),
                      const SizedBox(height: 12),
                    ],
                    if (widget.template.lastUsed != null) ...[
                      Text('Last Used', style: textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(
                        _formatLastUsed(widget.template.lastUsed!),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onEditPressed,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: widget.onMorePressed,
                          icon: const Icon(Icons.more_vert),
                          color: colors.textSecondary,
                          style: IconButton.styleFrom(
                            backgroundColor: colors.surfaceAlt,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _templateColor(BuildContext context) {
    final templateColorValue = widget.template.colorValue;
    if (templateColorValue == null) {
      return context.appScheme.primary;
    }

    return Workout(
      id: widget.template.id,
      name: widget.template.name,
      colorValue: templateColorValue,
    ).color;
  }

  String _formatLastUsed(String lastUsed) {
    try {
      final date = DateTime.parse(lastUsed);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      }
    } catch (e) {
      return lastUsed;
    }
  }
}
