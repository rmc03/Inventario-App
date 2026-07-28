import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/qr_pago.dart';

/// Modal fullscreen que muestra un QR grande y legible para que el cliente lo escanee.
/// 
/// Diseñado para el contexto cubano donde las transferencias se hacen escaneando
/// el QR de la app bancaria.
class QrDisplayModal extends ConsumerStatefulWidget {
  final List<QrPago> qrsDisponibles;
  final double? montoTransferencia;

  const QrDisplayModal({
    super.key,
    required this.qrsDisponibles,
    this.montoTransferencia,
  });

  @override
  ConsumerState<QrDisplayModal> createState() => _QrDisplayModalState();
}

class _QrDisplayModalState extends ConsumerState<QrDisplayModal>
    with SingleTickerProviderStateMixin {
  late QrPago _qrSeleccionado;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _qrScaleAnimation;

  @override
  void initState() {
    super.initState();
    _qrSeleccionado = widget.qrsDisponibles.first;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // QR entra más tarde y con más dramatismo
    _qrScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _cambiarQr(QrPago nuevoQr) {
    setState(() {
      _qrSeleccionado = nuevoQr;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: context.colors.background,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header con título prominente ──
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.03),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
                )),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escanear para pagar',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Presenta este código al cliente',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: AppSpacing.md),

            // ── Monto destacado si está disponible ──
            if (widget.montoTransferencia != null)
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.colors.primary.withValues(alpha: 0.1),
                            context.colors.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Monto a transferir',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            formatCurrency(widget.montoTransferencia!),
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            SizedBox(height: widget.montoTransferencia != null ? AppSpacing.xxl : AppSpacing.xl),

            // ── QR hero con animación dramática ──
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
                  ),
                  child: ScaleTransition(
                    scale: _qrScaleAnimation,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                        maxHeight: MediaQuery.of(context).size.width * 0.85,
                      ),
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        boxShadow: [
                          // Sombra dramática y elevada
                          BoxShadow(
                            color: context.colors.primary.withValues(alpha: isDark ? 0.3 : 0.15),
                            blurRadius: 60,
                            spreadRadius: 0,
                            offset: const Offset(0, 20),
                          ),
                          BoxShadow(
                            color: context.colors.ink.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 32,
                            spreadRadius: -8,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Image.file(
                              File(_qrSeleccionado.imagenPath),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 80,
                                        color: context.colors.muted.withValues(alpha: 0.3),
                                      ),
                                      SizedBox(height: AppSpacing.md),
                                      Text(
                                        'Error al cargar QR',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: context.colors.muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: AppSpacing.xl),

            // ── Selector de QR si hay múltiples ──
            if (widget.qrsDisponibles.length > 1)
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuenta seleccionada',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: context.colors.muted,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: widget.qrsDisponibles.map((qr) {
                            final isSelected = qr.id == _qrSeleccionado.id;
                            return Padding(
                              padding: EdgeInsets.only(right: AppSpacing.sm),
                              child: Semantics(
                                label: '${qr.nombre}${isSelected ? ', seleccionado' : ''}',
                                button: true,
                                selected: isSelected,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Haptics.tap(context);
                                      _cambiarQr(qr);
                                    },
                                    borderRadius: BorderRadius.circular(AppRadii.md),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOutCubic,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? context.colors.primary
                                            : context.colors.surface,
                                        borderRadius: BorderRadius.circular(AppRadii.md),
                                        border: Border.all(
                                          color: isSelected
                                              ? context.colors.primary
                                              : context.colors.line,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: context.colors.primary.withValues(alpha: 0.3),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            qr.esCompartido
                                                ? Icons.store_rounded
                                                : Icons.account_circle_rounded,
                                            size: 18,
                                            color: isSelected
                                                ? Colors.white
                                                : context.colors.ink,
                                          ),
                                          SizedBox(width: AppSpacing.xs),
                                          Text(
                                            qr.nombre,
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                              color: isSelected
                                                  ? Colors.white
                                                  : context.colors.ink,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: AppSpacing.lg),

            // ── Instrucciones sutiles ──
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.info.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: context.colors.info.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        size: 18,
                        color: context.colors.info,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'El cliente debe escanear este QR desde su app bancaria',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.ink,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: AppSpacing.lg),

            // ── Botón cerrar con color rojo (destructivo) ──
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Haptics.tap(context);
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colors.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                    ),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
