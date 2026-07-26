import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/resumen_repository.dart';
import '../../movimientos/providers/movimiento_provider.dart';
import '../../inventario/providers/inventario_provider.dart';
import '../../cuadres/providers/cuadre_provider.dart';

/// Proveedor del repositorio de resumen.
final resumenRepositoryProvider = Provider<ResumenRepository>((ref) {
  return ResumenRepository(
    movimientoRepo: ref.watch(movimientoRepositoryProvider),
    productoRepo: ref.watch(productoRepositoryProvider),
    cuadreRepo: ref.watch(cuadreRepositoryProvider),
  );
});

/// Notifier del período seleccionado en la pantalla de resumen.
final periodoResumenProvider =
    NotifierProvider<PeriodoResumenNotifier, PeriodoResumen>(
      PeriodoResumenNotifier.new,
    );

class PeriodoResumenNotifier extends Notifier<PeriodoResumen> {
  @override
  PeriodoResumen build() => PeriodoResumen.hoy;

  void setPeriodo(PeriodoResumen periodo) {
    state = periodo;
  }
}

/// Estado del resumen con soporte de loading y error.
class ResumenState {
  const ResumenState({
    this.datos = DatosResumen.empty,
    this.isLoading = true,
    this.errorMessage,
  });

  final DatosResumen datos;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get hasData => datos != DatosResumen.empty;

  ResumenState copyWith({
    DatosResumen? datos,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ResumenState(
      datos: datos ?? this.datos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier que gestiona loading, error y datos del resumen.
class ResumenNotifier extends Notifier<ResumenState> {
  @override
  ResumenState build() {
    // Escuchar cambios reactivos en datos subyacentes
    ref.listen(movimientoControllerProvider, (_, _) => _recalcular());
    ref.listen(inventarioControllerProvider, (_, _) => _recalcular());
    ref.listen(cuadreControllerProvider, (_, _) => _recalcular());

    // Cálculo inicial
    return _recalcularSync(isInitial: true);
  }

  void setPeriodo(PeriodoResumen periodo) {
    ref.read(periodoResumenProvider.notifier).setPeriodo(periodo);
    _recalcular();
  }

  void _recalcular() {
    state = _recalcularSync();
  }

  ResumenState _recalcularSync({bool isInitial = false}) {
    final periodo = ref.read(periodoResumenProvider);
    final repo = ref.read(resumenRepositoryProvider);

    try {
      final datos = repo.calcularResumen(periodo);
      return ResumenState(datos: datos, isLoading: false);
    } catch (e) {
      return ResumenState(
        isLoading: false,
        errorMessage: 'Error al cargar el resumen. Intenta de nuevo.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    state = _recalcularSync();
  }
}

/// Proveedor principal del resumen con loading/error state.
final resumenControllerProvider =
    NotifierProvider<ResumenNotifier, ResumenState>(
      ResumenNotifier.new,
    );
