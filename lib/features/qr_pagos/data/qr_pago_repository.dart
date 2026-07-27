import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/qr_pago.dart';

const _uuid = Uuid();

final qrPagoRepositoryProvider = Provider<QrPagoRepository>((ref) {
  return InMemoryQrPagoRepository();
});

abstract class QrPagoRepository {
  Stream<List<QrPago>> watchQrsPagosAccesibles(String userId);
  Stream<List<QrPago>> watchMisQrsPagos(String userId);
  Future<QrPago> crearQrPago({
    required String userId,
    required String nombre,
    required File imagenFile,
    required bool esCompartido,
  });
  Future<void> actualizarQrPago({
    required String userId,
    required String id,
    String? nombre,
    bool? esCompartido,
    File? nuevaImagen,
  });
  Future<void> eliminarQrPago(String userId, String id);
  Future<bool> puedeCrearMasQrs(String userId);
}

class InMemoryQrPagoRepository implements QrPagoRepository {
  final List<QrPago> _qrs = [];
  final StreamController<List<QrPago>> _controller =
      StreamController<List<QrPago>>.broadcast();

  InMemoryQrPagoRepository() {
    // Emitir la lista vacía inicial al controlador
    _controller.add(List.unmodifiable(_qrs));
  }

  @override
  Stream<List<QrPago>> watchQrsPagosAccesibles(String userId) {
    // Retornar un stream que comienza con los datos actuales
    return _controller.stream.map((qrs) {
      return qrs.where((qr) {
        return qr.propietarioId == userId || qr.esCompartido;
      }).toList();
    }).startWith(
      _qrs.where((qr) {
        return qr.propietarioId == userId || qr.esCompartido;
      }).toList(),
    );
  }

  @override
  Stream<List<QrPago>> watchMisQrsPagos(String userId) {
    // Retornar un stream que comienza con los datos actuales
    return _controller.stream.map((qrs) {
      return qrs.where((qr) => qr.propietarioId == userId).toList();
    }).startWith(
      _qrs.where((qr) => qr.propietarioId == userId).toList(),
    );
  }

  @override
  Future<QrPago> crearQrPago({
    required String userId,
    required String nombre,
    required File imagenFile,
    required bool esCompartido,
  }) async {
    // Verificar límite
    final misQrs = _qrs.where((qr) => qr.propietarioId == userId).length;
    if (misQrs >= 5) {
      throw Exception('No puedes tener más de 5 QRs. Elimina uno existente primero.');
    }

    // En in-memory, guardamos el path local de la imagen
    final nuevoQr = QrPago(
      id: _uuid.v4(),
      nombre: nombre,
      imagenPath: imagenFile.path, // Path local
      propietarioId: userId,
      esCompartido: esCompartido,
      creadoEn: DateTime.now(),
    );

    _qrs.insert(0, nuevoQr);
    _controller.add(List.unmodifiable(_qrs));

    return nuevoQr;
  }

  @override
  Future<void> actualizarQrPago({
    required String userId,
    required String id,
    String? nombre,
    bool? esCompartido,
    File? nuevaImagen,
  }) async {
    final idx = _qrs.indexWhere((qr) => qr.id == id && qr.propietarioId == userId);
    if (idx == -1) {
      throw Exception('QR no encontrado o no tienes permisos');
    }

    final qrActual = _qrs[idx];
    final qrActualizado = qrActual.copyWith(
      nombre: nombre,
      esCompartido: esCompartido,
      imagenPath: nuevaImagen?.path,
      actualizadoEn: DateTime.now(),
    );

    _qrs[idx] = qrActualizado;
    _controller.add(List.unmodifiable(_qrs));
  }

  @override
  Future<void> eliminarQrPago(String userId, String id) async {
    final initialLength = _qrs.length;
    _qrs.removeWhere((qr) => qr.id == id && qr.propietarioId == userId);
    
    if (_qrs.length == initialLength) {
      throw Exception('QR no encontrado o no tienes permisos');
    }
    
    _controller.add(List.unmodifiable(_qrs));
  }

  @override
  Future<bool> puedeCrearMasQrs(String userId) async {
    final count = _qrs.where((qr) => qr.propietarioId == userId).length;
    return count < 5;
  }

  void dispose() {
    _controller.close();
  }
}

// Extension para agregar startWith a Stream
extension _StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T initialValue) async* {
    yield initialValue;
    yield* this;
  }
}
