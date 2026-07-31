import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/qr_pago.dart';
import '../../../shared/models/usuario.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/qr_pago_provider.dart';

/// Pantalla para gestionar QRs de pago para transferencias bancarias.
///
/// Los administradores pueden crear QRs compartidos con todo el equipo.
/// Los dependientes pueden crear sus propios QRs personales (hasta 5).
class GestionarQrsScreen extends ConsumerStatefulWidget {
  const GestionarQrsScreen({super.key});

  @override
  ConsumerState<GestionarQrsScreen> createState() => _GestionarQrsScreenState();
}

class _GestionarQrsScreenState extends ConsumerState<GestionarQrsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _staggeredItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _fadeIn,
      builder: (context, _) => FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final esAdmin = authState.user?.rol == UserRole.admin;
    final misQrsAsync = ref.watch(misQrsPagosProvider);
    final qrsAccesiblesAsync = ref.watch(qrsPagosAccesiblesProvider);

    // Combinar ambos async values para evitar when anidados
    final isLoading = misQrsAsync.isLoading || qrsAccesiblesAsync.isLoading;
    final hasError = misQrsAsync.hasError || qrsAccesiblesAsync.hasError;

    return Scaffold(
      backgroundColor: context.colors.surfaceSecondary,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: const Text(
          'Mis QRs de pago',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // Manejar estados de error
            if (hasError) {
              return _ErrorState(
                onRetry: () {
                  ref.invalidate(misQrsPagosProvider);
                  ref.invalidate(qrsPagosAccesiblesProvider);
                },
              );
            }

            // Manejar estado de carga inicial (sin datos previos)
            if (isLoading && !misQrsAsync.hasValue && !qrsAccesiblesAsync.hasValue) {
              return const Center(child: CircularProgressIndicator());
            }

            // Obtener los datos usando value con fallback a lista vacía
            final misQrs = misQrsAsync.maybeWhen(
              data: (data) => data,
              orElse: () => <QrPago>[],
            );
            final qrsAccesibles = qrsAccesiblesAsync.maybeWhen(
              data: (data) => data,
              orElse: () => <QrPago>[],
            );
            final qrsCompartidos = qrsAccesibles
                .where((q) => q.esCompartido && q.propietarioId != authState.user?.id)
                .toList();
            final puedeCrearMas = misQrs.length < 5;

            return CustomScrollView(
              slivers: [
                // ── Header informativo — más sutil, menos invasivo ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.colors.info.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.info.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: context.colors.info.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              esAdmin
                                  ? 'Los QRs compartidos estarán disponibles para todo el equipo'
                                  : 'Crea hasta 5 QRs para recibir transferencias',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: context.colors.muted,
                                letterSpacing: -0.1,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── QRs compartidos (si existen) ──
                if (qrsCompartidos.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: context.colors.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.people_rounded,
                              size: 16,
                              color: context.colors.info,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'QRs del equipo',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.colors.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final qr = qrsCompartidos[index];
                          return _staggeredItem(
                            index,
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _QrCardReadOnly(qr: qr),
                            ),
                          );
                        },
                        childCount: qrsCompartidos.length,
                      ),
                    ),
                  ),
                ],

                // ── Mis QRs personales — header con contador destacado ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.qr_code_2_rounded,
                                size: 16,
                                color: context.colors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Mis QRs',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.colors.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: misQrs.length >= 5
                                ? context.colors.warning.withValues(alpha: 0.12)
                                : context.colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${misQrs.length}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: misQrs.length >= 5
                                      ? context.colors.warning
                                      : context.colors.primary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                '/5',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.muted,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (misQrs.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _EmptyState(
                        onAgregar: puedeCrearMas ? () => _mostrarFormularioNuevoQr(context, esAdmin) : null,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final qr = misQrs[index];
                          return _staggeredItem(
                            index,
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _QrCardEditable(
                                qr: qr,
                                onEditar: () => _editarQr(context, qr, esAdmin),
                                onEliminar: () => _eliminarQr(context, qr),
                              ),
                            ),
                          );
                        },
                        childCount: misQrs.length,
                      ),
                    ),
                  ),

                // Espaciado final
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: misQrsAsync.maybeWhen(
        data: (misQrs) {
          final puedeCrearMas = misQrs.length < 5;
          if (!puedeCrearMas) return null;

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primary = context.colors.primary;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Tooltip contextual — desaparece gradualmente después de 3s
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12, right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.colors.ink,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.ink.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 16,
                              color: context.colors.surface,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Agregar QR',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.colors.surface,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // FAB con glow premium
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: isDark ? 0.5 : 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: primary.withValues(alpha: isDark ? 0.2 : 0.15),
                      blurRadius: 48,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: FloatingActionButton.large(
                  onPressed: () {
                    Haptics.tap(context);
                    _mostrarFormularioNuevoQr(context, esAdmin);
                  },
                  tooltip: 'Agregar QR de pago',
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  highlightElevation: 12,
                  child: const Icon(Icons.add_rounded, size: 32),
                ),
              ),
            ],
          );
        },
        orElse: () => null,
      ),
    );
  }

  void _mostrarFormularioNuevoQr(BuildContext context, bool esAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormularioQr(esAdmin: esAdmin),
    );
  }

  void _editarQr(BuildContext context, QrPago qr, bool esAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormularioQr(qrExistente: qr, esAdmin: esAdmin),
    );
  }

  Future<void> _eliminarQr(BuildContext context, QrPago qr) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar QR'),
        content: Text('¿Estás seguro de que quieres eliminar "${qr.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.danger,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    try {
      await ref.read(qrPagoActionsProvider).eliminar(qr.id);
      if (!context.mounted) return;
      
      Haptics.confirm(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR "${qr.nombre}" eliminado'),
          backgroundColor: context.colors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Haptics.warning(context);
      final mensaje = e.toString().contains('permisos')
          ? 'No tienes permisos para eliminar este QR'
          : 'Error al eliminar el QR. Intenta de nuevo';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: context.colors.danger,
        ),
      );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets auxiliares
