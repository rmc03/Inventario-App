import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/configuracion/presentation/accesibilidad_screen.dart';
import '../../features/configuracion/presentation/categorias_screen.dart';
import '../../features/configuracion/presentation/configuracion_screen.dart';
import '../../features/configuracion/presentation/equipo_screen.dart';
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
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      // Leer (no watch) el estado actual en cada evaluación de redirect.
      final user = ref.read(authControllerProvider).user;
      final path = state.uri.path;
      final isLogin = path == '/login';

      if (user == null) {
        return isLogin ? null : '/login';
      }

      if (isLogin || path == '/') {
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
            builder: (context, state) => const ProductoFormScreen(),
          ),
          GoRoute(
            path: '/admin/inventario/productos/:id',
            builder: (context, state) =>
                ProductoDetalleScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/inventario/productos/:id/editar',
            builder: (context, state) =>
                ProductoFormScreen(productId: state.pathParameters['id']),
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
            builder: (context, state) {
              final venta = state.extra as Venta;
              return VentaDetalleScreen(venta: venta);
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
            builder: (context, state) =>
                CuadreDetalleScreen(cuadreId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/configuracion',
            builder: (context, state) => const ConfiguracionScreen(isAdmin: true),
          ),
          GoRoute(
            path: '/admin/configuracion/accesibilidad',
            builder: (context, state) => const AccesibilidadScreen(),
          ),
          GoRoute(
            path: '/admin/configuracion/equipo',
            builder: (context, state) => const EquipoScreen(),
          ),
          GoRoute(
            path: '/admin/configuracion/categorias',
            builder: (context, state) => const CategoriasScreen(),
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
            builder: (context, state) => ProductoDetalleScreen(
              productId: state.pathParameters['id']!,
              isAdmin: false,
            ),
          ),
          GoRoute(
            path: '/dependiente/turno',
            builder: (context, state) => const MiTurnoScreen(),
          ),
          GoRoute(
            path: '/dependiente/turno/resumen',
            builder: (context, state) => const CuadreResumenScreen(),
          ),
          GoRoute(
            path: '/dependiente/turno/nueva-venta',
            builder: (context, state) => const NuevaVentaScreen(),
          ),
          GoRoute(
            path: '/dependiente/turno/confirmar-pago',
            builder: (context, state) => const ConfirmarPagoScreen(),
          ),
          GoRoute(
            path: '/dependiente/turno/venta/:id',
            builder: (context, state) {
              final venta = state.extra as Venta;
              return VentaDetalleScreen(venta: venta);
            },
          ),
          GoRoute(
            path: '/dependiente/cuadres/historial',
            builder: (context, state) => const CuadresHistorialScreen(),
          ),
          GoRoute(
            path: '/dependiente/configuracion',
            builder: (context, state) => const ConfiguracionScreen(isAdmin: false),
          ),
          GoRoute(
            path: '/dependiente/configuracion/accesibilidad',
            builder: (context, state) => const AccesibilidadScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(uri: state.uri.path),
  );
});
