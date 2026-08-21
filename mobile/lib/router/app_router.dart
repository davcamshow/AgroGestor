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
import '../screens/reproduccion/registro_nacimiento_screen.dart';
import '../screens/reproduccion/kpis_reproduccion_screen.dart';
import '../screens/reproduccion/arbol_genealogico_screen.dart';
import '../screens/reproduccion/calculadora_ia_screen.dart';
import '../screens/reproduccion/temporadas_screen.dart';
import '../screens/alimentacion/alimentacion_screen.dart';
import '../screens/alimentacion/calculadora_screen.dart';
import '../screens/alimentacion/reporte_consumo_screen.dart';
import '../screens/alimentacion/alertas_stock_screen.dart';
import '../screens/planes/planes_screen.dart';
import '../widgets/app_shell.dart';
import '../screens/clima/ubicacion_rancho_screen.dart';
import '../screens/salud/salud_screen.dart';

/// Duración estándar para las transiciones de pantalla en toda la app.
const Duration _kTransitionDuration = Duration(milliseconds: 320);

/// Construye una [CustomTransitionPage] con fade + slide sutil.
///
/// Se usa en lugar de `builder:` en cada [GoRoute] para lograr
/// transiciones consistentes en toda la app sin modificar las pantallas.
CustomTransitionPage<void> _fadeSlidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _kTransitionDuration,
    reverseTransitionDuration: _kTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Transición para pantallas dentro del bottom nav (tabs): solo fade,
/// sin slide horizontal, ya que van y vienen entre ramas del shell.
CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _kTransitionDuration,
    reverseTransitionDuration: _kTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus =
      ref.watch(authProvider.select((AuthState state) => state.status));

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authStatus == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      // Still loading
      if (authStatus == AuthStatus.unknown) return null;

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
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const RegisterScreen()),
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
                pageBuilder: (context, state) =>
                    _fadePage(state: state, child: const DashboardScreen()),
              ),
            ],
          ),
          // Tab 1: Animales
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/animales',
                name: 'animales',
                pageBuilder: (context, state) =>
                    _fadePage(state: state, child: const AnimalesScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'animal-detail',
                    pageBuilder: (context, state) => _fadeSlidePage(
                      state: state,
                      child: AnimalDetailScreen(
                        animalId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Tab 2: Reproducción
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reproduccion',
                name: 'reproduccion',
                pageBuilder: (context, state) =>
                    _fadePage(state: state, child: const ReproduccionScreen()),
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
                pageBuilder: (context, state) =>
                    _fadePage(state: state, child: const AlimentacionScreen()),
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
                pageBuilder: (context, state) =>
                    _fadePage(state: state, child: const SaludScreen()),
              ),
            ],
          ),
        ],
      ),
      // Rutas secundarias (fuera del shell)
      GoRoute(
        path: '/clima/ubicacion',
        name: 'clima-ubicacion',
        builder: (_, __) => const UbicacionRanchoScreen(),
      ),
      GoRoute(
        path: '/lotes',
        name: 'lotes',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const LotesScreen()),
      ),
      GoRoute(
        path: '/lotes/new',
        name: 'lote-new',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const LoteFormScreen()),
      ),
      GoRoute(
        path: '/lotes/:id/edit',
        name: 'lote-edit',
        pageBuilder: (context, state) => _fadeSlidePage(
          state: state,
          child: LoteFormScreen(loteId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/formulas',
        name: 'formulas',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const FormulasScreen()),
      ),
      GoRoute(
        path: '/formulas/builder',
        name: 'formula-builder',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const FormulaBuilderScreen()),
      ),
      GoRoute(
        path: '/insumos',
        name: 'insumos',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const InsumosScreen()),
      ),
      GoRoute(
        path: '/reportes',
        name: 'reportes',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const ReportesScreen()),
      ),
      GoRoute(
        path: '/configuracion',
        name: 'configuracion',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const ConfiguracionScreen()),
      ),
    ],
  );
});
