import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../providers/onboarding_provider.dart';
import 'pages/welcome_page.dart';
import 'pages/inventory_interactive_page.dart';
import 'pages/sales_interactive_page.dart';
import 'pages/shifts_demo_page.dart';
import 'pages/theme_picker_page.dart';
import 'pages/ready_page.dart';
import 'widgets/page_indicator.dart';
import 'widgets/skip_button.dart';

/// Pantalla principal de onboarding con PageView
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  final int _pageCount = 6;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
      ref.read(onboardingProvider.notifier).setPage(page);
    }
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      Haptics.tap(context);
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    Haptics.tap(context);
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Skip button y página actual (solo en primeras 4 páginas)
            if (_currentPage < 4)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Placeholder para balance
                    const SizedBox(width: 80),

                    // Indicador de página
                    PageIndicator(
                      currentPage: _currentPage,
                      pageCount: _pageCount,
                    ),

                    // Botón Skip
                    SkipButton(onPressed: _skipOnboarding),
                  ],
                ),
              )
            else
              const SizedBox(height: AppSpacing.lg),

            // PageView con las páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                children: const [
                  WelcomePage(),
                  InventoryInteractivePage(),
                  SalesInteractivePage(),
                  ShiftsDemoPage(),
                  ThemePickerPage(),
                  ReadyPage(),
                ],
              ),
            ),

            // Footer: Botón de navegación
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _NavigationButton(
                currentPage: _currentPage,
                pageCount: _pageCount,
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de navegación que cambia según la página
class _NavigationButton extends StatefulWidget {
  const _NavigationButton({
    required this.currentPage,
    required this.pageCount,
    required this.onPressed,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onPressed;

  @override
  State<_NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<_NavigationButton> {
  bool _isPressed = false;

  String get _buttonText {
    if (widget.currentPage == widget.pageCount - 1) {
      return 'Comenzar';
    }
    return 'Continuar';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withAlpha(76), // 0.3
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                child: Text(_buttonText),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
