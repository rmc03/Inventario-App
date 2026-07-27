import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/qr_pago.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/qr_pago_repository.dart';

/// Provider que expone todos los QRs accesibles (propios + compartidos)
final qrsPagosAccesiblesProvider = StreamProvider<List<QrPago>>((ref) {
  final repo = ref.watch(qrPagoRepositoryProvider);
  final authState = ref.watch(authControllerProvider);
  
  if (authState.user == null) return Stream.value([]);
  
  return repo.watchQrsPagosAccesibles(authState.user!.id);
});

/// Provider que expone solo los QRs propios del usuario
final misQrsPagosProvider = StreamProvider<List<QrPago>>((ref) {
  final repo = ref.watch(qrPagoRepositoryProvider);
  final authState = ref.watch(authControllerProvider);
  
  if (authState.user == null) return Stream.value([]);
  
  return repo.watchMisQrsPagos(authState.user!.id);
});

/// Provider para operaciones de escritura
final qrPagoActionsProvider = Provider<QrPagoActions>((ref) {
  final repo = ref.watch(qrPagoRepositoryProvider);
  final authState = ref.watch(authControllerProvider);
  
  return QrPagoActions(repo, authState.user?.id ?? '');
});

class QrPagoActions {
  final QrPagoRepository _repository;
  final String _userId;

  QrPagoActions(this._repository, this._userId);

  Future<QrPago> crear({
    required String nombre,
    required File imagenFile,
    required bool esCompartido,
  }) async {
    return await _repository.crearQrPago(
      userId: _userId,
      nombre: nombre,
      imagenFile: imagenFile,
      esCompartido: esCompartido,
    );
  }

  Future<void> actualizar({
    required String id,
    String? nombre,
    bool? esCompartido,
    File? nuevaImagen,
  }) async {
    await _repository.actualizarQrPago(
      userId: _userId,
      id: id,
      nombre: nombre,
      esCompartido: esCompartido,
      nuevaImagen: nuevaImagen,
    );
  }

  Future<void> eliminar(String id) async {
    await _repository.eliminarQrPago(_userId, id);
  }

  Future<bool> puedeCrearMas() async {
    return await _repository.puedeCrearMasQrs(_userId);
  }
}
