import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

import '../theme/app_theme.dart';

class MainDockSpacer extends StatelessWidget {
  const MainDockSpacer({super.key, this.extraSpace = 0});

  final double extraSpace;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final fallbackHeight = safeBottom + AppTheme.mainDockClearance + extraSpace;
    final scope = BottomBarScope.maybeOf(context);

    if (scope == null) {
      return SizedBox(height: fallbackHeight);
    }

    return ValueListenableBuilder<double>(
      valueListenable: scope.barHeight,
      builder: (context, barHeight, _) {
        final effectiveDockHeight = barHeight > 0
            ? barHeight + AppTheme.mainDockOffset
            : AppTheme.mainDockClearance;

        return SizedBox(height: safeBottom + effectiveDockHeight + extraSpace);
      },
    );
  }
}

class MainDockSpacerSliver extends StatelessWidget {
  const MainDockSpacerSliver({super.key, this.extraSpace = 0});

  final double extraSpace;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: MainDockSpacer(extraSpace: extraSpace));
  }
}