// ════════════════════════════════════════════════════════════════════════════

/// Tarjeta de QR con opciones de edición/eliminación — craft premium
class _QrCardEditable extends StatefulWidget {
  final QrPago qr;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _QrCardEditable({
    required this.qr,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  State<_QrCardEditable> createState() => _QrCardEditableState();
}

class _QrCardEditableState extends State<_QrCardEditable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'QR de pago: ${widget.qr.nombre}${widget.qr.esCompartido ? ', compartido' : ''}',
      button: true,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colors.surface,
                  context.colors.surface.withValues(
                    alpha: isDark ? 0.95 : 0.98,
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.colors.line.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.colors.ink.withValues(alpha: isDark ? 0.08 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Preview del QR — más grande y con glow sutil
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: context.colors.line.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Image.file(
                        File(widget.qr.imagenPath),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: context.colors.surfaceSecondary,
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              size: 36,
                              color: context.colors.muted.withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.qr.nombre,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: context.colors.ink,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.colors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: context.colors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Activo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.success,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.qr.esCompartido) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.colors.info.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_rounded,
                                    size: 11,
                                    color: context.colors.info,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Equipo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.info,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: context.colors.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatearFecha(widget.qr.creadoEn),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.colors.muted,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Botones
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: context.colors.ink,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'editar') {
                      widget.onEditar();
                    } else if (value == 'eliminar') {
                      widget.onEliminar();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20, color: context.colors.ink),
                          const SizedBox(width: 12),
                          const Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 20, color: context.colors.danger),
                          const SizedBox(width: 12),
                          Text('Eliminar', style: TextStyle(color: context.colors.danger)),
                        ],
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

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      return 'Hoy';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}

/// Tarjeta de QR solo lectura (para QRs compartidos) — con acento visual diferenciado
class _QrCardReadOnly extends StatelessWidget {
  final QrPago qr;

