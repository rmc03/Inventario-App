import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
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
    if (_rango != RangoFechaFiltro.todos) count++;
    return count;
  }

  void _applyFilters() {
    widget.onApply(
      tipo: _tipo,
      rango: _rango,
      fechaInicio: _customInicio,
      fechaFin: _customFin,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _tipo = TipoMovimientoFiltro.todos;
      _rango = RangoFechaFiltro.todos;
      _customInicio = null;
      _customFin = null;
    });
    _applyFilters();
  }

  Future<void> _onCustomRangeTapped() async {
    final result = await showModalBottomSheet<DateTimeRange?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomDateRangePicker(
        initialRange: (_customInicio != null && _customFin != null)
            ? DateTimeRange(start: _customInicio!, end: _customFin!)
            : null,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _rango = RangoFechaFiltro.personalizado;
        _customInicio = result.start;
        _customFin = result.end;
      });
      _applyFilters();
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
                  padding: EdgeInsets.zero,
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
                        Haptics.tap(context);
                        setState(() => _tipo = TipoMovimientoFiltro.todos);
                        _applyFilters();
                      },
                    ),
                    _FilterListTile(
                      title: 'Solo Entradas',
                      icon: Icons.arrow_downward_rounded,
                      isSelected: _tipo == TipoMovimientoFiltro.entradas,
                      onTap: () {
                        Haptics.tap(context);
                        setState(() => _tipo = TipoMovimientoFiltro.entradas);
                        _applyFilters();
                      },
                    ),
                    _FilterListTile(
                      title: 'Solo Ventas',
                      icon: Icons.shopping_cart_rounded,
                      isSelected: _tipo == TipoMovimientoFiltro.ventas,
                      onTap: () {
                        Haptics.tap(context);
                        setState(() => _tipo = TipoMovimientoFiltro.ventas);
                        _applyFilters();
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
                      title: 'Todos',
                      icon: Icons.all_inclusive_rounded,
                      isSelected: _rango == RangoFechaFiltro.todos,
                      onTap: () {
                        Haptics.tap(context);
                        setState(() => _rango = RangoFechaFiltro.todos);
                        _applyFilters();
                      },
                    ),
                    _FilterListTile(
                      title: 'Hoy',
                      icon: Icons.today_rounded,
                      isSelected: _rango == RangoFechaFiltro.hoy,
                      onTap: () {
                        Haptics.tap(context);
                        setState(() => _rango = RangoFechaFiltro.hoy);
                        _applyFilters();
                      },
                    ),
                    _FilterListTile(
                      title: 'Esta semana',
                      icon: Icons.date_range_rounded,
                      isSelected: _rango == RangoFechaFiltro.semana,
                      onTap: () {
                        Haptics.tap(context);
                        setState(() => _rango = RangoFechaFiltro.semana);
                        _applyFilters();
                      },
                    ),
                    _FilterListTile(
                      title: 'Últimos 30 días',
                      icon: Icons.calendar_month_rounded,
                      isSelected: _rango == RangoFechaFiltro.mes,
                      onTap: () {
                        Haptics.tap(context);
                        setState(() => _rango = RangoFechaFiltro.mes);
                        _applyFilters();
                      },
                    ),
                    _CustomRangeTile(
                      rango: _rango,
                      customInicio: _customInicio,
                      customFin: _customFin,
                      onTap: _onCustomRangeTapped,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
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

// ── Widget: Selector de rango personalizado mejorado ──

class _CustomDateRangePicker extends StatefulWidget {
  const _CustomDateRangePicker({
    this.initialRange,
  });

  final DateTimeRange? initialRange;

  @override
  State<_CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _selectingEnd = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _startDate = widget.initialRange?.start;
    _endDate = widget.initialRange?.end;
    _selectingEnd = _startDate != null;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (nextMonth.isBefore(now) || nextMonth.month == now.month) {
      setState(() {
        _currentMonth = nextMonth;
      });
    }
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      if (!_selectingEnd) {
        // Seleccionando fecha de inicio
        _startDate = date;
        _endDate = null;
        _selectingEnd = true;
      } else {
        // Seleccionando fecha de fin
        if (date.isBefore(_startDate!)) {
          // Si la fecha es anterior al inicio, reiniciar
          _startDate = date;
          _endDate = null;
        } else {
          _endDate = date;
        }
      }
    });
  }

  void _confirm() {
    if (_startDate != null && _endDate != null) {
      Navigator.of(context).pop(
        DateTimeRange(start: _startDate!, end: _endDate!),
      );
    }
  }

  void _clear() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectingEnd = false;
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month).substring(0, 3)}';
  }

  bool _isDateInRange(DateTime date) {
    if (_startDate == null) return false;
    if (_endDate == null) return date.isAtSameMomentAs(_startDate!);
    return (date.isAtSameMomentAs(_startDate!) ||
            date.isAfter(_startDate!)) &&
        (date.isAtSameMomentAs(_endDate!) || date.isBefore(_endDate!));
  }

  bool _isStartOrEnd(DateTime date) {
    return (_startDate != null && date.isAtSameMomentAs(_startDate!)) ||
        (_endDate != null && date.isAtSameMomentAs(_endDate!));
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final weekdayOfFirstDay = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final now = DateTime.now();
    final canGoNext = _currentMonth.year < now.year ||
        (_currentMonth.year == now.year && _currentMonth.month < now.month);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.md),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: context.colors.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),

            // ── Header con navegación de mes/año ──
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: context.colors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Seleccionar rango',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      if (_startDate != null || _endDate != null)
                        IconButton(
                          onPressed: () {
                            Haptics.tap(context);
                            _clear();
                          },
                          icon: const Icon(Icons.clear_rounded),
                          iconSize: 20,
                          style: IconButton.styleFrom(
                            backgroundColor: context.colors.surfaceSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Indicadores de fecha seleccionada
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: _startDate != null
                                ? context.colors.primary.withValues(alpha: 0.1)
                                : context.colors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _startDate != null && !_selectingEnd
                                  ? context.colors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desde',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.colors.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _startDate != null
                                    ? _formatDate(_startDate!)
                                    : 'Seleccionar',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _startDate != null
                                          ? context.colors.primary
                                          : context.colors.muted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: context.colors.muted,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: _endDate != null
                                ? context.colors.primary.withValues(alpha: 0.1)
                                : context.colors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectingEnd && _endDate == null
                                  ? context.colors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hasta',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.colors.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _endDate != null
                                    ? _formatDate(_endDate!)
                                    : 'Seleccionar',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _endDate != null
                                          ? context.colors.primary
                                          : context.colors.muted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Navegación de mes
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Haptics.tap(context);
                          _previousMonth();
                        },
                        icon: const Icon(Icons.chevron_left_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: context.colors.surfaceSecondary,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: canGoNext
                            ? () {
                                Haptics.tap(context);
                                _nextMonth();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: canGoNext
                              ? context.colors.surfaceSecondary
                              : context.colors.surfaceSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Calendario ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  // Días de la semana
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['D', 'L', 'M', 'M', 'J', 'V', 'S']
                        .map((day) => SizedBox(
                              width: 40,
                              child: Center(
                                child: Text(
                                  day,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: context.colors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Grid de días
                  ...List.generate(6, (weekIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (dayIndex) {
                          final dayNumber =
                              weekIndex * 7 + dayIndex - weekdayOfFirstDay + 1;
                          
                          if (dayNumber < 1 || dayNumber > daysInMonth) {
                            return const SizedBox(width: 40, height: 40);
                          }

                          final date = DateTime(
                            _currentMonth.year,
                            _currentMonth.month,
                            dayNumber,
                          );
                          final isToday = date.year == now.year &&
                              date.month == now.month &&
                              date.day == now.day;
                          final isFuture = date.isAfter(now);
                          final isInRange = _isDateInRange(date);
                          final isStartOrEnd = _isStartOrEnd(date);

                          return InkWell(
                            onTap: isFuture
                                ? null
                                : () {
                                    Haptics.tap(context);
                                    _onDateTapped(date);
                                  },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isStartOrEnd
                                    ? context.colors.primary
                                    : isInRange
                                        ? context.colors.primary.withValues(alpha: 0.2)
                                        : isToday
                                            ? context.colors.surfaceSecondary
                                            : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  '$dayNumber',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isFuture
                                            ? context.colors.muted.withValues(alpha: 0.3)
                                            : isStartOrEnd
                                                ? Colors.white
                                                : isInRange
                                                    ? context.colors.primary
                                                    : context.colors.ink,
                                        fontWeight: isStartOrEnd || isToday
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Footer con botón de confirmar ──
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Haptics.tap(context);
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _startDate != null && _endDate != null
                          ? () {
                              Haptics.confirm(context);
                              _confirm();
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
