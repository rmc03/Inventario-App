import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/categoria.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/widgets/product_photo.dart';
import '../providers/inventario_provider.dart';

const _maxImageBytes = 5 * 1024 * 1024;

class ProductoFormScreen extends ConsumerStatefulWidget {
  const ProductoFormScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends ConsumerState<ProductoFormScreen> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _stockController = TextEditingController();
  final _precioController = TextEditingController();
  String? _categoriaId;
  String? _fotoUrl;
  String? _nombreError;
  Producto? _producto;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _nombreController.addListener(_refreshCounters);
    _descripcionController.addListener(_refreshCounters);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productId = widget.productId;
      if (productId != null) {
        final producto = ref
            .read(inventarioControllerProvider.notifier)
            .findProducto(productId);
        if (producto != null) {
          setState(() {
            _producto = producto;
            _nombreController.text = producto.nombre;
            _descripcionController.text = producto.descripcion ?? '';
            _stockController.text = producto.stockActual.toString();
            _precioController.text = producto.precio.toStringAsFixed(2);
            _categoriaId = producto.categoriaId;
            _fotoUrl = producto.fotoUrl;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nombreController.removeListener(_refreshCounters);
    _descripcionController.removeListener(_refreshCounters);
    _nombreController.dispose();
    _descripcionController.dispose();
    _stockController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _refreshCounters() {
    if (mounted) {
      setState(() {
        // Limpia el error de nombre en cuanto el usuario retoca el campo
        _nombreError = null;
      });
    }
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
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          children: [
            _LabeledTextField(
              label: 'Nombre del producto',
              controller: _nombreController,
              hintText: 'Ej. Camiseta algodón premium',
              icon: Icons.sell_outlined,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              errorText: _nombreError,
            ),
            const SizedBox(height: 22),
            _LabeledTextField(
              label: 'Descripción',
              controller: _descripcionController,
              hintText: 'Describe las características del producto...',
              icon: Icons.article_outlined,
              maxLength: 500,
              minLines: 5,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 22),
            _FieldLabel(label: 'Categoría'),
            const SizedBox(height: 8),
            _CategoriaDropdown(
              categorias: inventario.categorias,
              selectedId: _categoriaId,
              onChanged: (value) => setState(() => _categoriaId = value),
              onCreateNew: () => _showCreateCategoryDialog(context, ref),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LabeledTextField(
                    label: 'Stock disponible',
                    controller: _stockController,
                    hintText: 'Ej. 100',
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledTextField(
                    label: 'Precio por Unidad',
                    controller: _precioController,
                    hintText: 'Ej. 49.99',
                    icon: Icons.attach_money_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9,.]')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ProductImagePicker(
              fotoUrl: _fotoUrl,
              onPick: _pickImage,
              onRemove: _clearImage,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: () => _save(context),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _isEditing ? 'Actualizar producto' : 'Guardar producto',
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
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

    if (_nombreController.text.trim().isEmpty) {
      setState(() => _nombreError = 'El nombre del producto es obligatorio');
      return;
    }

    final isDuplicateName = ref
        .read(inventarioControllerProvider.notifier)
        .existsProductoConNombre(
          _nombreController.text.trim(),
          excludeId: _producto?.id,
        );
    if (isDuplicateName) {
      setState(() => _nombreError = 'Ya existe un producto con este nombre');
      return;
    }

    if (categoriaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una categoría')));
      return;
    }

    final precio = double.tryParse(_precioController.text.replaceAll(',', '.'));
    if (precio == null || precio < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un precio válido')));
      return;
    }

    final stock = int.tryParse(_stockController.text.trim());
    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un stock válido')));
      return;
    }

    final descripcion = _descripcionController.text.trim();
    final producto = Producto(
      id: _producto?.id ?? const Uuid().v4(),
      nombre: _nombreController.text.trim(),
      descripcion: descripcion.isEmpty ? null : descripcion,
      categoriaId: categoriaId,
      precio: precio,
      stockActual: stock,
      stockMinimo: _producto?.stockMinimo ?? 0,
      codigoRef: null,
      fotoUrl: _fotoUrl,
      createdAt: _producto?.createdAt ?? now,
      updatedAt: now,
    );

    ref.read(inventarioControllerProvider.notifier).upsertProducto(producto);
    context.go('/admin/inventario/productos/${producto.id}');
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null || !mounted) {
      return;
    }

    final imageSize = await File(image.path).length();
    if (imageSize > _maxImageBytes) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La imagen no debe superar los 5 MB')),
      );
      return;
    }

    setState(() => _fotoUrl = image.path);
  }

  void _clearImage() {
    setState(() => _fotoUrl = null);
  }

  void _goBack(BuildContext context) {
    final producto = _producto;
    if (producto == null) {
      context.go('/admin/inventario');
      return;
    }
    context.go('/admin/inventario/productos/${producto.id}');
  }

  Future<void> _showCreateCategoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Crear categoría'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      setDialogState(
                        () => errorText = 'El nombre es obligatorio',
                      );
                      return;
                    }
                    final isDuplicate = ref
                        .read(inventarioControllerProvider.notifier)
                        .existsCategoriaConNombre(value);
                    if (isDuplicate) {
                      setDialogState(
                        () => errorText =
                            'Ya existe una categoría con este nombre',
                      );
                      return;
                    }
                    Navigator.of(context).pop(value);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (name != null && name.isNotEmpty) {
      final categoria = Categoria(
        id: const Uuid().v4(),
        nombre: name,
        createdAt: DateTime.now(),
      );
      ref
          .read(inventarioControllerProvider.notifier)
          .upsertCategoria(categoria);
      if (mounted) {
        setState(() => _categoriaId = categoria.id);
      }
    }
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final isMultiline = (maxLines ?? 1) > 1 || (minLines ?? 1) > 1;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? AppColors.danger : AppColors.line,
              width: hasError ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, isMultiline ? 18 : 12, 16, 12),
            child: Row(
              crossAxisAlignment: isMultiline
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                _InputIcon(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    textCapitalization: textCapitalization,
                    inputFormatters: inputFormatters,
                    maxLength: maxLength,
                    minLines: minLines,
                    maxLines: maxLines,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                      counterText: '',
                      hintText: hintText,
                      hintStyle: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                            color: AppColors.muted.withValues(alpha: 0.72),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.danger,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (maxLength != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${controller.text.length}/$maxLength',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoriaDropdown extends StatelessWidget {
  const _CategoriaDropdown({
    required this.categorias,
    required this.selectedId,
    required this.onChanged,
    required this.onCreateNew,
  });

  final List<Categoria> categorias;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    final validSelectedId =
        categorias.any((categoria) => categoria.id == selectedId)
        ? selectedId
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 14, 8),
        child: Row(
          children: [
            const _InputIcon(icon: Icons.grid_view_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: validSelectedId,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted,
                  ),
                  hint: Text(
                    'Selecciona una categoría',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted.withValues(alpha: 0.72),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  items: [
                    for (final categoria in categorias)
                      DropdownMenuItem<String>(
                        value: categoria.id,
                        child: Text(categoria.nombre),
                      ),
                    const DropdownMenuItem<String>(
                      value: '__create_new__',
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('Crear nueva categoría'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == '__create_new__') {
                      onCreateNew();
                      return;
                    }
                    onChanged(value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImagePicker extends StatelessWidget {
  const _ProductImagePicker({
    required this.fotoUrl,
    required this.onPick,
    required this.onRemove,
  });

  final String? fotoUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = fotoUrl != null && fotoUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Imagen del producto',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.muted,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            children: [
              TextSpan(
                text: ' (opcional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.muted.withValues(alpha: 0.28),
            radius: 14,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  hasImage
                      ? ProductPhoto(url: fotoUrl, size: 92, iconSize: 38)
                      : const _UploadIcon(),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasImage
                              ? 'Foto del producto agregada'
                              : 'Agrega una foto del producto',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'JPG, PNG o WebP. Máx. 5MB',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: onPick,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                minimumSize: const Size(0, 42),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                side: const BorderSide(color: AppColors.line),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                              child: Text(
                                hasImage
                                    ? 'Cambiar imagen'
                                    : 'Seleccionar imagen',
                              ),
                            ),
                            if (hasImage)
                              TextButton(
                                onPressed: onRemove,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  minimumSize: const Size(0, 42),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                                child: const Text('Quitar'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.muted,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InputIcon extends StatelessWidget {
  const _InputIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox.square(
        dimension: 44,
        child: Icon(icon, color: AppColors.muted, size: 22),
      ),
    );
  }
}

class _UploadIcon extends StatelessWidget {
  const _UploadIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      child: SizedBox.square(
        dimension: 92,
        child: Icon(
          Icons.image_outlined,
          color: AppColors.primary.withValues(alpha: 0.72),
          size: 40,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(0.7), Radius.circular(radius)),
      );

    const dashLength = 7.0;
    const gapLength = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
