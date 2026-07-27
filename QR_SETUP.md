# 🚀 Setup Rápido - QRs de Pago

## ¿Qué se implementó?

Sistema completo para que dependientes muestren códigos QR bancarios a clientes en el flujo de venta. Pensado para el contexto cubano donde las transferencias se hacen escaneando QRs de apps bancarias.

## Estado Actual: ✅ LISTO PARA PROBAR

Todo el código está implementado y sin errores. Solo faltan 3 pasos para probarlo:

---

## Paso 1: Agregar dependencia (1 minuto)

Abre `pubspec.yaml` y agrega bajo `dependencies`:

```yaml
dependencies:
  # ... tus dependencias actuales ...
  image_picker: ^1.0.7
```

Luego ejecuta:
```bash
flutter pub get
```

---

## Paso 2: Configurar permisos nativos (2 minutos)

### Android
Abre `android/app/src/main/AndroidManifest.xml` y agrega dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

### iOS
Abre `ios/Runner/Info.plist` y agrega antes del `</dict>` final:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a tu galería para seleccionar imágenes de QR</string>
```

---

## Paso 3: Agregar entrada en menú de Configuración (3 minutos)

Busca tu pantalla de Configuración (probablemente en `lib/features/configuracion/`) y agrega un nuevo `ListTile`:

```dart
import '../qr_pagos/presentation/gestionar_qrs_screen.dart';

// ... dentro de tu lista de opciones:

ListTile(
  leading: Icon(Icons.qr_code_2_rounded),
  title: Text('Mis QRs de pago'),
  subtitle: Text('Gestiona tus códigos QR para transferencias'),
  trailing: Icon(Icons.chevron_right_rounded),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GestionarQrsScreen(),
      ),
    );
  },
),
```

---

## 🎉 ¡Listo! Ahora puedes probar

### Flujo de prueba completo:

1. **Configura un QR:**
   - Abre la app
   - Ve a Configuración → "Mis QRs de pago"
   - Toca el botón flotante "Agregar QR"
   - Pon un nombre (ej: "Mi Cuenta BPA")
   - Selecciona una imagen de QR de tu galería
   - Guarda

2. **Úsalo en una venta:**
   - Crea una nueva venta
   - Agrega productos
   - Ve a "Confirmar pago"
   - Selecciona "Transferencia" o "Mixto"
   - Verás un botón "Mostrar QR para pago"
   - Tócalo para ver tu QR en pantalla completa
   - Cierra el modal y confirma la venta

### Funcionalidades disponibles:

✅ Crear hasta 5 QRs personales  
✅ Editar nombre y cambiar imagen  
✅ Eliminar QRs  
✅ Admin puede crear QRs compartidos (visibles para todos)  
✅ Modal fullscreen para mostrar QR grande  
✅ Selector cuando tienes múltiples QRs  
✅ Muestra el monto a transferir  
✅ Funciona offline (todo en memoria por ahora)  

---

## ¿Problemas?

### "No encuentro image_picker"
- Verifica que ejecutaste `flutter pub get`
- Reinicia el IDE (VS Code/Android Studio)

### "Permission denied al seleccionar imagen"
- Verifica que agregaste los permisos en AndroidManifest.xml o Info.plist
- En Android 13+, puede pedir permisos en runtime

### "No veo el botón Mostrar QR"
- Verifica que seleccionaste modo "Transferencia" o "Mixto"
- En modo Mixto, solo aparece si el monto de transferencia > 0
- Asegúrate de haber creado al menos 1 QR

---

## Próximamente (cuando migres a producción)

Cuando quieras pasar de in-memory a persistencia real:

1. **Con Supabase:** Reemplazar el repository in-memory con versión Supabase (ya tengo el SQL listo)
2. **Solo SQLite:** Crear tablas locales y guardar QRs ahí
3. **Híbrido:** SQLite local + sync con Supabase cuando hay internet

Por ahora, los QRs solo viven mientras la app está abierta. Al cerrar la app, se pierden. Esto es perfecto para desarrollo y pruebas.

---

## Archivos importantes (por si necesitas modificar algo)

- **Modelo:** `lib/shared/models/qr_pago.dart`
- **Lógica:** `lib/features/qr_pagos/data/qr_pago_repository.dart`
- **Modal QR:** `lib/features/qr_pagos/presentation/qr_display_modal.dart`
- **Gestión:** `lib/features/qr_pagos/presentation/gestionar_qrs_screen.dart`
- **Integración ventas:** Ya modificado en `lib/features/ventas/presentation/confirmar_pago_screen.dart`

---

**Documentación completa:** Ver `IMPLEMENTACION_QR.md`

¡Cualquier duda, solo pregunta! 🚀
