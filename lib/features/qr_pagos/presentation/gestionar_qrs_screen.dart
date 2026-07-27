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
      appBar: AppBar(
        title: const Text(
          'Mis QRs de pago',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // Manejar estados de error
            if (hasError) {
              final error = misQrsAsync.error ?? qrsAccesiblesAsync.error;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: context.colors.danger.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar QRs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.colors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
                // ── Header informativo ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.colors.info.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 22,
                            color: context.colors.info,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              esAdmin
                                  ? 'Los QRs compartidos estarán disponibles para todos los dependientes'
                                  : 'Puedes crear hasta 5 QRs personales para recibir transferencias',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: context.colors.ink,
                                letterSpacing: -0.1,
                                height: 1.4,
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
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Text(
                        'QRs compartidos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.colors.muted,
                          letterSpacing: -0.2,
                        ),
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

                // ── Mis QRs personales ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mis QRs',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.colors.muted,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '${misQrs.length}/5',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                            letterSpacing: -0.2,
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

          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: isDark ? 0.4 : 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: primary.withValues(alpha: isDark ? 0.15 : 0.1),
                  blurRadius: 48,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                Haptics.tap(context);
                _mostrarFormularioNuevoQr(context, esAdmin);
              },
              tooltip: 'Agregar QR de pago',
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              highlightElevation: 8,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
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
      if (!context.mounted) return;
      
      Haptics.warning(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: context.colors.danger,
        ),
      );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets auxiliares
// ════════════════════════════════════════════════════════════════════════════

/// Tarjeta de QR con opciones de edición/eliminación
class _QrCardEditable extends StatelessWidget {
  final QrPago qr;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _QrCardEditable({
    required this.qr,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.line.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Preview del QR
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(qr.imagenPath),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 72,
                  height: 72,
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
          const SizedBox(width: 16),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        qr.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.ink,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (qr.esCompartido)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Compartido',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.info,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: context.colors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatearFecha(qr.creadoEn),
                      style: TextStyle(
                        fontSize: 13,
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
          const SizedBox(width: 12),
          // Botones
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: context.colors.muted),
            onSelected: (value) {
              if (value == 'editar') {
                onEditar();
              } else if (value == 'eliminar') {
                onEliminar();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20, color: context.colors.ink),
                    const SizedBox(width: 12),
                    const Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: context.colors.danger),
                    const SizedBox(width: 12),
                    Text('Eliminar', style: TextStyle(color: context.colors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
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

/// Tarjeta de QR solo lectura (para QRs compartidos)
class _QrCardReadOnly extends StatelessWidget {
  final QrPago qr;

  const _QrCardReadOnly({required this.qr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.info.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(qr.imagenPath),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 64,
                  height: 64,
                  color: context.colors.surfaceSecondary,
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 28,
                    color: context.colors.muted.withValues(alpha: 0.5),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 16,
                      color: context.colors.info,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        qr.nombre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.colors.ink,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'QR de la tienda',
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
        ],
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
    final primaryAlpha = isDark ? 0.55 : 0.35;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Animated QR icon with glow ring ──
            AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _glowController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(
                          alpha: _glowAnimation.value,
                        ),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(
                            alpha: _glowAnimation.value * 0.3,
                          ),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 64,
                      color: primaryColor.withValues(alpha: primaryAlpha),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            // ── Reframed headline — invitation, not dead end ──
            Text(
              'Listo para recibir pagos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.ink,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            // ── Copy with product voice ──
            Text(
              'Sube una imagen de tu QR bancario\ny empieza a cobrar por transferencia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.muted,
                letterSpacing: -0.1,
                height: 1.5,
              ),
            ),
            if (widget.onAgregar != null) ...[
              const SizedBox(height: 28),
              // ── CTA with subtle glow ──
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: widget.onAgregar,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Agregar mi primer QR',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: context.colors.danger,
        ),
      );
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.qrExistente == null ? 'Nuevo QR' : 'Editar QR',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: context.colors.ink,
                        letterSpacing: -0.6,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.surfaceSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Campo nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del QR',
                    hintText: 'Ej: Cuenta BPA, MLC, etc.',
                    prefixIcon: const Icon(Icons.label_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 20),

                // Selector de imagen
                InkWell(
                  onTap: _seleccionarImagen,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.colors.line.withValues(alpha: 0.3),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
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
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Toca para cambiar imagen',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.primary,
                                  letterSpacing: -0.1,
                                ),
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
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Toca para cambiar imagen',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.primary,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 64,
                                    color: context.colors.muted.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Seleccionar imagen del QR',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.ink,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Desde tu galería',
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

                // Botón guardar
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.qrExistente == null ? 'Crear QR' : 'Guardar cambios',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
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
