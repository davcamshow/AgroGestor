import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

Future<T?> showBlurBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  double? height,
  double? maxHeight,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    useRootNavigator: false,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, anim1, anim2) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: height,
            constraints: maxHeight != null
                ? BoxConstraints(maxHeight: maxHeight)
                : null,
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.darkSurface : Colors.white)
                  .withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: child,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim, secondary, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}