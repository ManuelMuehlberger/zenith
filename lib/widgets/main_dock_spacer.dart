import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MainDockSpacer extends StatelessWidget {
  const MainDockSpacer({super.key, this.extraSpace = 0});

  final double extraSpace;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: safeBottom + AppTheme.mainDockClearance + extraSpace,
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
