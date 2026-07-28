// ignore_for_file: unused_element_parameter, use_build_context_synchronously
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/movimientos/providers/movimiento_provider.dart';
import '../../../shared/models/categoria.dart';
import '../../../shared/models/movimiento.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/widgets/category_name_dialog.dart';
import '../../../shared/widgets/product_photo.dart';
import '../providers/inventario_provider.dart';

const _maxImageBytes = 5 * 1024 * 1024;
const _defaultStockMinimo = 3;

final _defaultCategoryCreatedAt = DateTime.utc(2024);
final List<Categoria> _defaultCategorias = List.unmodifiable([
  Categoria(
    id: 'cat-cascos',
    nombre: 'Cascos',
    createdAt: _defaultCategoryCreatedAt,
  ),
  Categoria(
    id: 'cat-repuestos',
    nombre: 'Repuestos',
    createdAt: _defaultCategoryCreatedAt,
  ),
  Categoria(
    id: 'cat-accesorios',
    nombre: 'Accesorios',
    createdAt: _defaultCategoryCreatedAt,
  ),
  Categoria(
    id: 'cat-lubricantes',
    nombre: 'Lubricantes',
    createdAt: _defaultCategoryCreatedAt,
  ),
]);

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
  String? _categoriaError;
  String? _precioError;
  String? _stockError;
  bool _isSaving = false;
  Producto? _producto;
  int _categoriaDropdownVersion = 0;

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
            _precioController.text = producto.precio.toInt().toString();
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
        _nombreError = null;
      });
    }
  }

  void _clearErrors() {
    setState(() {
      _nombreError = null;
      _categoriaError = null;
      _precioError = null;
      _stockError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventario = ref.watch(inventarioControllerProvider);

    final allCategorias = [
      ..._defaultCategorias,
      ...inventario.categorias.where(
        (dbCat) => !_defaultCategorias.any((hc) => hc.nombre == dbCat.nombre),
      ),
    ];
    final hasValidSelection =
        _categoriaId == null || allCategorias.any((c) => c.id == _categoriaId);
    final effectiveCategoriaId = hasValidSelection ? _categoriaId : null;

    final dropdownBorder = OutlineInputBorder(
      borderRadius: AppRadii.smBorder,
      borderSide: BorderSide(color: context.colors.line),
    );

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                children: [
                  _ProductPhotoComposer(
                    fotoUrl: _fotoUrl,
                    onPick: _pickImage,
                    onRemove: _clearImage,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader(title: 'Información'),
                  _GroupedFormCard(
                    children: [
                      _FormItem(
                        label: 'Nombre',
                        child: _PlainTextEditor(
                          controller: _nombreController,
                          hintText: 'Camiseta algodón premium',
                          maxLength: 100,
                          textCapitalization: TextCapitalization.words,
                          errorText: _nombreError,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const _CardSeparator(),
                      _FormItem(
                        label: 'Descripción',
                        child: _PlainTextEditor(
                          controller: _descripcionController,
                          hintText:
                              'Describe características, materiales o uso...',
                          maxLength: 500,
                          minLines: 3,
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const _CardSeparator(),
                      _FormItem(
                        label: 'Categoría',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: effectiveCategoriaId,
                              decoration: InputDecoration(
                                filled: false,
                                fillColor: Colors.transparent,
                                border: dropdownBorder,
                                enabledBorder: dropdownBorder,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppRadii.smBorder,
                                  borderSide: BorderSide(
                                    color: context.colors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: AppRadii.smBorder,
                                  borderSide: BorderSide(
                                    color: context.colors.danger,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: AppRadii.smBorder,
                                  borderSide: BorderSide(
                                    color: context.colors.danger,
                                    width: 1.5,
                                  ),
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md,
                                ),
                                hintText: 'Seleccionar categoría',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: context.colors.muted
                                          .withValues(alpha: 0.72),
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: context.colors.muted,
                                size: 22,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: context.colors.ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                              dropdownColor: context.colors.surface,
                              borderRadius: AppRadii.mdBorder,
                              key: ValueKey(_categoriaDropdownVersion),
                              items: [
                                ...allCategorias.map(
                                  (cat) => DropdownMenuItem(
                                    value: cat.id,
                                    child: Text(cat.nombre),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: '__create_new__',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: context.colors.primary,
                                        size: 20,
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'Crear nueva categoría',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: context.colors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _categoriaError = null);
                                if (value == '__create_new__') {
                                  SchedulerBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    setState(
                                        () => _categoriaDropdownVersion++);
                                    _showCreateCategoryDialog(context, ref);
                                  });
                                } else {
                                  setState(() => _categoriaId = value);
                                }
                              },
                            ),
                            if (_categoriaError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _categoriaError!,
                                style: TextStyle(
                                  color: context.colors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader(title: 'Inventario'),
                  _GroupedFormCard(
                    children: [
                      _FormItem(
                        label: 'Stock disponible',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PlainTextEditor(
                              controller: _stockController,
                              hintText: '100',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            if (_stockError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _stockError!,
                                style: TextStyle(
                                  color: context.colors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const _CardSeparator(),
                      _FormItem(
                        label: 'Precio por unidad',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PlainTextEditor(
                              controller: _precioController,
                              hintText: '50',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            if (_precioError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _precioError!,
                                style: TextStyle(
                                  color: context.colors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            _StickyActionBar(
              isEditing: _isEditing,
              isSaving: _isSaving,
              onPressed: () => _save(context),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  void _save(BuildContext context) {
    if (_isSaving) return;
    _clearErrors();
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
      setState(() => _categoriaError = 'Selecciona una categoría');
      return;
    }

    final precio = double.tryParse(_precioController.text.replaceAll(',', '.'));
    if (precio == null || precio < 0) {
      setState(() => _precioError = 'Ingresa un precio válido');
      return;
    }

    final stock = int.tryParse(_stockController.text.trim());
    if (stock == null || stock < 0) {
      setState(() => _stockError = 'Ingresa un stock válido');
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
      stockMinimo: _producto?.stockMinimo ?? _defaultStockMinimo,
      codigoRef: null,
      fotoUrl: _fotoUrl,
      createdAt: _producto?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaving = true);
    final error = ref.read(inventarioControllerProvider.notifier).upsertProducto(producto);
    if (error != null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Registrar un movimiento de entrada por el incremento de stock.
    // Para productos nuevos el stock previo es 0, así que cuenta todo el
    // stock inicial. Al editar, solo se registra la diferencia positiva.
    final prevStock = _producto?.stockActual ?? 0;
    final delta = stock - prevStock;
    if (delta > 0) {
      final user = ref.read(authControllerProvider).user;
      if (user != null) {
        final movError = ref.read(movimientoControllerProvider.notifier).registrarMovimiento(
          producto: producto,
          usuario: user,
          tipo: MovimientoTipo.entrada,
          cantidad: delta,
          nota: _isEditing ? 'Ajuste de stock (entrada)' : 'Alta de producto',
        );
        if (movError != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(movError)));
        }
      }
    }

    setState(() => _isSaving = false);

    // Si estamos editando (venimos desde la pantalla de detalle), simplemente
    // hacemos pop para volver a la pantalla de detalle que ya existe en la
    // pila y se actualizará por el provider. Si es un nuevo producto,
    // reemplazamos la ruta actual por la del detalle para mantener
    // `/admin/inventario` en el historial (evitando perder la pila).
    if (context.mounted) {
      if (_isEditing) {
        context.pop();
      } else {
        context.replace('/admin/inventario/productos/${producto.id}');
      }
    }
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
    context.pop();
  }

  Future<void> _showCreateCategoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => CategoryNameDialog(
        title: 'Nueva categoría',
        categoryExists: (value) => ref
            .read(inventarioControllerProvider.notifier)
            .existsCategoriaConNombre(value),
      ),
    );

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

class _ProductPhotoComposer extends StatelessWidget {
  const _ProductPhotoComposer({
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

    Widget content = Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 104,
            child: ClipRRect(
              borderRadius: AppRadii.mdBorder,
              child: InkWell(
                onTap: onPick,
                borderRadius: AppRadii.mdBorder,
                child: hasImage
                    ? ProductPhoto(url: fotoUrl, size: 104, iconSize: 42)
                    : _PhotoPlaceholder(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasImage ? 'Foto agregada' : 'Foto del producto',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hasImage
                      ? 'Puedes cambiarla o quitarla antes de guardar.'
                      : 'Opcional. JPG, PNG o WebP. Máx. 5 MB.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onPick,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(hasImage ? 'Cambiar foto' : 'Agregar foto'),
                    ),
                    if (hasImage)
                      TextButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Quitar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.lgBorder),
        shadows: AppShadows.subtle,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.lgBorder,
        child: InkWell(onTap: !hasImage ? onPick : null, child: content),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceSecondary,
        borderRadius: AppRadii.mdBorder,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: context.colors.primary.withValues(alpha: AppAlphas.overlay),
              size: 36,
            ),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.muted,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.colors.muted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _GroupedFormCard extends StatelessWidget {
  const _GroupedFormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.lgBorder),
        shadows: AppShadows.subtle,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.lgBorder,
        child: Column(children: children),
      ),
    );
  }
}

class _FormItem extends StatelessWidget {
  const _FormItem({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _PlainTextEditor extends StatelessWidget {
  const _PlainTextEditor({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.errorText,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final String? errorText;
  final TextAlign textAlign;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final isMultiline = (maxLines ?? 1) > 1 || (minLines ?? 1) > 1;
    final resolvedKeyboardType =
        keyboardType ??
        (isMultiline ? TextInputType.multiline : TextInputType.text);

    final border = OutlineInputBorder(
      borderRadius: AppRadii.smBorder,
      borderSide: BorderSide(color: context.colors.line),
    );

    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      keyboardType: resolvedKeyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      textAlign: textAlign,
      textInputAction: textInputAction,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: context.colors.ink,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: false,
        fillColor: Colors.transparent,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.smBorder,
          borderSide: BorderSide(color: context.colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.smBorder,
          borderSide: BorderSide(color: context.colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.smBorder,
          borderSide: BorderSide(color: context.colors.danger, width: 1.5),
        ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: isMultiline ? AppSpacing.lg : AppSpacing.md,
        ),
        errorText: errorText,
        errorStyle: TextStyle(
          color: context.colors.danger,
          fontWeight: FontWeight.w600,
        ),
        counterStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.colors.muted),
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: context.colors.muted.withValues(alpha: 0.72),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _CardSeparator extends StatelessWidget {
  const _CardSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Divider(height: 1),
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  const _StickyActionBar({required this.isEditing, required this.onPressed, this.isSaving = false});

  final bool isEditing;
  final VoidCallback onPressed;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.background.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: context.colors.line.withValues(alpha: 0.7)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.sm + MediaQuery.of(context).padding.bottom,
          ),
          child: ElevatedButton.icon(
            onPressed: isSaving ? null : () {
              Haptics.confirm(context);
              onPressed();
            },
            icon: isSaving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Icon(
                    isEditing ? Icons.save_outlined : Icons.add_circle_outline,
                  ),
            label: Text(isSaving ? 'Guardando…' : (isEditing ? 'Actualizar producto' : 'Guardar producto')),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
