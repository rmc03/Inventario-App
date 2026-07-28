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
        } else if (_isConnected != connected) {
          _isConnected = connected;
          _showToast(context, connected);
        }
      },
      loading: () {},
error: (error, stackTrace) {
        // Ignorar errores de conectividad
      },
    );

    if (_isConnected) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Sin conexión a internet. Los datos se guardan localmente y se sincronizarán cuando haya conexión.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.red.shade700,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Sin conexión — los datos se guardan localmente',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(BuildContext context, bool isConnected) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isConnected
                    ? 'Conexión restablecida'
                    : 'Sin conexión — los datos se guardan localmente',
              ),
            ),
          ],
        ),
        backgroundColor: isConnected ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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