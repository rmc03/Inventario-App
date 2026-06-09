import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/usuario.dart';
import 'indicador_conexion.dart';

class RoleShell extends ConsumerWidget {
  const RoleShell({
    super.key,
    required this.role,
    required this.path,
    required this.child,
  });

  final UserRole role;
  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = role == UserRole.admin ? _adminItems : _dependienteItems;
    final selectedIndex = items.indexWhere((item) => item.path == path);
    final showNavigation = selectedIndex != -1;
    final isRootTab = showNavigation;

    return _PopGuard(
      isRootTab: isRootTab,
      child: Scaffold(
        body: Column(
          children: [
            const IndicadorConexion(),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: showNavigation
            ? SafeArea(
                top: false,
                child: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: (index) => context.go(items[index].path),
                  items: [
                    for (final item in items)
                      BottomNavigationBarItem(
                        icon: Icon(item.icon),
                        activeIcon: Icon(item.activeIcon),
                        label: item.label,
                      ),
                  ],
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

/// Intercepts the system back button on root tabs.
/// Shows "Press again to exit" snackbar; exits only on a second press
/// within [_backExitInterval].
class _PopGuard extends StatefulWidget {
  const _PopGuard({required this.isRootTab, required this.child});

  final bool isRootTab;
  final Widget child;

  @override
  State<_PopGuard> createState() => _PopGuardState();
}

class _PopGuardState extends State<_PopGuard> {
  static const _backExitInterval = Duration(seconds: 2);
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isRootTab,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();
        final last = _lastBackPress;

        if (last != null && now.difference(last) < _backExitInterval) {
          // Second press within interval → exit the app.
          SystemNavigator.pop();
          return;
        }

        _lastBackPress = now;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Presiona atrás otra vez para salir'),
              duration: _backExitInterval,
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: widget.child,
    );
  }
}

class ShellItem {
  const ShellItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _adminItems = [
  ShellItem(
    path: '/admin/inventario',
    label: 'Inventario',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
  ),
  ShellItem(
    path: '/admin/movimientos',
    label: 'Movimientos',
    icon: Icons.swap_vert_circle_outlined,
    activeIcon: Icons.swap_vert_circle,
  ),
  ShellItem(
    path: '/admin/cuadres',
    label: 'Cuadres',
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
  ),
  ShellItem(
    path: '/admin/configuracion',
    label: 'Ajustes',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
  ),
];

const _dependienteItems = [
  ShellItem(
    path: '/dependiente/inventario',
    label: 'Inventario',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
  ),
  ShellItem(
    path: '/dependiente/turno',
    label: 'Mi turno',
    icon: Icons.today_outlined,
    activeIcon: Icons.today,
  ),
];
