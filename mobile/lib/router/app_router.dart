import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth/auth_state.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/lotes/lotes_screen.dart';
import '../screens/lotes/lote_form_screen.dart';
import '../screens/formulas/formulas_screen.dart';
import '../screens/formulas/formula_builder_screen.dart';
import '../screens/insumos/insumos_screen.dart';
import '../screens/reportes/reportes_screen.dart';
import '../screens/configuracion/configuracion_screen.dart';
import '../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      // Still loading
      if (authState.status == AuthStatus.unknown) return null;

      // Not authenticated
      if (!isAuth && !isAuthRoute) return '/login';

      // Authenticated but on auth route
      if (isAuth && isAuthRoute) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/lotes',
            name: 'lotes',
            builder: (_, __) => const LotesScreen(),
          ),
          GoRoute(
            path: '/lotes/new',
            name: 'lote-new',
            builder: (_, __) => const LoteFormScreen(),
          ),
          GoRoute(
            path: '/lotes/:id/edit',
            name: 'lote-edit',
            builder: (context, state) => LoteFormScreen(
              loteId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/formulas',
            name: 'formulas',
            builder: (_, __) => const FormulasScreen(),
          ),
          GoRoute(
            path: '/formulas/builder',
            name: 'formula-builder',
            builder: (_, __) => const FormulaBuilderScreen(),
          ),
          GoRoute(
            path: '/insumos',
            name: 'insumos',
            builder: (_, __) => const InsumosScreen(),
          ),
          GoRoute(
            path: '/reportes',
            name: 'reportes',
            builder: (_, __) => const ReportesScreen(),
          ),
          GoRoute(
            path: '/configuracion',
            name: 'configuracion',
            builder: (_, __) => const ConfiguracionScreen(),
          ),
        ],
      ),
    ],
  );
});
