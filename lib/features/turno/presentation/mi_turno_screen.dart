import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/pago.dart';
import '../../../shared/models/venta.dart';
import '../../../shared/widgets/screen_popup_menu.dart';
import '../../ventas/providers/venta_provider.dart';
import '../providers/turno_provider.dart';

class MiTurnoScreen extends ConsumerWidget {
  const MiTurnoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turno = ref.watch(turnoControllerProvider);

    if (turno.estaActivo) {
      return const _TurnoActivoView();
    } else if (turno.cuadreEnviadoHoy) {
      return const _CuadreEnviadoView();
    } else {
      return const _SinTurnoView();
    }
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 8),
            elevation: 8,
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
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'cerrar',
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: context.colors.danger,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cerrar turno',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Finaliza tu jornada',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.colors.muted,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ajustes',
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.muted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        color: context.colors.muted,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ajustes',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Preferencias de la app',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.colors.muted,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                // Card resumen mejorada (fija)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    12,
                    AppSpacing.xl,
                    8,
                  ),
                  child: _ResumenDelDiaCard(
                    totalVentas: totalTurno,
                    cantidadVentas: ventas.length,
                    cantidadArticulos: totalArticulos,
                  ),
                ),

                // Badge de turno activo
                if (turno.horaInicio != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      16,
                    ),
                    child: _BadgeChip(
                      horaInicio: turno.horaInicio!,
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

class _ResumenDelDiaCard extends StatelessWidget {
  const _ResumenDelDiaCard({
    required this.totalVentas,
    required this.cantidadVentas,
    required this.cantidadArticulos,
  });

  final double totalVentas;
  final int cantidadVentas;
  final int cantidadArticulos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary.withValues(alpha: 0.08),
            context.colors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.monetization_on_rounded,
                        color: context.colors.primary,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Ventas de hoy',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  formatCurrency(totalVentas),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Divisor vertical
          Container(
            width: 1,
            height: 60,
            color: context.colors.line.withValues(alpha: 0.5),
          ),
          const SizedBox(width: AppSpacing.md),
          // Métricas compactas
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MetricaBadge(
                icon: Icons.receipt_rounded,
                valor: '$cantidadVentas',
                label: cantidadVentas == 1 ? 'venta' : 'ventas',
              ),
              const SizedBox(height: 8),
              _MetricaBadge(
                icon: Icons.inventory_2_rounded,
                valor: '$cantidadArticulos',
                label: 'uds.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Badge de métrica compacto para la card de resumen
class _MetricaBadge extends StatelessWidget {
  const _MetricaBadge({
    required this.icon,
    required this.valor,
    required this.label,
  });

  final IconData icon;
  final String valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.colors.line.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: context.colors.primary,
          ),
          SizedBox(width: 6),
          Text(
            valor,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.colors.primary,
                ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.muted,
                ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.horaInicio});

  final DateTime horaInicio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: context.colors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Turno activo \u00b7 Desde ${timeFormatter.format(horaInicio)}',
            style: TextStyle(
              fontSize: 12,
              color: context.colors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

class _CuadreEnviadoView extends StatelessWidget {
  const _CuadreEnviadoView();

  @override
  Widget build(BuildContext context) {
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
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colors.success.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 56,
                          color: context.colors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Cuadre enviado',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pendiente de revisión por el jefe.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: context.colors.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hoy, ${compactDateFormatter.format(DateTime.now())}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
