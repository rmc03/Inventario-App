import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../features/movimientos/data/movimiento_repository.dart';

class MovimientoFilterSheet extends StatefulWidget {
  const MovimientoFilterSheet({
    super.key,
    required this.initialTipo,
    required this.initialRango,
    this.initialFechaInicio,
    this.initialFechaFin,
    required this.onApply,
  });

  final TipoMovimientoFiltro initialTipo;
  final RangoFechaFiltro initialRango;
  final DateTime? initialFechaInicio;
  final DateTime? initialFechaFin;
  final void Function({
    required TipoMovimientoFiltro tipo,
    required RangoFechaFiltro rango,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) onApply;

  @override
  State<MovimientoFilterSheet> createState() => _MovimientoFilterSheetState();
}

class _MovimientoFilterSheetState extends State<MovimientoFilterSheet> {
  late TipoMovimientoFiltro _tipo;
  late RangoFechaFiltro _rango;
  DateTime? _customInicio;
  DateTime? _customFin;
  final _sheetController = DraggableScrollableController();
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _tipo = widget.initialTipo;
    _rango = widget.initialRango;
    _customInicio = widget.initialFechaInicio;
    _customFin = widget.initialFechaFin;
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_tipo != TipoMovimientoFiltro.todos) count++;
    if (_rango != RangoFechaFiltro.hoy) count++;
    return count;
  }

  bool get _canApply {
    if (_rango == RangoFechaFiltro.personalizado &&
        (_customInicio == null || _customFin == null)) {
      return false;
    }
    return true;
  }

  void _apply() {
    widget.onApply(
      tipo: _tipo,
      rango: _rango,
      fechaInicio: _customInicio,
      fechaFin: _customFin,
    );
    Navigator.of(context).pop();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _clearAllFilters() {
    setState(() {
      _tipo = TipoMovimientoFiltro.todos;
      _rango = RangoFechaFiltro.hoy;
      _customInicio = null;
      _customFin = null;
    });
  }

  Future<void> _onCustomRangeTapped() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: (_customInicio != null && _customFin != null)
          ? DateTimeRange(start: _customInicio!, end: _customFin!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.colors.primary,
              onPrimary: Colors.white,
              surface: context.colors.surface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: context.colors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
      helpText: 'Seleccionar rango de fechas',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      saveText: 'Guardar',
      errorFormatText: 'Formato inválido',
      errorInvalidText: 'Fecha fuera de rango',
      errorInvalidRangeText: 'Rango inválido',
      fieldStartHintText: 'Fecha inicio',
      fieldEndHintText: 'Fecha fin',
      fieldStartLabelText: 'Desde',
      fieldEndLabelText: 'Hasta',
    );

    if (range != null && mounted) {
      setState(() {
        _rango = RangoFechaFiltro.personalizado;
        _customInicio = range.start;
        _customFin = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.65,
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
                            'Filtrar movimientos',
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

                    // ── Sección: Tipo de movimiento ──
                    _SectionHeader(
                      icon: Icons.filter_list_rounded,
                      title: 'Tipo de movimiento',
                    ),

                    // Lista de tipos
                    _FilterListTile(
                      title: 'Todos',
                      icon: Icons.all_inclusive_rounded,
                      isSelected: _tipo == TipoMovimientoFiltro.todos,
                      onTap: () {
                        setState(() => _tipo = TipoMovimientoFiltro.todos);
                      },
                    ),
                    _FilterListTile(
                      title: 'Solo Entradas',
                      icon: Icons.arrow_downward_rounded,
                      isSelected: _tipo == TipoMovimientoFiltro.entradas,
                      onTap: () {
                        setState(() => _tipo = TipoMovimientoFiltro.entradas);
                      },
                    ),
                    _FilterListTile(
                      title: 'Solo Ventas',
                      icon: Icons.shopping_cart_rounded,
                      isSelected: _tipo == TipoMovimientoFiltro.ventas,
                      onTap: () {
                        setState(() => _tipo = TipoMovimientoFiltro.ventas);
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Sección: Rango de fecha ──
                    _SectionHeader(
                      icon: Icons.calendar_today_rounded,
                      title: 'Rango de fecha',
                    ),

                    // Lista de rangos
                    _FilterListTile(
                      title: 'Hoy',
                      icon: Icons.today_rounded,
                      isSelected: _rango == RangoFechaFiltro.hoy,
                      onTap: () {
                        setState(() => _rango = RangoFechaFiltro.hoy);
                      },
                    ),
                    _FilterListTile(
                      title: 'Esta semana',
                      icon: Icons.date_range_rounded,
                      isSelected: _rango == RangoFechaFiltro.semana,
                      onTap: () {
                        setState(() => _rango = RangoFechaFiltro.semana);
                      },
                    ),
                    _FilterListTile(
                      title: 'Últimos 30 días',
                      icon: Icons.calendar_month_rounded,
                      isSelected: _rango == RangoFechaFiltro.mes,
                      onTap: () {
                        setState(() => _rango = RangoFechaFiltro.mes);
                      },
                    ),
                    _CustomRangeTile(
                      rango: _rango,
                      customInicio: _customInicio,
                      customFin: _customFin,
                      onTap: _onCustomRangeTapped,
                    ),
                  ],
                ),
              ),

              // ── Footer ──
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: context.colors.line.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: _canApply ? _apply : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

// ── Widget: Tile especial para rango personalizado con formato mejorado ──

class _CustomRangeTile extends StatelessWidget {
  const _CustomRangeTile({
    required this.rango,
    required this.customInicio,
    required this.customFin,
    required this.onTap,
  });

  final RangoFechaFiltro rango;
  final DateTime? customInicio;
  final DateTime? customFin;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String get _displayText {
    if (rango == RangoFechaFiltro.personalizado &&
        customInicio != null &&
        customFin != null) {
      return 'Personalizado (${_formatDate(customInicio!)} - ${_formatDate(customFin!)})';
    }
    return 'Personalizado';
  }

  bool get _hasValidRange =>
      customInicio != null && customFin != null;

  @override
  Widget build(BuildContext context) {
    final isSelected = rango == RangoFechaFiltro.personalizado && _hasValidRange;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
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
                  Icons.edit_calendar_rounded,
                  size: 20,
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.muted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  _displayText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.ink,
                      ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.muted,
                size: isSelected ? 24 : 18,
              ),
            ],
          ),
        ),
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
