class AppStartup {
  /// Future de inicialización de servicios iniciados antes o justo después
  /// de llamar a `runApp`. Puede ser null si no hay nada que esperar.
  static Future<void>? supabaseInitFuture;
}
