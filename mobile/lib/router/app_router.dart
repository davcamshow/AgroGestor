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
import '../screens/animales/animales_screen.dart';
import '../screens/animales/animal_detail_screen.dart';
import '../screens/reproduccion/reproduccion_screen.dart';
import '../screens/salud/salud_screen.dart';
import '../screens/alimentacion/alimentacion_screen.dart';
import '../screens/alimentacion/calculadora_screen.dart';
import '../screens/reproduccion/reproduccion_screen.dart';
import '../screens/reproduccion/registro_nacimiento_screen.dart';
import '../screens/reproduccion/kpis_reproduccion_screen.dart';
import '../screens/reproduccion/arbol_genealogico_screen.dart';
import '../screens/reproduccion/calculadora_ia_screen.dart';
import '../screens/reproduccion/temporadas_screen.dart';
import '../screens/alimentacion/calculadora_screen.dart';
import '../screens/alimentacion/reporte_consumo_screen.dart';
import '../screens/alimentacion/alertas_stock_screen.dart';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Dashboard/Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 1: Animales
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/animales',
                name: 'animales',
                builder: (_, __) => const AnimalesScreen(),
              ),
              GoRoute(
                path: '/animales/:id',
                name: 'animal-detail',
                builder: (context, state) => AnimalDetailScreen(
                  animalId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          // Tab 2: Reproducción
          StatefulShellBranch(
            routes: [
GoRoute(
        path: '/reproduccion',
        name: 'reproduccion',
        builder: (_, __) => const ReproduccionScreen(),
      ),
      GoRoute(
        path: '/reproduccion/nacimiento',
        name: 'registro-nacimiento',
        builder: (context, state) => RegistroNacimientoScreen(
          cicloId: state.uri.queryParameters['ciclo'],
        ),
      ),
      GoRoute(
        path: '/reproduccion/kpis',
        name: 'kpis-reproduccion',
        builder: (_, __) => const KPIsReproduccionScreen(),
      ),
      GoRoute(
        path: '/reproduccion/arbol/:animalId',
        name: 'arbol-genealogico',
        builder: (context, state) => ArbolGenealogicoScreen(
          animalId: int.parse(state.pathParameters['animalId']!),
        ),
      ),
      GoRoute(
        path: '/reproduccion/calculadora-ia',
        name: 'calculadora-ia',
        builder: (_, __) => const CalculadoraIAScreen(),
      ),
      GoRoute(
        path: '/reproduccion/temporadas',
        name: 'temporadas',
        builder: (_, __) => const TemporadasScreen(),
      ),
            ],
          ),
          // Tab 3: Alimentación
          StatefulShellBranch(
            routes: [
GoRoute(
        path: '/alimentacion',
        name: 'alimentacion',
        builder: (_, __) => const AlimentacionScreen(),
      ),
      GoRoute(
        path: '/alimentacion/calculadora',
        name: 'calculadora',
        builder: (_, __) => const CalculadoraScreen(),
      ),
      GoRoute(
        path: '/alimentacion/reporte',
        name: 'reporte-consumo',
        builder: (_, __) => const ReporteConsumoScreen(),
      ),
      GoRoute(
        path: '/alimentacion/alertas',
        name: 'alertas-stock',
        builder: (_, __) => const AlertasStockScreen(),
      ),
            ],
          ),
          // Tab 4: Salud
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/salud',
                name: 'salud',
                builder: (_, __) => const SaludScreen(),
              ),
            ],
          ),
        ],
      ),
      // Rutas secundarias (fuera del shell)
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
  );
});
