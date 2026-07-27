import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/configuracion/presentation/accesibilidad_screen.dart';
import '../../features/configuracion/presentation/categorias_screen.dart';
import '../../features/configuracion/presentation/configuracion_screen.dart';
import '../../features/configuracion/presentation/equipo_screen.dart';
import '../../features/configuracion/presentation/temas_screen.dart';
import '../../features/cuadres/presentation/cuadre_detalle_screen.dart';
import '../../features/cuadres/presentation/cuadres_screen.dart';
import '../../features/cuadres/presentation/cuadres_historial_screen.dart';
import '../../features/inventario/presentation/inventario_screen.dart';
import '../../features/inventario/presentation/producto_detalle_screen.dart';
import '../../features/inventario/presentation/producto_form_screen.dart';
import '../../features/movimientos/presentation/movimientos_screen.dart';
import '../../features/resumen/presentation/resumen_screen.dart';
import '../../features/turno/presentation/cuadre_resumen_screen.dart';
import '../../features/turno/presentation/mi_turno_screen.dart';
import '../../features/ventas/presentation/nueva_venta_screen.dart';
import '../../features/ventas/presentation/confirmar_pago_screen.dart';
import '../../features/ventas/presentation/venta_detalle_screen.dart';
import '../../shared/models/venta.dart';
import '../../shared/widgets/error_page.dart';
import '../../shared/models/usuario.dart';
import '../../shared/widgets/role_shell.dart';

/// Transición personalizada que solo anima el contenido, no el AppBar
Page<void> _buildPageWithFadeTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Transición casi instantánea para evitar bugs visuales
      // Solo un fade muy rápido
      const begin = 0.0;
      const end = 1.0;
      const curve = Curves.easeOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var opacityAnimation = animation.drive(tween);

      return FadeTransition(
        opacity: opacityAnimation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 150),  // Más rápido
    reverseTransitionDuration: const Duration(milliseconds: 150),
  );
}

/// Transición para Mi Turno: fade + slide sutil hacia arriba.
/// Se diferencia del fade genérico para dar continuidad visual
/// cuando se regresa desde Confirmar Pago (context.go).
Page<void> _buildTurnoTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slide = Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(curved);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
  );
}

/// Notifica a GoRouter cuando el estado de autenticación cambia,
/// sin necesidad de recrear la instancia del router.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen<AuthState>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // El notifier escucha cambios de auth y dispara refreshListenable.
  // GoRouter NO se recrea: solo re-evalúa su función redirect.
  final notifier = _AuthNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) async {
      // Leer (no watch) el estado actual en cada evaluación de redirect.
      final user = ref.read(authControllerProvider).user;
      final path = state.uri.path;
      final isOnboarding = path == '/onboarding';
      final isLogin = path == '/login';
      final isRoot = path == '/';

      // Check if onboarding is completed
      if (isRoot) {
        final shouldShowOnboarding = await ref.read(shouldShowOnboardingProvider.future);
        if (shouldShowOnboarding) {
          return '/onboarding';
        }
        return user == null ? '/login' : user.rol.homePath;
      }

      // Allow onboarding route
      if (isOnboarding) {
        return null;
      }

      if (user == null) {
        return isLogin ? null : '/login';
      }

      if (isLogin) {
        return user.rol.homePath;
      }

      if (path.startsWith('/admin') && user.rol != UserRole.admin) {
        return user.rol.homePath;
      }

      if (path.startsWith('/dependiente') && user.rol != UserRole.dependiente) {
        return user.rol.homePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          context,
          state,
          const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          context,
          state,
          const LoginScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            RoleShell(role: UserRole.admin, path: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/admin/resumen',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const ResumenScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/inventario',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const InventarioScreen(isAdmin: true),
            ),
          ),
          GoRoute(
            path: '/admin/inventario/productos/nuevo',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const ProductoFormScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/inventario/productos/:id',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              ProductoDetalleScreen(productId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/admin/inventario/productos/:id/editar',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              ProductoFormScreen(productId: state.pathParameters['id']),
            ),
          ),
          GoRoute(
            path: '/admin/movimientos',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const MovimientosScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/movimientos/ventas/:id',
            pageBuilder: (context, state) {
              final venta = state.extra as Venta;
              return _buildPageWithFadeTransition(
                context,
                state,
                VentaDetalleScreen(venta: venta),
              );
            },
          ),
          GoRoute(
            path: '/admin/cuadres',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const CuadresScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/cuadres/:id',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              CuadreDetalleScreen(cuadreId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/admin/configuracion',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const ConfiguracionScreen(isAdmin: true),
            ),
          ),
          GoRoute(
            path: '/admin/configuracion/accesibilidad',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const AccesibilidadScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/configuracion/equipo',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const EquipoScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/configuracion/categorias',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const CategoriasScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/configuracion/temas',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const TemasScreen(),
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => RoleShell(
          role: UserRole.dependiente,
          path: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dependiente/inventario',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const InventarioScreen(isAdmin: false),
            ),
          ),
          GoRoute(
            path: '/dependiente/inventario/productos/:id',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              ProductoDetalleScreen(
                productId: state.pathParameters['id']!,
                isAdmin: false,
              ),
            ),
          ),
          GoRoute(
            path: '/dependiente/turno',
            pageBuilder: (context, state) => _buildTurnoTransition(
              context,
              state,
              const MiTurnoScreen(),
            ),
          ),
          GoRoute(
            path: '/dependiente/turno/resumen',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const CuadreResumenScreen(),
            ),
          ),
          GoRoute(
            path: '/dependiente/turno/nueva-venta',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const NuevaVentaScreen(),
            ),
          ),
          GoRoute(
            path: '/dependiente/turno/confirmar-pago',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const ConfirmarPagoScreen(),
            ),
          ),
          GoRoute(
            path: '/dependiente/turno/venta/:id',
            pageBuilder: (context, state) {
              final venta = state.extra as Venta;
              return _buildPageWithFadeTransition(
                context,
                state,
                VentaDetalleScreen(venta: venta),
              );
            },
          ),
          GoRoute(
            path: '/dependiente/cuadres/historial',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const CuadresHistorialScreen(),
            ),
          ),
          GoRoute(
            path: '/dependiente/configuracion',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const ConfiguracionScreen(isAdmin: false),
            ),
          ),
          GoRoute(
            path: '/dependiente/configuracion/accesibilidad',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const AccesibilidadScreen(),
            ),
          ),
          GoRoute(
            path: '/dependiente/configuracion/temas',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const TemasScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(uri: state.uri.path),
  );
});
