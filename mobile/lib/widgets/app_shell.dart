import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth/auth_state.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroGestor'),
        backgroundColor: const Color(0xFF064e3b),
        elevation: 0,
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  user.nombre_completo,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      drawer: _buildDrawer(context, ref),
      body: child,
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF064e3b),
            ),
            child: Text(
              'AgroGestor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _drawerItem(
            context,
            icon: Icons.dashboard,
            label: 'Dashboard',
            route: '/dashboard',
          ),
          _drawerItem(
            context,
            icon: Icons.groups,
            label: 'Lotes',
            route: '/lotes',
          ),
          _drawerItem(
            context,
            icon: Icons.restaurant,
            label: 'Fórmulas',
            route: '/formulas',
          ),
          _drawerItem(
            context,
            icon: Icons.inventory,
            label: 'Insumos',
            route: '/insumos',
          ),
          _drawerItem(
            context,
            icon: Icons.assessment,
            label: 'Reportes',
            route: '/reportes',
          ),
          _drawerItem(
            context,
            icon: Icons.settings,
            label: 'Configuración',
            route: '/configuracion',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        context.go(route);
        Navigator.of(context).pop();
      },
    );
  }
}
