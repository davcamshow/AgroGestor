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
      final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
      return BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: viewInsets),
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

/// Hoja de confirmación con el mismo estilo de pestaña emergente que el
/// resto de hojas de la app. Devuelve `true` si el usuario confirma.
Future<bool?> showBlurConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  IconData icon = Icons.help_outline,
  Color? iconColor,
  Color? confirmColor,
  bool destructive = false,
}) {
  final theme = Theme.of(context);
  final color =
      iconColor ?? (destructive ? AppTheme.error : theme.colorScheme.primary);
  final confirmBg = confirmColor ??
      (destructive ? AppTheme.error : theme.colorScheme.primary);

  return showBlurBottomSheet<bool>(
    context: context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: theme.textTheme.titleLarge),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmBg,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