  const _QrCardReadOnly({required this.qr});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'QR compartido: ${qr.nombre}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.info.withValues(alpha: isDark ? 0.08 : 0.06),
              context.colors.info.withValues(alpha: isDark ? 0.04 : 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.colors.info.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Preview del QR — con border accent
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colors.info.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.info.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  color: Colors.white,
                  child: Image.file(
                    File(qr.imagenPath),
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: context.colors.surfaceSecondary,
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          size: 32,
                          color: context.colors.muted.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.colors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          size: 14,
                          color: context.colors.info,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          qr.nombre,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.colors.ink,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 12,
                          color: context.colors.info,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Disponible para todo el equipo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.info,
                            letterSpacing: 0,
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
      ),
    );
  }
}

/// Estado vacío cuando no hay QRs — la primera impresión cuenta.
///
/// Breathing pulse + glow ring le dan vida al ícono. La copy reframing
/// el empty state como una invitación ("Listo para recibir pagos") en
/// vez de una sentencia muerta ("Sin QRs configurados").
class _EmptyState extends StatefulWidget {
  final VoidCallback? onAgregar;

  const _EmptyState({this.onAgregar});

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing pulse — 3s cycle, very subtle (1.0 → 1.06)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Glow ring pulse — slower, offset timing
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.colors.primary;
    final primaryAlpha = isDark ? 0.55 : 0.4;

