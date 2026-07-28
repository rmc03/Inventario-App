import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_schemes.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';

/// Card de selección de tema con preview
class ThemeCard extends StatefulWidget {
  const ThemeCard({
    super.key,
    required this.colorScheme,
    required this.isSelected,
    required this.onTap,
    required this.brightness,
  });

  final AppColorScheme colorScheme;
  final bool isSelected;
  final VoidCallback onTap;
  final Brightness brightness;

  @override
  State<ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<ThemeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.brightness == Brightness.light
        ? widget.colorScheme.light
        : widget.colorScheme.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Haptics.confirm(context);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : (widget.isSelected ? 1.0 : 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: widget.isSelected
                  ? colors.primary
                  : colors.line,
              width: widget.isSelected ? 2.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withAlpha(51), // 0.2
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colors.ink.withAlpha(15), // 0.06
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Ícono con gradient
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [colors.primary, colors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withAlpha(51), // 0.2
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  widget.colorScheme.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Info del tema
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nombre del tema
                    Text(
                      widget.colorScheme.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.ink,
                          ),
                    ),
                    const SizedBox(height: 3),

                    // Mini preview del UI
                    _MiniPreview(colors: colors),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Checkmark si está seleccionado
              if (widget.isSelected)
                Icon(
                  Icons.check_circle,
                  color: colors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini preview del UI con los colores del tema
class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.colors});

  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bar principal
        Expanded(
          flex: 2,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
        const SizedBox(width: 3),

        // Bar success
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: colors.success,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
        const SizedBox(width: 3),

        // Bar info
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: colors.info,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
      ],
    );
  }
}
