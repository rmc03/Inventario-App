import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/producto.dart';
import '../providers/inventario_provider.dart';

class ProductoFormScreen extends ConsumerStatefulWidget {
  const ProductoFormScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends ConsumerState<ProductoFormScreen> {
  final _nombreController = TextEditingController();
  final _stockController = TextEditingController();
  final _precioController = TextEditingController();
  String? _categoriaId;
  Producto? _producto;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    final productId = widget.productId;
    if (productId != null) {
      final producto = ref
          .read(inventarioControllerProvider.notifier)
          .findProducto(productId);
      if (producto != null) {
        _producto = producto;
        _nombreController.text = producto.nombre;
        _stockController.text = producto.stockActual.toString();
        _precioController.text = producto.precio.toStringAsFixed(2);
        _categoriaId = producto.categoriaId;
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _stockController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventario = ref.watch(inventarioControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar producto' : 'Crear producto'),
        leading: IconButton(
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                hintText: 'Ej. Laptop Dell Inspiron 15',
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _categoriaId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              hint: const Text('Selecciona una categoría'),
              items: [
                for (final categoria in inventario.categorias)
                  DropdownMenuItem(
                    value: categoria.id,
                    child: Text(categoria.nombre),
                  ),
              ],
              onChanged: (value) => setState(() => _categoriaId = value),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock disponible',
                hintText: 'Ej. 15',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _precioController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio por Unidad',
                hintText: 'Ej. 750.00',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _save(context),
              icon: const Icon(Icons.save_rounded),
              label: Text(
                _isEditing ? 'Actualizar producto' : 'Guardar producto',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    final now = DateTime.now();
    final categoriaId = _categoriaId;
    if (_nombreController.text.trim().isEmpty || categoriaId == null) {
      return;
    }

    final producto = Producto(
      id: _producto?.id ?? const Uuid().v4(),
      nombre: _nombreController.text.trim(),
      categoriaId: categoriaId,
      precio: double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0,
      stockActual: int.tryParse(_stockController.text.trim()) ?? 0,
      stockMinimo: _producto?.stockMinimo ?? 0,
      codigoRef: null,
      fotoUrl: _producto?.fotoUrl,
      createdAt: _producto?.createdAt ?? now,
      updatedAt: now,
    );

    ref.read(inventarioControllerProvider.notifier).upsertProducto(producto);
    context.go('/admin/inventario/productos/${producto.id}');
  }

  void _goBack(BuildContext context) {
    final producto = _producto;
    if (producto == null) {
      context.go('/admin/inventario');
      return;
    }

    context.go('/admin/inventario/productos/${producto.id}');
  }
}