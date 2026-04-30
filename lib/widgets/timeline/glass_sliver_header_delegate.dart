import 'dart:ui';

import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// A pinned sliver header with a frosted glass blur that allows content
/// to scroll under it.
class GlassSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  /// The top safe-area padding (i.e., status bar height).
  final double topPadding;

  /// Height excluding [topPadding]. Typically `kToolbarHeight + extra`.
  final double expandedHeight;
  final Widget smallTitle;
  final Widget largeTitle;
  final Widget trailing;

  GlassSliverHeaderDelegate({
    required this.topPadding,
    required this.expandedHeight,
    required this.smallTitle,
    required this.largeTitle,
    required this.trailing,
  });

  @override
  double get minExtent => topPadding + kToolbarHeight;

  @override
  double get maxExtent => topPadding + expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppConstants.GLASS_BLUR_SIGMA,
              sigmaY: AppConstants.GLASS_BLUR_SIGMA,
            ),
            child: Container(
              color: Color.lerp(
                AppConstants.HEADER_BG_COLOR_MEDIUM,
                AppConstants.HEADER_BG_COLOR_STRONG,
                t,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Column(
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: kToolbarHeight),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: smallTitle,
                      ),
                    ),
                    SizedBox(
                      width: kToolbarHeight,
                      child: Center(child: trailing),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IgnorePointer(
                  ignoring: t > 0.98,
                  child: Opacity(
                    opacity: 1.0 - t,
                    child: Center(child: largeTitle),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant GlassSliverHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.smallTitle != smallTitle ||
        oldDelegate.largeTitle != largeTitle ||
        oldDelegate.trailing != trailing;
  }
}
