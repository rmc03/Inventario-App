import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cuadres/providers/cuadre_provider.dart';
import '../../features/movimientos/providers/movimiento_provider.dart';
import '../../features/ventas/providers/venta_provider.dart';

/// Provides the count of local changes pending sync to Supabase.
final pendingSyncCountProvider = Provider<int>((ref) {
  final ventas = ref.watch(ventaRepositoryProvider);
  final movimientos = ref.watch(movimientoRepositoryProvider);
  final cuadres = ref.watch(cuadreRepositoryProvider);

  int count = 0;

  // Count unsynced ventas
  for (final v in ventas.fetchVentas()) {
    if (!v.synced) count++;
  }

  // Count unsynced movimientos
  for (final m in movimientos.fetchMovimientos()) {
    if (!m.synced) count++;
  }

  // Count unsynced cuadres
  for (final c in cuadres.fetchCuadres()) {
    if (!c.synced) count++;
  }

  return count;
});
