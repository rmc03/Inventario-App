import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/connectivity_service.dart';

/// Widget que muestra el estado de conexión de forma persistente
/// y muestra toasts cuando cambia el estado.
class IndicadorConexion extends ConsumerStatefulWidget {
  const IndicadorConexion({super.key});

  @override
  ConsumerState<IndicadorConexion> createState() => _IndicadorConexionState();
}

class _IndicadorConexionState extends ConsumerState<IndicadorConexion> {
  bool _isConnected = true;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    connectivityAsync.when(
      data: (connected) {
        if (!_initialized) {
          _isConnected = connected;
          _initialized = true;
          // Show toast immediately if the app starts offline
          if (!connected) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showToast(context, false);
            });
          }
        } else if (_isConnected != connected) {
          _isConnected = connected;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showToast(context, connected);
          });
        }
      },
      loading: () {},
      error: (error, stackTrace) {},
    );

    // Nunca ocupa espacio en la UI, solo reacciona con Toasts
    return const SizedBox.shrink();
  }

  void _showToast(BuildContext context, bool isConnected) {
    if (!mounted) return;
    
    final backgroundColor = isConnected ? const Color(0xFF1E2D24) : const Color(0xFF2D1E1E);
    final borderColor = isConnected ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3);
    final iconColor = isConnected ? Colors.green.shade400 : Colors.red.shade400;
    final iconBgColor = isConnected ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'Conexión restablecida' : 'Sin conexión a internet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? 'Sincronizando datos automáticamente...'
                          : 'Trabajando en modo local seguro',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Versión compacta para app bar o espacios reducidos
class IndicadorConexionCompacto extends ConsumerWidget {
  const IndicadorConexionCompacto({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    return connectivityAsync.when(
      data: (connected) {
        if (connected) return const SizedBox.shrink();

        return Semantics(
          label: 'Sin conexión a internet',
          child: Tooltip(
            message: 'Sin conexión — los datos se guardan localmente',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Offline',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}