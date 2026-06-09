import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/configuracion/presentation/configuracion_screen.dart';
import '../../features/cuadres/presentation/cuadre_detalle_screen.dart';
import '../../features/cuadres/presentation/cuadres_screen.dart';
import '../../features/inventario/presentation/inventario_screen.dart';
import '../../features/inventario/presentation/producto_detalle_screen.dart';
import '../../features/inventario/presentation/producto_form_screen.dart';
import '../../features/movimientos/presentation/movimientos_screen.dart';
import '../../features/turno/presentation/cuadre_resumen_screen.dart';
import '../../features/turno/presentation/mi_turno_screen.dart';
import '../../shared/models/usuario.dart';
import '../../shared/widgets/role_shell.dart';

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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            RoleShell(role: UserRole.admin, path: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/admin/inventario',
            builder: (context, state) => const InventarioScreen(isAdmin: true),
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
            builder: (context, state) => const MovimientosScreen(),
          ),
          GoRoute(
            path: '/admin/cuadres',
            builder: (context, state) => const CuadresScreen(),
          ),
          GoRoute(
            path: '/admin/cuadres/:id',
            builder: (context, state) =>
                CuadreDetalleScreen(cuadreId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/configuracion',
            builder: (context, state) => const ConfiguracionScreen(),
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
            builder: (context, state) => const InventarioScreen(isAdmin: false),
          ),
          GoRoute(
            path: '/dependiente/turno',
            builder: (context, state) => const MiTurnoScreen(),
          ),
          GoRoute(
            path: '/dependiente/turno/resumen',
            builder: (context, state) => const CuadreResumenScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri.path}')),
    ),
  );
});
