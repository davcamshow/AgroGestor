import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_mode_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isSystemMode = themeMode == ThemeMode.system;
    final isDarkMode = themeMode == ThemeMode.dark ||
        (isSystemMode &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    // Ícono + color según el modo actual:
    // - Sistema: ícono neutro "auto" (independiente de si el resultado es claro u oscuro)
    // - Explícito claro/oscuro: sol / luna, como antes
    final IconData icon;
    final Color iconColor;
    if (isSystemMode) {
      icon = Icons.brightness_auto_rounded;
      iconColor = Colors.lightBlueAccent;
    } else if (isDarkMode) {
      icon = Icons.nightlight_round;
      iconColor = Colors.amberAccent;
    } else {
      icon = Icons.wb_sunny_rounded;
      iconColor = Colors.orange;
    }

    return Tooltip(
      message: isSystemMode
          ? 'Siguiendo el tema del sistema\nMantén presionado para cambiar'
          : 'Toca para cambiar de tema\nMantén presionado para usar el del sistema',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efecto Blur
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              // Tap: alterna entre claro y oscuro explícitamente
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(
                      isDarkMode ? ThemeMode.light : ThemeMode.dark,
                    );
              },
              // Mantener presionado: vuelve a seguir el tema del sistema
              onLongPress: () {
                ref.read(themeModeProvider.notifier).setThemeMode(
                      ThemeMode.system,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ahora sigues el tema del sistema'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    // Animación de rotación y desvanecimiento suave
                    return RotationTransition(
                      turns: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    icon,
                    key: ValueKey<IconData>(icon),
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
