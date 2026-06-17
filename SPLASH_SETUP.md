# Configuración del splash nativo

He añadido una configuración básica para `flutter_native_splash` en `pubspec.yaml` y ajustes iniciales en los drawables nativos para evitar la pantalla negra en el arranque.

Qué hice
- Color nativo de fondo: `#F2F2F7` (coincide con `AppColors.background`).
- `android` y `ios` habilitados en la configuración de `flutter_native_splash`.
- Los drawables nativos (`android/app/src/main/res/drawable*/launch_background.xml`) ahora usan `@mipmap/ic_launcher` centrado como splash por defecto.
- Añadí un `SplashOverlay` interno para cubrir la UI hasta que inicien los servicios en background.

Pasos para generar/actualizar el splash nativo (tú los ejecutas)
1. Instala dependencias:

```bash
flutter pub get
```

2. Genera los recursos nativos con `flutter_native_splash`:

```bash
flutter pub run flutter_native_splash:create
```

3. (Opcional) Si quieres un logo personalizado en lugar de `ic_launcher`:
- Coloca tu imagen en `assets/splash.png` (recomiendo 1024×1024 PNG)
- Añade en `pubspec.yaml` dentro de `flutter:` la sección `assets:` si no existe:

```yaml
flutter:
  assets:
    - assets/splash.png
```

- Modifica la sección `flutter_native_splash` en `pubspec.yaml` para indicar la ruta:

```yaml
flutter_native_splash:
  image: "assets/splash.png"
  color: "#F2F2F7"
  android: true
  ios: true
```

- Vuelve a ejecutar:

```bash
flutter pub get
flutter pub run flutter_native_splash:create
```

Notas y recomendaciones
- Genera y prueba en `--release` para ver el comportamiento real de cold start.
- `flutter_native_splash` actualiza archivos nativos; si haces cambios manuales en `android/*` o `ios/*`, revisa antes de sobrescribir.
- Si usas Android 12+, la librería habilita la API de SplashScreen nativa cuando procede.

Si quieres, puedo:
- añadir el asset `assets/splash.png` de ejemplo (placeholder) en el repo,
- o actualizar la configuración para usar directamente `ic_launcher` como imagen por parte de `flutter_native_splash` (requiere pasos manuales después de generar).

Dime si prefieres que cree un `assets/splash.png` de ejemplo o que deje todo tal cual para que ejecutes los comandos en tu máquina.