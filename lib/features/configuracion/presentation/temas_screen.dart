import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_color_schemes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';

const _kEntranceDuration = Duration(milliseconds: 400);
const _kStaggerInterval = Duration(milliseconds: 60);

class TemasScreen extends ConsumerStatefulWidget {
  const TemasScreen({super.key});

  @override
  ConsumerState<TemasScreen> createState() => _TemasScreenState();
}

class _TemasScreenState extends ConsumerState<TemasScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _cardFades;
  late final List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();

    // 1 selector de modo + 1 título + 6 esquemas de color = 8 tarjetas
    final cardCount = AppColorScheme.values.length + 2;
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: _kEntranceDuration + _kStaggerInterval * (cardCount - 1),
    );

    _cardFades = List.generate(cardCount, (i) {
      final start = i *
          (_kStaggerInterval.inMilliseconds /
              _entranceCtrl.duration!.inMilliseconds);
      final end = (start +
              _kEntranceDuration.inMilliseconds /
                  _entranceCtrl.duration!.inMilliseconds)
          .clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _cardSlides = List.generate(cardCount, (i) {
      final start = i *
          (_kStaggerInterval.inMilliseconds /
              _entranceCtrl.duration!.inMilliseconds);
      final end = (start +
              _kEntranceDuration.inMilliseconds /
                  _entranceCtrl.duration!.inMilliseconds)
          .clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
          .animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reduceMotion = MediaQuery.of(context).disableAnimations;
        if (reduceMotion) {
          _entranceCtrl.value = 1;
        } else {
          _entranceCtrl.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Widget _staggeredCard(int index, Widget child) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([_cardFades[index], _cardSlides[index]]),
      builder: (context, _) => FadeTransition(
        opacity: _cardFades[index],
        child: SlideTransition(
          position: _cardSlides[index],
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentScheme = ref.watch(colorSchemeProvider);
    final currentMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personaliza tu tema'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // Sección de modo (claro/oscuro/auto)
                _staggeredCard(
                  0,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.sunMoon,
                              size: 20,
                              color: context.colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MODO',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: context.colors.muted,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _BrightnessModeSelector(currentMode: currentMode),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Sección de esquemas de color
                _staggeredCard(
                  1,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.palette,
                          size: 20,
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PALETA DE COLORES',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: context.colors.muted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Grid de esquemas de color
                ...List.generate(
                  AppColorScheme.values.length,
                  (i) {
                    final scheme = AppColorScheme.values[i];
                    return _staggeredCard(
                      i + 2,
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ColorSchemeCard(
                          scheme: scheme,
                          isSelected: currentScheme == scheme,
                          onTap: () {
                            ref
                                .read(colorSchemeProvider.notifier)
                                .setColorScheme(scheme);
                            Haptics.confirm(context);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Selector de modo (claro/oscuro/automático)
// ══════════════════════════════════════════════════════════════════════════════
class _BrightnessModeSelector extends ConsumerWidget {
  const _BrightnessModeSelector({required this.currentMode});

  final ThemeMode currentMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: LucideIcons.sun,
            label: 'Claro',
            isSelected: currentMode == ThemeMode.light,
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.light);
              Haptics.tap(context);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
            icon: LucideIcons.moon,
            label: 'Oscuro',
            isSelected: currentMode == ThemeMode.dark,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
              Haptics.tap(context);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
            icon: LucideIcons.sunMedium,
            label: 'Automático',
            isSelected: currentMode == ThemeMode.system,
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.system);
              Haptics.tap(context);
            },
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatefulWidget {
  const _ModeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.94), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1), weight: 50),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _tapScale,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: widget.isSelected
            ? context.colors.primary
            : context.colors.surface,
        elevation: widget.isSelected ? 2 : 0,
        shadowColor: context.colors.primary.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () {
            _tapCtrl.forward(from: 0);
            widget.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                Icon(
                  widget.icon,
                  size: 32,
                  color: widget.isSelected
                      ? Colors.white
                      : context.colors.ink,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: widget.isSelected
                            ? Colors.white
                            : context.colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tarjeta de esquema de color
// ══════════════════════════════════════════════════════════════════════════════
class _ColorSchemeCard extends StatefulWidget {
  const _ColorSchemeCard({
    required this.scheme,
    required this.isSelected,
    required this.onTap,
  });

  final AppColorScheme scheme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ColorSchemeCard> createState() => _ColorSchemeCardState();
}

class _ColorSchemeCardState extends State<_ColorSchemeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.97), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1), weight: 50),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = brightness == Brightness.light
        ? widget.scheme.light
        : widget.scheme.dark;

    return ScaleTransition(
      scale: _tapScale,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: widget.isSelected ? 4 : 0,
        shadowColor: colors.primary.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: widget.isSelected
              ? BorderSide(color: colors.primary, width: 3)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            _tapCtrl.forward(from: 0);
            widget.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icono del tema
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.scheme.icon,
                    size: 32,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 16),

                // Información del tema
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.scheme.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (widget.isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Activo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.scheme.description,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.colors.muted,
                                ),
                      ),
                      const SizedBox(height: 12),

                      // Muestra de colores
                      Row(
                        children: [
                          _ColorDot(color: colors.primary),
                          const SizedBox(width: 6),
                          _ColorDot(color: colors.success),
                          const SizedBox(width: 6),
                          _ColorDot(color: colors.warning),
                          const SizedBox(width: 6),
                          _ColorDot(color: colors.info),
                          const SizedBox(width: 6),
                          _ColorDot(color: colors.danger),
                        ],
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
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colors.line,
          width: 1,
        ),
      ),
    );
  }
}
