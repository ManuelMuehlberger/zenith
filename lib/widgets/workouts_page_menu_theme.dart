import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../theme/app_theme.dart';

PullDownButtonTheme buildWorkoutsPageMenuTheme(BuildContext context) {
  final colors = context.appColors;
  final textTheme = context.appText;
  final backgroundColor = Theme.of(
    context,
  ).colorScheme.surface.withValues(alpha: 0.98);

  return PullDownButtonTheme(
    routeTheme: PullDownMenuRouteTheme(
      backgroundColor: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      shadow: BoxShadow(
        color: colors.shadow.withValues(alpha: 0.16),
        blurRadius: 30,
        spreadRadius: 3,
        offset: const Offset(0, 2),
      ),
      width: 224,
      accessibilityWidth: 280,
    ),
    itemTheme: PullDownMenuItemTheme(
      destructiveColor: Theme.of(context).colorScheme.error,
      textStyle: textTheme.bodyLarge?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      subtitleStyle: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      iconActionTextStyle: textTheme.labelMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      onHoverBackgroundColor: colors.field.withValues(alpha: 0.9),
      onPressedBackgroundColor: colors.field,
      onHoverTextColor: colors.textPrimary,
    ),
  );
}

Widget buildWorkoutsPageMenuWrapper(
  BuildContext context, {
  required Widget child,
}) {
  return PullDownButtonInheritedTheme(
    data: buildWorkoutsPageMenuTheme(context),
    child: child,
  );
}
