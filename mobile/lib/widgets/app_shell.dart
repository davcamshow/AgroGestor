import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth/auth_state.dart';
import '../core/theme/app_theme.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/sync_service.dart';
import '../core/providers/sync_provider.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({required this.navigationShell, super.key});

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Animales';
      case 2:
        return 'Reproducción';
      case 3:
        return 'Alimentación';
      case 4:
        return 'Salud';
      case 5:
        return 'Suscripción';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // BP-159: banner de estado de conexión/sincronización, visible en
    // cualquier pantalla de la app (arriba del contenido, debajo del AppBar
    // de cada pantalla).
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    final syncStatus = ref.watch(syncStatusProvider).valueOrNull;

    Widget? banner;
    if (!isOnline) {
      banner = const _StatusBanner(
        icon: Icons.cloud_off,
        message: 'Sin conexión — los cambios se guardan localmente',
        color: AppTheme.warning,
      );
    } else if (syncStatus == SyncStatus.syncing) {
      banner = const _StatusBanner(
        icon: Icons.sync,
        message: 'Sincronizando cambios pendientes...',
        color: AppTheme.info,
      );
    }

    return Scaffold(
      body: Column(
        children: [
          if (banner != null) banner,
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        onTap: navigationShell.goBranch,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Animales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Reproducción',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grass),
            label: 'Alimentación',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Salud',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium),
            label: 'Suscripción',
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
