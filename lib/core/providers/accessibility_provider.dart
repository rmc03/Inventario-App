import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Niveles de tamaño de texto disponibles
enum TextSizeLevel {
  small('Pequeño', 0.85),
  normal('Normal', 1.0),
  large('Grande', 1.15),
  extraLarge('Extra grande', 1.3),
  huge('Muy grande', 1.5);

  const TextSizeLevel(this.label, this.scale);
  final String label;
  final double scale;
}

/// Configuración de accesibilidad de la aplicación
class AccessibilitySettings {
  const AccessibilitySettings({
    this.textSizeLevel = TextSizeLevel.normal,
    this.highContrast = false,
    this.reduceAnimations = false,
    this.boldText = false,
  });

  final TextSizeLevel textSizeLevel;
  final bool highContrast;
  final bool reduceAnimations;
  final bool boldText;

  AccessibilitySettings copyWith({
    TextSizeLevel? textSizeLevel,
    bool? highContrast,
    bool? reduceAnimations,
    bool? boldText,
  }) {
    return AccessibilitySettings(
      textSizeLevel: textSizeLevel ?? this.textSizeLevel,
      highContrast: highContrast ?? this.highContrast,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      boldText: boldText ?? this.boldText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'textSizeLevel': textSizeLevel.name,
      'highContrast': highContrast,
      'reduceAnimations': reduceAnimations,
      'boldText': boldText,
    };
  }

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      textSizeLevel: TextSizeLevel.values.firstWhere(
        (e) => e.name == json['textSizeLevel'],
        orElse: () => TextSizeLevel.normal,
      ),
      highContrast: json['highContrast'] as bool? ?? false,
      reduceAnimations: json['reduceAnimations'] as bool? ?? false,
      boldText: json['boldText'] as bool? ?? false,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

const String _accessibilityKey = 'accessibility_settings';

final accessibilityProvider =
    NotifierProvider<AccessibilityNotifier, AccessibilitySettings>(() {
  return AccessibilityNotifier();
});

class AccessibilityNotifier extends Notifier<AccessibilitySettings> {
  @override
  AccessibilitySettings build() {
    _loadSettings();
    return const AccessibilitySettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_accessibilityKey);
    if (jsonString != null) {
      try {
        final json = <String, dynamic>{
          'textSizeLevel': prefs.getString('${_accessibilityKey}_textSize') ?? 'normal',
          'highContrast': prefs.getBool('${_accessibilityKey}_highContrast') ?? false,
          'reduceAnimations': prefs.getBool('${_accessibilityKey}_reduceAnimations') ?? false,
          'boldText': prefs.getBool('${_accessibilityKey}_boldText') ?? false,
        };
        state = AccessibilitySettings.fromJson(json);
      } catch (_) {
        // Si hay error al cargar, mantener valores por defecto
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_accessibilityKey}_textSize', state.textSizeLevel.name);
    await prefs.setBool('${_accessibilityKey}_highContrast', state.highContrast);
    await prefs.setBool('${_accessibilityKey}_reduceAnimations', state.reduceAnimations);
    await prefs.setBool('${_accessibilityKey}_boldText', state.boldText);
  }

  Future<void> setTextSizeLevel(TextSizeLevel level) async {
    state = state.copyWith(textSizeLevel: level);
    await _saveSettings();
  }

  Future<void> setHighContrast(bool enabled) async {
    state = state.copyWith(highContrast: enabled);
    await _saveSettings();
  }

  Future<void> setReduceAnimations(bool enabled) async {
    state = state.copyWith(reduceAnimations: enabled);
    await _saveSettings();
  }

  Future<void> setBoldText(bool enabled) async {
    state = state.copyWith(boldText: enabled);
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = const AccessibilitySettings();
    await _saveSettings();
  }
}

// ─── Helper Extensions ────────────────────────────────────────────────────────

extension AccessibilityContext on BuildContext {
  AccessibilitySettings get accessibility => 
      ProviderScope.containerOf(this).read(accessibilityProvider);
  
  double get textScale => accessibility.textSizeLevel.scale;
  
  bool get highContrast => accessibility.highContrast;
  
  bool get reduceAnimations => accessibility.reduceAnimations;
  
  bool get boldText => accessibility.boldText;
  
  /// Duración de animación ajustada según preferencias de accesibilidad
  Duration animationDuration(Duration standard) {
    if (reduceAnimations) {
      return Duration.zero;
    }
    return standard;
  }
}
