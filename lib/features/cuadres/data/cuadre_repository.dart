import '../../../shared/models/cuadre.dart';
import '../../../shared/models/cuadre_item.dart';

class CuadreRepository {
  CuadreRepository()
      : _cuadres = [
          Cuadre(
            id: 'cuadre-001',
            dependienteId: '00000000-0000-4000-9000-000000000002',
            dependienteNombre: 'Dependiente Demo',
            fechaTurno: DateTime.now().subtract(const Duration(days: 1)),
            items: const [
              CuadreItem(
                productoId: 'prod-keyboard',
                productoNombre: 'Teclado Inalámbrico Logitech',
                cantidad: 5,
                precioUnitario: 45,
              ),
              CuadreItem(
                productoId: 'prod-mouse',
                productoNombre: 'Mouse Óptico HP',
                cantidad: 3,
                precioUnitario: 18,
              ),
            ],
            estado: CuadreEstado.aprobado,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now().subtract(const Duration(days: 1)),
            synced: true,
          ),
        ];

  final List<Cuadre> _cuadres;

  List<Cuadre> fetchCuadres() {
    final sorted = [..._cuadres]
      ..sort((a, b) => b.fechaTurno.compareTo(a.fechaTurno));
    return List.unmodifiable(sorted);
  }

  void addCuadre(Cuadre cuadre) {
    _cuadres.insert(0, cuadre);
  }

  void updateCuadre(Cuadre cuadre) {
    final index = _cuadres.indexWhere((item) => item.id == cuadre.id);
    if (index != -1) {
      _cuadres[index] = cuadre;
    }
  }

  bool existsCuadreHoy(String dependienteId) {
    final hoy = DateTime.now();
    return _cuadres.any(
      (c) =>
          c.dependienteId == dependienteId &&
          c.fechaTurno.year == hoy.year &&
          c.fechaTurno.month == hoy.month &&
          c.fechaTurno.day == hoy.day,
    );
  }
}
