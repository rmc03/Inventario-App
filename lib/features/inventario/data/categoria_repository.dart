import '../../../shared/models/categoria.dart';

abstract class CategoriaRepository {
  List<Categoria> fetchCategorias();
  void upsertCategoria(Categoria categoria);
  void deleteCategoria(String id);
  bool existsCategoriaConNombre(String nombre, {String? excludeId});
}
