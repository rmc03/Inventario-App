// ignore_for_file: unused_element_parameter
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/app_branding.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/app_startup.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/accessibility_provider.dart';

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
    _precacheDemoAssets();
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

  void _precacheDemoAssets() {
    const paths = [
      'assets/images/aceite.jpg',
      'assets/images/cadena.jpg',
      'assets/images/casco.jpg',
      'assets/images/cubre-tanque.jpg',
      'assets/images/guantes.jpg',
      'assets/images/extra-1.jpg',
      'assets/images/extra-2.jpg',
      'assets/images/extra-3.jpg',
      'assets/images/extra-4.jpg',
      'assets/images/extra-5.jpg',
    ];
    // Usamos el frame después del primer build para tener PaintingBinding listo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final path in paths) {
        precacheImage(AssetImage(path), context);
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
    // 🔥 FIX: Use MediaQuery brightness to determine background color
    // BEFORE theme is fully resolved, preventing white flash in dark mode
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark 
        ? const Color(0xFF0F172A)  // Slate 900 from dark theme
        : const Color(0xFFFAFAFA); // Light background
    
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
              color: backgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBranding.buildAppIcon(context),
                    const SizedBox(height: 12),
                    Text(
                      AppBranding.appName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                      ),
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
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = ref.watch(colorSchemeProvider);
    final accessibility = ref.watch(accessibilityProvider);

    return MaterialApp.router(
      title: 'Inventario App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(
        textScaleFactor: accessibility.textSizeLevel.scale,
        boldText: accessibility.boldText,
        reduceAnimations: accessibility.reduceAnimations,
        colorScheme: colorScheme,
      ),
      darkTheme: AppTheme.dark(
        textScaleFactor: accessibility.textSizeLevel.scale,
        boldText: accessibility.boldText,
        reduceAnimations: accessibility.reduceAnimations,
        colorScheme: colorScheme,
      ),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en')],
      builder: (context, child) => _SplashOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
