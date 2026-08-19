import 'dart:ui';
import 'package:flutter/material.dart';

class BlurredModalBackdrop extends StatelessWidget {
  final Widget child;

  /// Intensidad del blur. 6-8 da un efecto sutil de "vidrio esmerilado".
  final double sigma;

  /// Color de superposición sobre el blur (oscurece ligeramente el fondo).
  final Color overlayColor;

  const BlurredModalBackdrop({
    required this.child,
    this.sigma = 6,
    this.overlayColor = const Color(0x1A000000), // negro al 10%
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: sigma * value,
                  sigmaY: sigma * value,
                ),
                child: Container(
                    color:
                        overlayColor.withOpacity(overlayColor.opacity * value)),
              );
            },
          ),
        ),
        child,
      ],
    );
  }
}