    return Semantics(
      label: 'No tienes QRs de pago configurados',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Animated QR icon with enhanced glow ring ──
              AnimatedBuilder(
                animation: Listenable.merge([_pulseController, _glowController]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withValues(alpha: _glowAnimation.value * 0.15),
                            primaryColor.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: _glowAnimation.value),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: _glowAnimation.value * 0.4),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: 72,
                        color: primaryColor.withValues(alpha: primaryAlpha),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // ── Reframed headline — invitation, not dead end ──
              Text(
                'Empieza a cobrar\ncon transferencias',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.colors.ink,
                  letterSpacing: -0.6,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              // ── Copy with product voice ──
              Text(
                'Sube tu QR bancario y tus clientes\npodrán transferir de inmediato',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.colors.muted,
                  letterSpacing: -0.15,
                  height: 1.45,
                ),
              ),
              if (widget.onAgregar != null) ...[
                const SizedBox(height: 32),
                // ── CTA with enhanced glow and micro-interaction ──
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.85 + (0.15 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: isDark ? 0.4 : 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: FilledButton.icon(
                            onPressed: widget.onAgregar,
                            icon: const Icon(Icons.add_photo_alternate_rounded, size: 22),
                            label: const Text(
                              'Subir mi primer QR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: context.colors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado de error con retry — el usuario nunca debe quedarse atrapado.
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: context.colors.danger.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No se pudieron cargar los QRs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.ink,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Verifica tu conexión a internet y vuelve a intentar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.muted,
                letterSpacing: -0.1,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulario para crear o editar un QR
class _FormularioQr extends ConsumerStatefulWidget {
  final QrPago? qrExistente;
  final bool esAdmin;

  const _FormularioQr({
    this.qrExistente,
    required this.esAdmin,
  });

  @override
  ConsumerState<_FormularioQr> createState() => _FormularioQrState();
}

class _FormularioQrState extends ConsumerState<_FormularioQr> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  bool _esCompartido = false;
  File? _imagenSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.qrExistente != null) {
      _nombreController.text = widget.qrExistente!.nombre;
      _esCompartido = widget.qrExistente!.esCompartido;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );

    if (imagen == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagen.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxWidth: 1024,
      maxHeight: 1024,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar QR',
          toolbarColor: context.colors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: context.colors.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Recortar QR',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imagenSeleccionada = File(croppedFile.path);
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.qrExistente == null && _imagenSeleccionada == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona una imagen del QR'),
          backgroundColor: context.colors.warning,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final actions = ref.read(qrPagoActionsProvider);

      if (widget.qrExistente == null) {
        // Crear nuevo
        await actions.crear(
          nombre: _nombreController.text.trim(),
          imagenFile: _imagenSeleccionada!,
          esCompartido: _esCompartido && widget.esAdmin,
        );
      } else {
        // Actualizar existente
        await actions.actualizar(
          id: widget.qrExistente!.id,
          nombre: _nombreController.text.trim(),
          esCompartido: _esCompartido && widget.esAdmin,
          nuevaImagen: _imagenSeleccionada,
        );
      }

      if (!mounted) return;
      
      // Capturar el ScaffoldMessenger antes de navegar
      final messenger = ScaffoldMessenger.of(context);
      final colorSuccess = context.colors.success;
      final mensaje = widget.qrExistente == null
          ? '¡Listo! Ya puedes recibir transferencias'
          : 'QR actualizado';
      
      Haptics.confirm(context);
      Navigator.of(context).pop();
      
      // Mostrar SnackBar después de navegar, usando el messenger capturado
      messenger.showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: colorSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Haptics.warning(context);
      final mensaje = e.toString().contains('permisos')
          ? 'No tienes permisos para modificar este QR'
          : 'No se pudo guardar. Verifica tu conexión e intenta de nuevo';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: context.colors.danger,
        ),
      );
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: isDark ? 0.4 : 0.2),
            blurRadius: 48,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header con drag handle ──
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: context.colors.line.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.qrExistente == null ? 'Nuevo QR' : 'Editar QR',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: context.colors.ink,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.qrExistente == null
                              ? 'Sube tu QR para recibir transferencias'
                              : 'Actualiza la información de tu QR',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colors.muted,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.surfaceSecondary,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Campo nombre con diseño elevado ──
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.ink.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nombreController,
                    maxLength: 40,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nombre del QR',
                      hintText: 'Ej: Cuenta BPA, USD, etc.',
                      prefixIcon: Icon(
                        Icons.label_rounded,
                        color: context.colors.primary.withValues(alpha: 0.7),
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: context.colors.surfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: context.colors.line.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: context.colors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: context.colors.danger,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.trim().length < 3) {
                        return 'Mínimo 3 caracteres';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Selector de imagen — hero del formulario ──
                InkWell(
                  onTap: _seleccionarImagen,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.colors.primary.withValues(alpha: 0.05),
                          context.colors.primary.withValues(alpha: 0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: context.colors.primary.withValues(alpha: 0.2),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _imagenSeleccionada != null
                        ? Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imagenSeleccionada!,
                                  height: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: context.colors.surfaceSecondary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_outlined,
                                            size: 48,
                                            color: context.colors.muted.withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No se pudo cargar la imagen',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: context.colors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 16,
                                    color: context.colors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Toca para cambiar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.primary,
                                      letterSpacing: -0.15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : widget.qrExistente != null
                            ? Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(widget.qrExistente!.imagenPath),
                                      height: 200,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: context.colors.surfaceSecondary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image_outlined,
                                                size: 48,
                                                color: context.colors.muted.withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Imagen no disponible',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: context.colors.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.touch_app_rounded,
                                        size: 16,
                                        color: context.colors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Toca para cambiar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: context.colors.primary,
                                          letterSpacing: -0.15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: context.colors.primary.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 56,
                                      color: context.colors.primary.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Seleccionar imagen del QR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.ink,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Desde tu galería de fotos',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.muted,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 20),

                // Opción compartir (solo admin)
                if (widget.esAdmin)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colors.info.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 24,
                          color: context.colors.info,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Compartir con el equipo',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.ink,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Todos los dependientes podrán usar este QR',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.muted,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _esCompartido,
                          onChanged: (value) => setState(() => _esCompartido = value),
                          activeColor: context.colors.primary,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Botón guardar — CTA hero con estados refinados ──
                Container(
                  height: 58,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _guardando
                        ? []
                        : [
                            BoxShadow(
                              color: context.colors.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      disabledBackgroundColor: context.colors.muted.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _guardando
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Guardando...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            widget.qrExistente == null ? 'Crear QR' : 'Guardar cambios',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
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
