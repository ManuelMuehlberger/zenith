import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: context.appColors.transparent,
    builder: builder,
  );
}

// policy: allow-public-api shared bottom-sheet shell reused by exercise flows.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    this.height,
    this.maxHeight,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 12),
    required this.child,
  });

  final double? height;
  final double? maxHeight;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;

    final sheet = Container(
      height: height,
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
        padding: padding.add(
          EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        ),
        child: child,
      ),
    );

    if (maxHeight == null) {
      return sheet;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight!),
      child: sheet,
    );
  }
}

// policy: allow-public-api shared bottom-sheet drag handle for sheet headers.
class AppBottomSheetHandle extends StatelessWidget {
  const AppBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;

    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: scheme.outline.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

// policy: allow-public-api shared single-select option tile for bottom sheets.
class AppBottomSheetOptionTile extends StatelessWidget {
  const AppBottomSheetOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

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
                    color: selected ? scheme.primary : colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, size: 20, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
