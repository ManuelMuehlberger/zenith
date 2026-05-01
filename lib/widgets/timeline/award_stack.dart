import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;

import '../../theme/app_theme.dart';

/// Simple award model for the timeline card.
///
/// This is intentionally UI-focused for now; it can later be backed by
/// a richer domain model.
class Award {
  final String title;
  final IconData icon;
  final Color? color;

  const Award({required this.title, required this.icon, this.color});
}

/// Stacked award icons (up to 3 visible) that opens a Cupertino modal
/// listing all awards on tap.
class AwardStack extends StatelessWidget {
  final List<Award> awards;
  final double iconSize;
  final double horizontalOffset;

  const AwardStack({
    super.key,
    required this.awards,
    this.iconSize = 24,
    this.horizontalOffset = 15,
  });

  @override
  Widget build(BuildContext context) {
    if (awards.isEmpty) return const SizedBox.shrink();

    final visible = awards.take(3).toList(growable: false);
    final width = iconSize + (visible.length - 1) * horizontalOffset;

    return CupertinoContextMenu(
      actions: [
        for (final award in awards)
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
            },
            trailingIcon: award.icon,
            child: Text(award.title),
          ),
      ],
      child: SizedBox(
        width: width,
        height: iconSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < visible.length; i++)
              Positioned(
                left: i * horizontalOffset,
                child: _AwardIcon(award: visible[i], size: iconSize),
              ),
          ],
        ),
      ),
    );
  }
}

class _AwardIcon extends StatelessWidget {
  final Award award;
  final double size;

  const _AwardIcon({required this.award, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = context.appScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.field,
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Center(
        child: Icon(
          award.icon,
          color: award.color ?? scheme.primary,
          size: size * 0.62,
        ),
      ),
    );
  }
}
