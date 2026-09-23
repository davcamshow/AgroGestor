import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/notificaciones_provider.dart';
import '../../core/theme/app_theme.dart';

class NotificacionesScreen extends ConsumerWidget {
  const NotificacionesScreen({super.key});

  IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'evento_sanitario':
        return Icons.vaccines_outlined;
      case 'parto_proximo':
        return Icons.favorite_outline;
      case 'stock_bajo':
        return Icons.inventory_2_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificacionesNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Paleta adaptada según el modo activo
    final backgroundColor =
        isDark ? AppTheme.darkBackground : AppTheme.background;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final textPrimaryColor = isDark ? AppTheme.darkTextPrimary : Colors.black87;
    final textSecondaryColor =
        isDark ? AppTheme.darkTextSecondary : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primary,
        foregroundColor: isDark ? AppTheme.darkTextPrimary : Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificacionesNotifierProvider.notifier)
                .marcarTodasLeidas(),
            child: Text(
              'Marcar todas',
              style: TextStyle(
                color: isDark ? AppTheme.darkPrimary : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        onRefresh: () async => ref.invalidate(notificacionesNotifierProvider),
        child: notifsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
          error: (err, _) => Center(
            child: Text(
              'Error: $err',
              style: TextStyle(
                  color: isDark ? AppTheme.darkError : AppTheme.error),
            ),
          ),
          data: (notifs) {
            if (notifs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 56,
                      color: textSecondaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin notificaciones pendientes',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifs.length,
              itemBuilder: (context, index) {
                final n = notifs[index];

                // Fondo de tarjeta según estado de lectura y modo
                final cardColor = n.leida
                    ? (isDark ? AppTheme.darkSurface : Colors.white)
                    : (isDark
                        ? AppTheme.darkSurfaceVariant
                        : AppTheme.secondary.withOpacity(0.12));

                final badgeColor = isDark
                    ? (n.leida
                        ? AppTheme.darkSurfaceVariant
                        : AppTheme.darkPrimary.withOpacity(0.2))
                    : (n.leida
                        ? AppTheme.background
                        : AppTheme.primary.withOpacity(0.1));

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      AppTheme.softShadowFor(
                        isDark ? Brightness.dark : Brightness.light,
                      ),
                    ],
                    border: Border.all(
                      color: !n.leida
                          ? primaryColor.withOpacity(0.35)
                          : (isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.05)),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        if (!n.leida) {
                          ref
                              .read(notificacionesNotifierProvider.notifier)
                              .marcarLeida(n.id);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _iconoPorTipo(n.tipo),
                                color: primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n.titulo,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: n.leida
                                                ? FontWeight.w500
                                                : FontWeight.bold,
                                            color: textPrimaryColor,
                                          ),
                                        ),
                                      ),
                                      if (!n.leida)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin:
                                              const EdgeInsets.only(left: 6),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.mensaje,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: textSecondaryColor,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('dd/MM HH:mm')
                                        .format(n.fechaCreacion),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          textSecondaryColor.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
