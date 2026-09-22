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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificacionesNotifierProvider.notifier)
                .marcarTodasLeidas(),
            child: const Text('Marcar todas',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificacionesNotifierProvider),
        child: notifsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (notifs) {
            if (notifs.isEmpty) {
              return const Center(child: Text('Sin notificaciones'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              itemBuilder: (context, index) {
                final n = notifs[index];
                return Card(
                  color: n.leida ? null : AppTheme.secondary.withOpacity(0.08),
                  child: ListTile(
                    leading:
                        Icon(_iconoPorTipo(n.tipo), color: AppTheme.primary),
                    title: Text(n.titulo,
                        style: TextStyle(
                          fontWeight:
                              n.leida ? FontWeight.normal : FontWeight.bold,
                        )),
                    subtitle: Text(n.mensaje),
                    trailing: Text(
                      DateFormat('dd/MM HH:mm').format(n.fechaCreacion),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    onTap: () {
                      if (!n.leida) {
                        ref
                            .read(notificacionesNotifierProvider.notifier)
                            .marcarLeida(n.id);
                      }
                    },
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
