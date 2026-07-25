import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/cuadre.dart';
import '../../../shared/models/pago.dart';
import '../../../shared/models/venta.dart';
import '../../../shared/widgets/screen_popup_menu.dart';
import '../../../shared/widgets/shift_summary_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cuadres/providers/cuadre_provider.dart';
import '../../ventas/providers/venta_provider.dart';
import '../providers/turno_provider.dart';

class MiTurnoScreen extends ConsumerWidget {
  const MiTurnoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turno = ref.watch(turnoControllerProvider);
    final usuario = ref.watch(authControllerProvider).user;

    if (turno.estaActivo) {
      return const _TurnoActivoView();
    } else if (turno.cuadreEnviadoHoy) {
      return const _CuadreEnviadoView();
    } else {
      // Verificar si hay un cuadre aprobado hoy
      final cuadres = ref.watch(cuadreControllerProvider);
      final hoy = DateTime.now();
      final cuadreAprobadoHoy = usuario != null
          ? cuadres.where((c) =>
              c.dependienteId == usuario.id &&
              c.estado == CuadreEstado.aprobado &&
              _isSameDay(c.fechaTurno, hoy)).firstOrNull
          : null;

      if (cuadreAprobadoHoy != null) {
        return _CuadreAprobadoView(cuadre: cuadreAprobadoHoy);
      } else {
        return const _SinTurnoView();
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ─── Estado 1: Sin turno activo ───────────────────────────────────────────────

class _SinTurnoView extends ConsumerWidget {
  const _SinTurnoView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi turno'),
        actions: [
          ScreenPopupMenu(
            items: [
              ScreenMenuItem(
                value: 'ajustes',
                icon: Icons.settings_rounded,
                iconColor: context.colors.muted,
                title: 'Ajustes',
                subtitle: 'Preferencias de la app',
              ),
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push('/dependiente/configuracion');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Icon(
                        Icons.work_outline_rounded,
                        size: 56,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    compactDateFormatter.format(DateTime.now()),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aún no has iniciado tu turno',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: context.colors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 58,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Haptics.confirm(context);
                        ref.read(turnoControllerProvider.notifier).iniciarTurno();
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Iniciar turno'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Estado 2: Turno activo ───────────────────────────────────────────────────

class _TurnoActivoView extends ConsumerWidget {
  const _TurnoActivoView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turno = ref.watch(turnoControllerProvider);
    final ventas = ref.watch(ventasDelTurnoProvider);
    final totalTurno = ventas.fold(0.0, (sum, v) => sum + v.total);
    final totalArticulos = ventas.fold(0, (sum, v) => sum + v.totalUnidades);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi turno'),
        actions: [
          ScreenPopupMenu(
            items: [
              ScreenMenuItem(
                value: 'cerrar',
                icon: Icons.logout_rounded,
                iconColor: context.colors.danger,
                title: 'Cerrar turno',
                subtitle: 'Finaliza tu jornada',
              ),
              ScreenMenuItem(
                value: 'ajustes',
                icon: Icons.settings_rounded,
                iconColor: context.colors.muted,
                title: 'Ajustes',
                subtitle: 'Preferencias de la app',
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'cerrar':
                  Haptics.confirm(context);
                  context.push('/dependiente/turno/resumen');
                  break;
                case 'ajustes':
                  context.push('/dependiente/configuracion');
                  break;
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card resumen con badge, stats y cerrar turno
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    12,
                    AppSpacing.xl,
                    8,
                  ),
                  child: ShiftSummaryCard(
                    totalVentas: totalTurno,
                    cantidadVentas: ventas.length,
                    cantidadUnidades: totalArticulos,
                    activo: true,
                    horaInicio: turno.horaInicio,
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      0,
                    ),
                    children: [
                      if (ventas.isNotEmpty) ...[
                        // Historial de ventas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Historial de ventas',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: () => _showAllVentasSheet(context, ventas),
                              child: const Text('Ver todas'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...List.generate(
                          ventas.length > 5 ? 5 : ventas.length, // Mostrar máximo 5
                          (i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _VentaCard(venta: ventas[i]),
                            );
                          },
                        ),
                        // Indicador de más ventas
                        if (ventas.length > 5)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: TextButton.icon(
                                onPressed: () => _showAllVentasSheet(context, ventas),
                                icon: const Icon(Icons.expand_more_rounded, size: 20),
                                label: Text(
                                  'Ver ${ventas.length - 5} ventas más',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                      ],

                      if (ventas.isEmpty)
                        const _EmptyItems(),
                    ],
                  ),
                ),
                // Botón nueva venta (fijo al fondo)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Haptics.tap(context);
                        context.push('/dependiente/turno/nueva-venta');
                      },
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: const Text(
                        'Nueva venta',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra un bottom sheet con todas las ventas del turno
  /// Siguiendo UI/UX Pro Max §2 Touch & Interaction con lista scrollable
  void _showAllVentasSheet(BuildContext context, List<Venta> ventas) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.colors.muted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 24,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Todas las ventas',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${ventas.length} ${ventas.length == 1 ? 'venta' : 'ventas'} • ${formatCurrency(ventas.fold(0.0, (sum, v) => sum + v.total))}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: context.colors.muted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Lista de ventas
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    itemCount: ventas.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return _VentaCard(venta: ventas[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 40,
              color: context.colors.muted.withValues(alpha: 0.4),
            ),
            SizedBox(height: 10),
            Text(
              'Sin ventas aún',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: context.colors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca en "Nueva venta" para atender a un cliente.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VentaCard extends StatelessWidget {
  const _VentaCard({required this.venta});

  final Venta venta;

  @override
  Widget build(BuildContext context) {
    // Obtener el método de pago del primer pago (si existe)
    final metodoPago = venta.pagos.isNotEmpty ? venta.pagos.first.metodo : null;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.line,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              context.push('/dependiente/turno/venta/${venta.id}', extra: venta),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Ícono con gradiente
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colors.primary.withValues(alpha: 0.15),
                        context.colors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    color: context.colors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Información de la venta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venta a las ${timeFormatter.format(venta.fecha)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Badge de artículos
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2_rounded,
                                  size: 12,
                                  color: context.colors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  articulosLabel(venta.totalUnidades),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Badge de método de pago (si aplica)
                          if (metodoPago != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: metodoPago == MetodoPago.efectivo
                                    ? context.colors.success.withValues(alpha: 0.08)
                                    : context.colors.warning.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    metodoPago == MetodoPago.efectivo
                                        ? Icons.payments_rounded
                                        : Icons.credit_card_rounded,
                                    size: 12,
                                    color: metodoPago == MetodoPago.efectivo
                                        ? context.colors.success
                                        : context.colors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    metodoPago == MetodoPago.efectivo
                                        ? 'Efectivo'
                                        : 'Transferencia',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: metodoPago == MetodoPago.efectivo
                                              ? context.colors.success
                                              : context.colors.warning,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Precio y chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(venta.total),
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: context.colors.primary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Estado 3: Cuadre enviado ─────────────────────────────────────────────────

class _CuadreEnviadoView extends ConsumerWidget {
  const _CuadreEnviadoView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventas = ref.watch(ventasDelTurnoProvider);
    final total = ventas.fold(0.0, (sum, v) => sum + v.total);
    final totalUnidades = ventas.fold(0, (sum, v) => sum + v.totalUnidades);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi turno'),
        actions: [
          ScreenPopupMenu(
            items: [
              ScreenMenuItem(
                value: 'ajustes',
                icon: Icons.settings_rounded,
                iconColor: context.colors.muted,
                title: 'Ajustes',
                subtitle: 'Preferencias de la app',
              ),
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push('/dependiente/configuracion');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // ── Status Banner ──
                Container(
                  margin: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colors.success.withValues(alpha: 0.12),
                        context.colors.success.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.colors.success.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.colors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 28,
                              color: context.colors.success,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cuadre enviado',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.success,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pendiente de revisión',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.colors.ink.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.colors.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: context.colors.muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Puedes seguir vendiendo. El cuadre se actualizará automáticamente.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.colors.muted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Resumen actual ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ShiftSummaryCard(
                    totalVentas: total,
                    cantidadVentas: ventas.length,
                    cantidadUnidades: totalUnidades,
                    activo: false,
                    horaInicio: ref.watch(turnoControllerProvider).horaInicio,
                    showEditBadge: true,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Historial de ventas ──
                Expanded(
                  child: ventas.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: context.colors.muted.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Cuadre enviado sin ventas',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Toca "Continuar vendiendo" para\natender más clientes.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ventas del turno',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                if (ventas.length > 3)
                                  TextButton(
                                    onPressed: () => _showAllVentasSheet(context, ventas),
                                    child: const Text('Ver todas'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...List.generate(
                              ventas.length > 3 ? 3 : ventas.length,
                              (i) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: _VentaCard(venta: ventas[i]),
                              ),
                            ),
                            if (ventas.length > 3)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: TextButton.icon(
                                    onPressed: () => _showAllVentasSheet(context, ventas),
                                    icon: const Icon(Icons.expand_more_rounded, size: 20),
                                    label: Text(
                                      'Ver ${ventas.length - 3} ventas más',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),

                // ── Botón continuar vendiendo ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Haptics.confirm(context);
                            ref.read(turnoControllerProvider.notifier).reabrirTurno();
                          },
                          icon: const Icon(Icons.add_rounded, size: 22),
                          label: const Text(
                            'Continuar vendiendo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'El cuadre se actualizará con las nuevas ventas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllVentasSheet(BuildContext context, List<Venta> ventas) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.colors.muted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 24,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Todas las ventas',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${ventas.length} ${ventas.length == 1 ? 'venta' : 'ventas'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: ventas.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                       return _VentaCard(venta: ventas[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Estado 4: Cuadre aprobado hoy ─────────────────────────────────────────────

class _CuadreAprobadoView extends ConsumerWidget {
  const _CuadreAprobadoView({required this.cuadre});

  final Cuadre cuadre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi turno'),
        actions: [
          ScreenPopupMenu(
            items: [
              ScreenMenuItem(
                value: 'ajustes',
                icon: Icons.settings_rounded,
                iconColor: context.colors.muted,
                title: 'Ajustes',
                subtitle: 'Preferencias de la app',
              ),
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push('/dependiente/configuracion');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const Spacer(flex: 2),

                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colors.success.withValues(alpha: 0.2),
                        context.colors.success.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Icon(
                      Icons.verified_rounded,
                      size: 72,
                      color: context.colors.success,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  '¡Buen trabajo, ${cuadre.dependienteNombre.split(' ').first}!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu cuadre fue aprobado',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),
                Text(
                  compactDateFormatter.format(cuadre.fechaTurno),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.muted,
                  ),
                ),

                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'Ventas',
                            value: '${cuadre.ventas.length}',
                            icon: Icons.receipt_long_rounded,
                            color: context.colors.primary,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: context.colors.line,
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'Unidades',
                            value: '${cuadre.totalSalidas}',
                            icon: Icons.inventory_2_rounded,
                            color: context.colors.warning,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: context.colors.line,
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'Total',
                            value: formatCurrency(cuadre.valorTotal),
                            icon: Icons.payments_rounded,
                            color: context.colors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    height: 58,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Haptics.confirm(context);
                        ref.read(turnoControllerProvider.notifier).iniciarTurno();
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Iniciar nuevo turno',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colors.muted,
          ),
        ),
      ],
    );
  }
}


