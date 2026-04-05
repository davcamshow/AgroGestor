import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final BoxShadow? shadow;
  final VoidCallback? onTap;

  const GradientCard({
    required this.child,
    this.gradient = AppTheme.primaryGradient,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.shadow,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
        boxShadow: shadow != null ? [shadow!] : [AppTheme.softShadow],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: widget,
        ),
      );
    }

    return widget;
  }
}
