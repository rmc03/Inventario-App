import 'dart:async';
import 'dart:ui';

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
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: SafeArea(
                    top: false,
                    child: BottomNavigationBar(
                      currentIndex: selectedIndex,
                      onTap: (index) => context.go(items[index].path),
                      type: BottomNavigationBarType.fixed,
                      selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      items: [
                        for (final item in items)
                          BottomNavigationBarItem(
                            icon: Icon(item.icon),
                            activeIcon: Icon(item.activeIcon),
                            label: item.label,
                          ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

/// Intercepts Android back presses on root tabs.
/// First press shows a confirmation; second press exits only if repeated quickly.
///
/// Uses [ChildBackButtonDispatcher] instead of [PopScope] because PopScope
/// registers at the ModalRoute level, which is *below* GoRouter's own back
/// handling.  After a push/pop cycle inside a ShellRoute, GoRouter intercepts
/// the back button before PopScope can respond.  A ChildBackButtonDispatcher
/// with [takePriority] fires at the Router level — above GoRouter — so the
/// double-tap-to-exit logic works reliably regardless of navigation history.
class _PopGuard extends StatefulWidget {
  const _PopGuard({required this.isRootTab, required this.child});

  final bool isRootTab;
  final Widget child;

  @override
  State<_PopGuard> createState() => _PopGuardState();
}

class _PopGuardState extends State<_PopGuard> {
  static const _backExitInterval = Duration(seconds: 2);

  ChildBackButtonDispatcher? _backDispatcher;
  bool _exitOnNextBack = false;
  Timer? _exitTimer;

  // ── lifecycle ───────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDispatcher();
  }

  @override
  void didUpdateWidget(covariant _PopGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRootTab != oldWidget.isRootTab) {
      _exitOnNextBack = false;
      _exitTimer?.cancel();
      _syncDispatcher();
    }
  }

  @override
  void dispose() {
    _removeDispatcher();
    _exitTimer?.cancel();
    super.dispose();
  }

  // ── dispatcher management ───────────────────────────────────────────────

  void _syncDispatcher() {
    if (widget.isRootTab) {
      _ensureDispatcher();
    } else {
      _removeDispatcher();
    }
  }

  void _ensureDispatcher() {
    if (_backDispatcher != null) {
      // Already registered — just re-assert priority so it stays on top
      // after any GoRouter internal changes.
      _backDispatcher!.takePriority();
      return;
    }

    final root = Router.of(context).backButtonDispatcher;
    if (root == null) return;

    _backDispatcher = root.createChildBackButtonDispatcher()
      ..addCallback(_handleBack)
      ..takePriority();
  }

  void _removeDispatcher() {
    _backDispatcher?.removeCallback(_handleBack);
    _backDispatcher = null;
  }

  // ── back button handler ─────────────────────────────────────────────────

  Future<bool> _handleBack() async {
    // Safety: if we are somehow called while not on a root tab, let the
    // framework handle it normally.
    if (!widget.isRootTab) return false;

    if (_exitOnNextBack) {
      _exitTimer?.cancel();
      _exitOnNextBack = false;
      SystemNavigator.pop();
      return true;
    }

    _exitOnNextBack = true;
    _exitTimer?.cancel();
    _exitTimer = Timer(_backExitInterval, () {
      if (mounted) _exitOnNextBack = false;
    });

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Presiona atrás otra vez para salir'),
          duration: _backExitInterval,
          behavior: SnackBarBehavior.floating,
        ),
      );

    return true; // consumed — do NOT let GoRouter pop the route.
  }

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isRootTab,
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
  ShellItem(
    path: '/dependiente/configuracion',
    label: 'Ajustes',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
  ),
];
