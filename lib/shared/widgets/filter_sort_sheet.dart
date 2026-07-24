import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../models/categoria.dart';

/// Enum para las opciones de ordenamiento de productos
enum ProductoSortBy {
  nombreAsc('Nombre (A-Z)'),
  precioAsc('Precio (Menor a Mayor)'),
  precioDesc('Precio (Mayor a Menor)'),
  stockAsc('Stock (Menor a Mayor)'),
  stockDesc('Stock (Mayor a Menor)');

  const ProductoSortBy(this.label);
  final String label;
}

/// Sheet rediseñado para ordenar y filtrar siguiendo las mejores prácticas
/// de UI/UX Pro Max:
/// - Usa listas en lugar de chips para mejor escaneabilidad
/// - Targets táctiles de 44×44pt mínimo
/// - Jerarquía visual clara con separadores
/// - Feedback visual inmediato en interacciones
/// - Contraste adecuado (4.5:1) en todos los estados
class FilterSortSheet extends StatefulWidget {
  const FilterSortSheet({
    super.key,
    required this.initialSortBy,
    this.initialCategoriaId,
    required this.initialSoloStockBajo,
    required this.categorias,
    required this.onApply,
    this.title = 'Ordenar y Filtrar',
  });

  final ProductoSortBy initialSortBy;
  final String? initialCategoriaId;
  final bool initialSoloStockBajo;
  final List<Categoria> categorias;
  final void Function({
    required ProductoSortBy sortBy,
    required String? categoriaId,
    required bool soloStockBajo,
  }) onApply;
  final String title;

  @override
  State<FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends State<FilterSortSheet> {
  late ProductoSortBy _sortBy;
  String? _categoriaId;
  late bool _soloStockBajo;
  final _sheetController = DraggableScrollableController();
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy;
    _categoriaId = widget.initialCategoriaId;
    _soloStockBajo = widget.initialSoloStockBajo;
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_sortBy != ProductoSortBy.nombreAsc) count++;
    if (_soloStockBajo) count++;
    if (_categoriaId != null) count++;
    return count;
  }

  void _applyFilters() {
    widget.onApply(
      sortBy: _sortBy,
      categoriaId: _categoriaId == '' ? null : _categoriaId,
      soloStockBajo: _soloStockBajo,
    );
    Navigator.of(context).pop();
  }

  void _clearAllFilters() {
    setState(() {
      _sortBy = ProductoSortBy.nombreAsc;
      _categoriaId = null;
      _soloStockBajo = false;
    });
    // Aplicar inmediatamente al limpiar
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.ink.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Drag Handle ──
              GestureDetector(
                onVerticalDragStart: (_) => setState(() => _isDragging = true),
                onVerticalDragUpdate: (details) {
                  final delta = -details.primaryDelta! /
                      MediaQuery.of(context).size.height;
                  _sheetController.jumpTo(
                    (_sheetController.size + delta).clamp(0.5, 0.95),
                  );
                },
                onVerticalDragEnd: (_) => setState(() => _isDragging = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: _isDragging ? 50 : 40,
                      height: _isDragging ? 6 : 5,
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? context.colors.primary
                            : context.colors.muted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Header ──
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: context.colors.line.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: context.colors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          if (_activeFiltersCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    context.colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_activeFiltersCount ${_activeFiltersCount == 1 ? 'activo' : 'activos'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_activeFiltersCount > 0)
                      FilledButton.tonal(
                        onPressed: _clearAllFilters,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.clear_all_rounded, size: 16),
                            SizedBox(width: 4),
                            Text('Limpiar'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ── Contenido scrollable ──
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom +
                        AppSpacing.xl,
                  ),
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    // ── Sección: Ordenar por ──
                    _SectionHeader(
                      icon: Icons.sort_rounded,
                      title: 'Ordenar por',
                    ),

                    // Lista de opciones de ordenamiento
                    ...ProductoSortBy.values.map((sortOption) {
                      final isSelected = _sortBy == sortOption;
                      return _FilterListTile(
                        title: sortOption.label,
                        icon: _getSortIcon(sortOption),
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _sortBy = sortOption);
                          _applyFilters();
                        },
                      );
                    }),

                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Sección: Filtros ──
                    _SectionHeader(
                      icon: Icons.filter_list_rounded,
                      title: 'Filtros',
                    ),

                    // Stock bajo
                    _FilterSwitchTile(
                      title: 'Solo stock bajo',
                      subtitle: 'Productos con 3 unidades o menos',
                      icon: Icons.warning_amber_rounded,
                      value: _soloStockBajo,
                      onChanged: (val) {
                        setState(() => _soloStockBajo = val);
                        _applyFilters();
                      },
                      activeColor: context.colors.warning,
                    ),

                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Sección: Categoría ──
                    _SectionHeader(
                      icon: Icons.category_rounded,
                      title: 'Categoría',
                    ),

                    // Opción "Todas"
                    _FilterListTile(
                      title: 'Todas las categorías',
                      icon: Icons.apps_rounded,
                      isSelected: _categoriaId == null,
                      onTap: () {
                        setState(() => _categoriaId = null);
                        _applyFilters();
                      },
                    ),

                    // Lista de categorías
                    ...widget.categorias.map((categoria) {
                      final isSelected = _categoriaId == categoria.id;
                      return _FilterListTile(
                        title: categoria.nombre,
                        icon: Icons.label_rounded,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _categoriaId = categoria.id);
                          _applyFilters();
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getSortIcon(ProductoSortBy sortBy) {
    return switch (sortBy) {
      ProductoSortBy.nombreAsc => Icons.sort_by_alpha_rounded,
      ProductoSortBy.precioAsc => Icons.arrow_upward_rounded,
      ProductoSortBy.precioDesc => Icons.arrow_downward_rounded,
      ProductoSortBy.stockAsc => Icons.trending_up_rounded,
      ProductoSortBy.stockDesc => Icons.trending_down_rounded,
    };
  }
}

// ── Widget: Header de sección ──

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: context.colors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.ink,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: List tile para filtros (target táctil mínimo 44pt) ──

class _FilterListTile extends StatelessWidget {
  const _FilterListTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56), // 56dp > 44pt
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected
                    ? context.colors.primary
                    : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.primary.withValues(alpha: 0.15)
                      : context.colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.muted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.ink,
                      ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: context.colors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget: Switch tile para filtros ──

class _FilterSwitchTile extends StatelessWidget {
  const _FilterSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: value
            ? activeColor.withValues(alpha: 0.08)
            : context.colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? activeColor.withValues(alpha: 0.3)
              : context.colors.line,
          width: 1,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: value ? activeColor : context.colors.muted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value ? activeColor : context.colors.ink,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: value ? activeColor : context.colors.muted,
            fontSize: 12,
          ),
        ),
        value: value,
        activeTrackColor: activeColor,
        onChanged: onChanged,
      ),
    );
  }
}
