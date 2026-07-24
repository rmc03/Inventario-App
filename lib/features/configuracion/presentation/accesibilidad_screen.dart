import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/accessibility_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';

class AccesibilidadScreen extends ConsumerWidget {
  const AccesibilidadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accesibilidad'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.accessibility_new_rounded,
                        size: 20,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Accesibilidad',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: context.colors.muted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.text_fields_rounded),
                        title: const Text('Tamaño de texto'),
                        subtitle: Text(accessibility.textSizeLevel.label),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showTextSizeDialog(context, ref),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        secondary: const Icon(Icons.format_bold_rounded),
                        title: const Text('Texto en negrita'),
                        subtitle: const Text('Mejora la legibilidad'),
                        value: accessibility.boldText,
                        onChanged: (v) {
                          ref
                              .read(accessibilityProvider.notifier)
                              .setBoldText(v);
                          Haptics.tap(context);
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        secondary: const Icon(Icons.animation_rounded),
                        title: const Text('Reducir animaciones'),
                        subtitle: const Text('Desactiva efectos de transición'),
                        value: accessibility.reduceAnimations,
                        onChanged: (v) {
                          ref
                              .read(accessibilityProvider.notifier)
                              .setReduceAnimations(v);
                          Haptics.tap(context);
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        secondary: const Icon(Icons.contrast_rounded),
                        title: const Text('Alto contraste'),
                        subtitle: const Text('Aumenta la visibilidad'),
                        value: accessibility.highContrast,
                        onChanged: (v) {
                          ref
                              .read(accessibilityProvider.notifier)
                              .setHighContrast(v);
                          Haptics.tap(context);
                        },
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

  Future<void> _showTextSizeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current = ref.read(accessibilityProvider).textSizeLevel;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.text_fields_rounded,
            color: context.colors.primary,
            size: 28,
          ),
        ),
        title: const Text('Tamaño de texto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TextSizeLevel.values.map((level) {
            final isSelected = level == current;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: isSelected
                    ? context.colors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref
                        .read(accessibilityProvider.notifier)
                        .setTextSizeLevel(level);
                    Haptics.tap(context);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          level.label,
                          style: TextStyle(
                            fontSize: 15 * level.scale,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.ink,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: context.colors.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
