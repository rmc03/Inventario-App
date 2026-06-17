// ignore_for_file: unused_element_parameter
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/app_startup.dart';

/// Internal splash overlay shown while optional background initialization
/// (e.g. Supabase) completes. Keeps visuals identical to the native splash
/// to avoid a black flash during the transition.
class _SplashOverlay extends StatefulWidget {
  final Widget child;
  const _SplashOverlay({required this.child, super.key});

  @override
  State<_SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<_SplashOverlay> {
  bool _visible = true;
  Timer? _minDelayTimer;

  @override
  void initState() {
    super.initState();
    final future = AppStartup.supabaseInitFuture ?? Future.value();
    var ready = false;
    future.then((_) {
      ready = true;
      if (_minDelayTimer == null || !_minDelayTimer!.isActive) {
        if (mounted) setState(() => _visible = false);
      }
    });

    _minDelayTimer = Timer(const Duration(milliseconds: 200), () {
      if (ready) {
        if (mounted) setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    try {
      _minDelayTimer?.cancel();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return Stack(
      children: [
        child,
        // Splash that covers the UI until initialization completes.
        AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !_visible,
            child: Container(
              color: const Color(0xFFF2F2F7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 92,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Inventario',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InventarioApp extends ConsumerWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Inventario App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) => _SplashOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
