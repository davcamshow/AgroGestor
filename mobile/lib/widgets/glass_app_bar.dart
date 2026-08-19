import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// AppBar con efecto "vidrio esmerilado" (glassmorphism): tinte
/// semitransparente + blur sobre el contenido que se desliza detrás.
///
/// Debe usarse junto con `Scaffold(extendBodyBehindAppBar: true)` y el
/// body debe compensar el espacio con [GlassAppBar.contentTopPadding],
/// para que el primer elemento visible no quede oculto bajo la barra.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color tintColor;
  final double blurSigma;
  final Widget? leading;

  const GlassAppBar({
    required this.title,
    this.actions,
    this.bottom,
    this.leading,
    this.tintColor = AppTheme.primary,
    this.blurSigma = 14,
    super.key,
  });

  /// Altura total a reservar en el body (status bar + toolbar + bottom)
  /// para que el contenido inicie justo debajo del AppBar.
  static double contentTopPadding(BuildContext context,
      {double bottomHeight = 0}) {
    return MediaQuery.of(context).padding.top + kToolbarHeight + bottomHeight;
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AppBar(
          title: title,
          actions: actions,
          bottom: bottom,
          leading: leading,
          backgroundColor: tintColor.withOpacity(0.72),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle:
              Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                    color: Colors.white,
                  ),
        ),
      ),
    );
  }
}
