import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/usuario.dart';
import 'indicador_conexion.dart';
import '../../core/theme/app_theme.dart';
import '../../features/cuadres/providers/cuadre_provider.dart';
import '../models/cuadre.dart';

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
    final items = role == UserRole.admin ? _adminItems(ref) : _dependienteItems;
    final selectedIndex = items.indexWhere((item) => item.path == path);
    final showNavigation = selectedIndex != -1;
    final isRootTab = showNavigation;

    return _PopGuard(
      isRootTab: isRootTab,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildLargeScreen(context, items, selectedIndex);
          }
          return _buildSmallScreen(
            context,
            items,
            selectedIndex,
            showNavigation,
          );
        },
      ),
    );
  }

  Widget _buildLargeScreen(
    BuildContext context,
    List<ShellItem> items,
    int selectedIndex,
  ) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                context.go(items[index].path),
            labelType: NavigationRailLabelType.all,
            groupAlignment: -1.0,
            leading: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Icon(
                LucideIcons.package,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: _AnimatedNavIcon(
                    icon: item.icon,
                    isSelected: false,
                    showBadge: item.badge,
                  ),
                  selectedIcon: _AnimatedNavIcon(
                    icon: item.activeIcon,
                    isSelected: true,
                    showBadge: item.badge,
                  ),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const IndicadorConexion(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildSmallScreen(
    BuildContext context,
    List<ShellItem> items,
    int selectedIndex,
    bool showNavigation,
  ) {
    return Scaffold(
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
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).colorScheme.surface,
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
                      icon: _AnimatedNavIcon(
                        icon: item.icon,
                        isSelected: false,
                        showBadge: item.badge,
                      ),
                      activeIcon: _AnimatedNavIcon(
                        icon: item.activeIcon,
                        isSelected: true,
                        showBadge: item.badge,
                      ),
                      label: item.label,
                    ),
                ],
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
    return PopScope(canPop: !widget.isRootTab, child: widget.child);
  }
}

class ShellItem {
  const ShellItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badge = false,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool badge;
}

class _AnimatedNavIcon extends StatefulWidget {
  const _AnimatedNavIcon({
    required this.icon,
    required this.isSelected,
    this.showBadge = false,
  });

  final IconData icon;
  final bool isSelected;
  final bool showBadge;

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Fondo circular para el ícono activo
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widget.isSelected ? 40 : 0,
          height: widget.isSelected ? 40 : 0,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
        // Ícono con animación de escala
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isSelected ? _scaleAnimation.value : 1.0,
              child: Icon(
                widget.icon,
                color: widget.isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            );
          },
        ),
        // Badge de notificación
        if (widget.showBadge)
          Positioned(
            top: 2,
            right: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.colors.danger,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

List<ShellItem> _adminItems(WidgetRef ref) {
  final cuadres = ref.watch(cuadreControllerProvider);
  final hasPending = cuadres.any((c) => c.estado == CuadreEstado.pendiente);

  return [
    ShellItem(
      path: '/admin/resumen',
      label: 'Resumen',
      icon: LucideIcons.lineChart,
      activeIcon: LucideIcons.chartLine,
    ),
    ShellItem(
      path: '/admin/inventario',
      label: 'Inventario',
      icon: LucideIcons.box,
      activeIcon: LucideIcons.package,
    ),
    ShellItem(
      path: '/admin/movimientos',
      label: 'Movimientos',
      icon: LucideIcons.repeat,
      activeIcon: LucideIcons.arrowLeftRight,
    ),
    ShellItem(
      path: '/admin/cuadres',
      label: 'Cuadres',
      icon: LucideIcons.fileText,
      activeIcon: LucideIcons.fileCheck,
      badge: hasPending,
    ),
  ];
}

const _dependienteItems = [
  ShellItem(
    path: '/dependiente/turno',
    label: 'Mi turno',
    icon: LucideIcons.clock,
    activeIcon: LucideIcons.calendar,
  ),
  ShellItem(
    path: '/dependiente/inventario',
    label: 'Inventario',
    icon: LucideIcons.box,
    activeIcon: LucideIcons.package,
  ),
];
