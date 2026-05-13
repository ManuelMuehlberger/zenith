import 'package:flutter/material.dart';

/// A small helper widget for animating inserted/removed rows in a SliverAnimatedList.
///
/// We combine a SizeTransition (vertical expand) + FadeTransition.
/// Optionally supports a SlideTransition for "fly in" effects.
class AnimatedInsert extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double axisAlignment;
  final bool slideInFromBottom;

  const AnimatedInsert({
    super.key,
    required this.animation,
    required this.child,
    this.axisAlignment = -1.0,
    this.slideInFromBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    Widget result = FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
      child: SizeTransition(
        sizeFactor: curved,
        axisAlignment: axisAlignment,
        child: child,
      ),
    );

    if (slideInFromBottom) {
      result = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.0), // Start from below
          end: Offset.zero,
        ).animate(curved),
        child: result,
      );
    }

    return result;
  }
}
