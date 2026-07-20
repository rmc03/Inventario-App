import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla si la vibración en botones está activada. Persiste la preferencia
/// en `shared_preferences` para que sobreviva a reinicios de la app.
final hapticsEnabledProvider = NotifierProvider<HapticsSettingsNotifier, bool>(
  HapticsSettingsNotifier.new,
);

class HapticsSettingsNotifier extends Notifier<bool> {
  static const _key = 'haptics_enabled';

  @override
  bool build() {
    // Carga asíncrona; mientras tanto se asume activado (default).
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  void setEnabled(bool value) {
    state = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_key, value),
    );
  }
}

/// Ayudantes de feedback háptico. Usan `HapticFeedback` (nativo, sin
/// dependencias extra) y respetan el toggle de Ajustes vía [BuildContext].
class Haptics {
  const Haptics._();

  /// Impacto ligero: acciones normales (ej. iniciar sesión, crear producto).
  static void tap(BuildContext context) =>
      _fire(context, HapticFeedback.lightImpact);

  /// Impacto medio: confirmaciones (ej. cobrar, guardar, aprobar).
  static void confirm(BuildContext context) =>
      _fire(context, HapticFeedback.mediumImpact);

  /// Impacto fuerte: acciones destructivas (ej. eliminar, rechazar).
  static void warning(BuildContext context) =>
      _fire(context, HapticFeedback.heavyImpact);

  static void _fire(
    BuildContext context,
    Future<void> Function() feedback,
  ) {
    final enabled = ProviderScope.containerOf(context).read(
      hapticsEnabledProvider,
    );
    if (enabled) {
      feedback();
    }
  }
}
