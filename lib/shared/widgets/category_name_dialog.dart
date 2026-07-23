import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';

/// Diálogo para crear o editar categorías (UI/UX Pro Max)
/// Siguiendo §8 Forms & Feedback: validación en tiempo real, labels claros,
/// feedback visual inmediato, y acciones diferenciadas.
class CategoryNameDialog extends StatefulWidget {
  const CategoryNameDialog({
    super.key,
    required this.title,
    required this.categoryExists,
    this.initialName,
  });

  final String title;
  final bool Function(String name) categoryExists;
  final String? initialName;

  @override
  State<CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<CategoryNameDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  String? _errorText;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _focusNode = FocusNode();
    _isValid = (widget.initialName?.trim().isNotEmpty ?? false);
    
    // Auto-focus después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    final trimmed = value.trim();
    setState(() {
      if (trimmed.isEmpty) {
        _errorText = null;
        _isValid = false;
      } else if (trimmed.length < 2) {
        _errorText = 'Mínimo 2 caracteres';
        _isValid = false;
      } else if (widget.categoryExists(trimmed)) {
        _errorText = 'Ya existe una categoría con este nombre';
        _isValid = false;
      } else {
        _errorText = null;
        _isValid = true;
      }
    });
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'El nombre es obligatorio');
      return;
    }

    if (value.length < 2) {
      setState(() => _errorText = 'Mínimo 2 caracteres');
      return;
    }

    if (widget.categoryExists(value)) {
      setState(() => _errorText = 'Ya existe una categoría con este nombre');
      return;
    }

    Haptics.confirm(context);
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;

    return AlertDialog(
      // ═══ Icono contextual ═══
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isEdit ? Icons.edit_rounded : Icons.add_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
      title: Text(
        widget.title,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ Campo de texto con validación visual ═══
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Nombre de la categoría',
              hintText: 'Ej: Bebidas, Limpieza...',
              prefixIcon: Icon(
                Icons.category_outlined,
                color: _errorText != null
                    ? AppColors.danger
                    : (_isValid ? AppColors.success : AppColors.muted),
              ),
              errorText: _errorText,
              // Borde verde cuando es válido
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isValid
                      ? AppColors.success.withValues(alpha: 0.5)
                      : AppColors.line,
                  width: _isValid ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _errorText != null
                      ? AppColors.danger
                      : AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.danger,
                  width: 2,
                ),
              ),
            ),
            onChanged: _validateInput,
            onSubmitted: (_) {
              if (_isValid) _submit();
            },
          ),
          // ═══ Contador de caracteres ═══
          if (_controller.text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_controller.text.trim().length} caracteres',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        // ═══ Botón Cancelar ═══
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(100, 44),
          ),
          child: const Text('Cancelar'),
        ),
        // ═══ Botón Guardar (deshabilitado si no es válido) ═══
        FilledButton.icon(
          onPressed: _isValid ? _submit : null,
          icon: Icon(
            isEdit ? Icons.check_rounded : Icons.add_rounded,
            size: 20,
          ),
          label: Text(isEdit ? 'Actualizar' : 'Crear'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, 44),
            disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.3),
            disabledForegroundColor: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
