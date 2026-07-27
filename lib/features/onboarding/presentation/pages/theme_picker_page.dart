import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_schemes.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/haptics.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/theme_card.dart';

/// Página 5: Selector de tema con preview en tiempo real
class ThemePickerPage extends ConsumerStatefulWidget {
  const ThemePickerPage({super.key});

  @override
  ConsumerState<ThemePickerPage> createState() => _ThemePickerPageState();
}

class _ThemePickerPageState extends ConsumerState<ThemePickerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectTheme(AppColorScheme scheme) {
    Haptics.confirm(context);
    ref.read(colorSchemeProvider.notifier).setColorScheme(scheme);
    ref.read(onboardingProvider.notifier).selectTheme(scheme);
  }

  void _toggleBrightness() {
    Haptics.tap(context);
    final currentMode = ref.read(themeModeProvider);
    final newMode = currentMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    ref.read(themeModeProvider.notifier).setThemeMode(newMode);
    ref.read(onboardingProvider.notifier).selectBrightness(
          newMode == ThemeMode.light ? Brightness.light : Brightness.dark,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentScheme = ref.watch(colorSchemeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final brightness = themeMode == ThemeMode.light
        ? Brightness.light
        : Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      color: colors.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Título animado
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0, 0.3, curve: Curves.easeOut),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.ink,
                    ),
                child: const Text(
                  'Hazla tuya',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Descripción animada
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.1, 0.4, curve: Curves.easeOut),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: colors.muted,
                    ),
                child: const Text(
                  'Elige el tema que más te guste.\nCambia cuando quieras.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Toggle Light/Dark
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
              ),
              child: _BrightnessToggle(
                brightness: brightness,
                onToggle: _toggleBrightness,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Lista de temas
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                physics: const BouncingScrollPhysics(),
                itemCount: AppColorScheme.values.length,
                itemBuilder: (context, index) {
                  final scheme = AppColorScheme.values[index];
                  final delay = 0.3 + (index * 0.05);

                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: Interval(
                        delay,
                        delay + 0.2,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Interval(
                            delay,
                            delay + 0.2,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ThemeCard(
                          colorScheme: scheme,
                          isSelected: scheme == currentScheme,
                          brightness: brightness,
                          onTap: () => _selectTheme(scheme),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Toggle entre Light y Dark mode
class _BrightnessToggle extends StatelessWidget {
  const _BrightnessToggle({
    required this.brightness,
    required this.onToggle,
  });

  final Brightness brightness;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLight = brightness == Brightness.light;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withAlpha(20), // 0.08
            colors.primary.withAlpha(10), // 0.04
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: colors.primary.withAlpha(38), // 0.15
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: Icons.light_mode,
            label: 'Claro',
            isSelected: isLight,
            onTap: isLight ? null : onToggle,
          ),
          _ToggleButton(
            icon: Icons.dark_mode,
            label: 'Oscuro',
            isSelected: !isLight,
            onTap: isLight ? onToggle : null,
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatefulWidget {
  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withAlpha(51), // 0.2
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isSelected ? Colors.white : colors.muted,
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isSelected ? Colors.white : colors.muted,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
