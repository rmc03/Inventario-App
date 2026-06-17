import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/app_startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Iniciar la app inmediatamente para que Flutter dibuje el primer frame
  // y se retire el tema de lanzamiento nativo. Inicializamos Supabase en
  // segundo plano para evitar bloquear la pantalla de arranque.
  runApp(const ProviderScope(child: InventarioApp()));

  // Inicialización en background (no await) para no retrasar el primer frame.
  // Guardamos la Future en `AppStartup` para que la UI pueda ocultar el
  // splash interno cuando termine (sin bloquear el primer frame).
  AppStartup.supabaseInitFuture = initializeSupabaseIfConfigured();
}
