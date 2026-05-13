import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FloatingFeedbackToast {
  FloatingFeedbackToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_rounded,
    Color? accentColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    _removeCurrent();

    final overlay = Overlay.of(context, rootOverlay: true);
    final colorScheme = context.appScheme;
    final colors = context.appColors;
    final textTheme = context.appText;
    final highlight = accentColor ?? colors.success;
    final fillColor = Color.alphaBlend(
      highlight.withValues(alpha: 0.08),
      colors.surfaceAlt.withValues(alpha: 0.96),
    );

    final overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final mediaQuery = MediaQuery.of(overlayContext);

        return Positioned(
          left: 24,
          right: 24,
          bottom:
              mediaQuery.viewInsets.bottom + mediaQuery.viewPadding.bottom + 92,
          child: IgnorePointer(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 10),
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    color: colorScheme.surface.withValues(alpha: 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: highlight.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: highlight.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 16, color: highlight),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    _currentEntry = overlayEntry;
    _dismissTimer = Timer(duration, _removeCurrent);
  }

  static void _removeCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
