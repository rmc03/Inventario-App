import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/connectivity_service.dart';

class IndicadorConexion extends ConsumerStatefulWidget {
  const IndicadorConexion({super.key});

  @override
  ConsumerState<IndicadorConexion> createState() => _IndicadorConexionState();
}

class _IndicadorConexionState extends ConsumerState<IndicadorConexion> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
      final prevConnected = previous?.value;
      final nextConnected = next.value;
      if (prevConnected != null && nextConnected != null && prevConnected != nextConnected) {
        _showToast(context, nextConnected);
      }
    });

    return const SizedBox.shrink();
  }

  void _showToast(BuildContext context, bool isConnected) {
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