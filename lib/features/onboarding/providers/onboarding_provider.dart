import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_color_schemes.dart';

/// Estado del onboarding
class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.hasCompletedOnboarding = false,
    this.selectedTheme,
    this.selectedBrightness,
  });

  final int currentPage;
  final bool hasCompletedOnboarding;
  final AppColorScheme? selectedTheme;
  final Brightness? selectedBrightness;

  OnboardingState copyWith({
    int? currentPage,
    bool? hasCompletedOnboarding,
    AppColorScheme? selectedTheme,
    Brightness? selectedBrightness,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      selectedBrightness: selectedBrightness ?? this.selectedBrightness,
    );
  }
}

/// Notifier para el estado del onboarding
class OnboardingNotifier extends Notifier<OnboardingState> {
  static const _keyCompleted = 'onboarding_completed';

  @override
  OnboardingState build() {
    _loadCompletionStatus();
    return const OnboardingState();
  }

  Future<void> _loadCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_keyCompleted) ?? false;
    state = state.copyWith(hasCompletedOnboarding: completed);
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void selectTheme(AppColorScheme scheme) {
    state = state.copyWith(selectedTheme: scheme);
  }

  void selectBrightness(Brightness brightness) {
    state = state.copyWith(selectedBrightness: brightness);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompleted, true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCompleted);
    state = const OnboardingState();
  }
}

/// Provider del estado de onboarding
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

/// Provider para verificar si debe mostrar onboarding
final shouldShowOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final completed = prefs.getBool('onboarding_completed') ?? false;
  return !completed;
});
