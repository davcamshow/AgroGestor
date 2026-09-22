import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_mode_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final (IconData icon, Color iconColor, String tooltipMsg) =
        switch (themeMode) {
      ThemeMode.system => (
          Icons.brightness_auto_rounded,
          Colors.lightBlueAccent,
          'Tema: Sistema (Automático)\nToca para cambiar a Claro',
        ),
      ThemeMode.light => (
          Icons.wb_sunny_rounded,
          Colors.orange,
          'Tema: Claro\nToca para cambiar a Oscuro',
        ),
      ThemeMode.dark => (
          Icons.nightlight_round,
          Colors.amberAccent,
          'Tema: Oscuro\nToca para volver al Sistema',
        ),
    };

    return Tooltip(
      message: tooltipMsg,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              // Al tocar, rota y guarda el nuevo estado en storage
              onTap: () {
                ref.read(themeModeProvider.notifier).cycleTheme();
              },
              // Si mantienes presionado, restablece y guarda directo en Sistema
              onLongPress: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tema fijado en Automático (Sistema)'),
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
