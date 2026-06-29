# Inventario App

Aplicación móvil de gestión de inventario y punto de venta (POS) para tiendas retail locales. Permite a un administrador gestionar productos, categorías y usuarios, mientras que los dependientes registran ventas durante su turno y generan cuadres de cierre para revisión del jefe.

> **Estado actual (junio 2026):** La app funciona como prototipo offline-first con datos de demostración. La capa de Supabase está preparada pero desconectada por defecto; los datos de productos, ventas, cuadres y turno viven en memoria mientras que usuarios y movimientos se persisten en SQLite local. Ver sección [Estado actual vs. roadmap](#estado-actual-vs-roadmap).

## Stack Tecnológico

| Componente | Tecnología |
|---|---|
| Framework | Flutter 3.12.1+ (Dart) |
| Estado | flutter_riverpod |
| Navegación | go_router con redirección por rol |
| Base de datos local | sqflite (SQLite) |
| Backend remoto | Supabase (Auth + PostgreSQL + Storage) — desconectado por defecto |
| Conectividad | connectivity_plus |
| UI | Material 3 con tema inspirado en iOS |
| Utilidades | uuid, intl, image_picker, cached_network_image |

## Características Principales

- **Gestión de productos** con categorías, fotos locales, alertas de stock bajo, búsqueda y filtros.
- **Punto de venta (POS)** para dependientes: selección de productos, cantidades, carrito y confirmación de pago.
- **Registro automático de movimientos** de salida por cada venta completada.
- **Cuadres de turno**: el dependiente cierra su turno y envía un resumen de ventas pendiente de aprobación.
- **Aprobación/rechazo de cuadres** por parte del admin; al rechazar se revierte el stock descontado.
- **Historial de movimientos** para el admin, con vistas por producto o por venta.
- **Modo offline parcial**: SQLite local para usuarios y movimientos; la app no se detiene si no hay internet.
- **Dos roles**: Admin (control total) y Dependiente (ventas + consulta de inventario).
- **Indicador de conexión** discreto en todas las pantallas.

## Roles de Usuario

| Rol | Permisos |
|---|---|
| **Admin** | CRUD de productos y categorías; gestión de dependientes; historial de movimientos; aprobar/rechazar cuadres. |
| **Dependiente** | Iniciar/cerrar turno; registrar ventas POS; consultar inventario en solo lectura; ver resumen de su turno. |

## Flujo de Trabajo

```
Dependiente
  ├── Inicia turno
  ├── Registra una o varias ventas (productos + pago)
  ├── Cada venta descuenta stock y genera movimiento de salida
  └── Cierra turno → genera cuadre pendiente

Admin
  ├── Revisa cuadres pendientes
  ├── Aprueba (stock ya descontado)
  └── Rechaza con comentario → stock revertido
```

## Estado Actual vs. Roadmap

| Área | Estado actual | Roadmap |
|---|---|---|
| Autenticación | Simulada localmente (selector de rol en login) | Conectar con Supabase Auth |
| Productos/categorías | En memoria con datos demo | Persistir en SQLite y sincronizar con Supabase |
| Ventas | En memoria (se pierden al cerrar app) | Persistir en SQLite + sync |
| Cuadres | En memoria con un cuadre demo | Persistir en SQLite + sync |
| Turno | En memoria | Persistir en SQLite |
| Movimientos | SQLite local | Sync bidireccional con Supabase |
| Usuarios | SQLite local | Sync con Supabase Auth + tabla `usuarios` |
| Sincronización | Placeholder (`SyncService`) no operativo | Implementar sync offline→online con cola de cambios |
| Pagos | Efectivo / Transferencia | Historial de pagos, cierre de caja |
| Reportes | Básico en pantallas | PDF/Excel, gráficos de ventas |

## Requisitos Previos

- Flutter SDK >= 3.12.1
- Android Studio o VS Code con plugins de Flutter
- (Opcional) Cuenta en [Supabase](https://supabase.com/) para habilitar backend remoto

## Instalación

1. Clona el repositorio:
   ```bash
   git clone <url-del-repositorio>
   cd inventario_app
   ```

2. Instala dependencias:
   ```bash
   flutter pub get
   ```

3. Ejecuta la app en modo demo (sin Supabase):
   ```bash
   flutter run
   ```

4. Para conectar Supabase, pasa las credenciales al compilar:
   ```bash
   flutter run --dart-define=SUPABASE_URL=TU_SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=TU_SUPABASE_ANON_KEY
   ```

## Estructura del Proyecto

```
lib/
├── main.dart                           # Entry point
├── app.dart                            # MaterialApp + Riverpod + GoRouter + splash overlay
├── core/
│   ├── router/app_router.dart          # Rutas y redirección por rol
│   ├── theme/app_theme.dart            # Tema visual (paleta iOS)
│   ├── theme/app_dimens.dart           # Tokens de espaciado, radios, sombras
│   ├── supabase/                       # Bootstrap y config de Supabase
│   ├── local_db/                       # Configuración de SQLite + sync service
│   └── utils/                          # Conectividad y formateadores
├── features/
│   ├── auth/                           # Login y autenticación simulada
│   ├── inventario/                     # CRUD de productos y categorías
│   ├── movimientos/                    # Historial de movimientos
│   ├── turno/                          # Mi turno (dependiente) + cierre
│   ├── cuadres/                        # Panel de aprobación de cuadres
│   ├── ventas/                         # Flujo POS: nueva venta, pago y detalle
│   ├── usuarios/                       # Gestión de dependientes
│   └── configuracion/                  # Pantalla de ajustes
└── shared/
    ├── models/                         # Modelos de datos
    └── widgets/                        # Componentes reutilizables
```

## Variables de Entorno

Las credenciales de Supabase se leen desde variables de entorno al compilar:

```bash
--dart-define=SUPABASE_URL=https://xxxx.supabase.co
--dart-define=SUPABASE_ANON_KEY=eyJ...
```

En el código se encuentran en `lib/core/supabase/supabase_config.dart`. Si no se proporcionan, la app arranca en modo demo/offline.

## Datos de Demostración

La app incluye productos de ejemplo relacionados con motocicletas:

- Casco Integral Shoei GT-Air II
- Kit de Cadena 520 DID
- Guantes Alpinestars SP-8
- Aceite Motul 5100 10W-40
- Cubre Tanque Universal

Para probar como **Admin** usa el email sugerido `admin@inventario.local`.  
Para probar como **Dependiente** usa `dependiente@inventario.local`. La contraseña es meramente ilustrativa.

## Tests

El proyecto tiene cobertura de test inicial. Para ejecutarlos:

```bash
flutter test
```

## Plataformas

- Android (distribución principal vía APK directa)
- iOS, Web, Linux, macOS, Windows (soporte Flutter estándar)

## Documentación Adicional

- [ARQUITECTURA.md](ARQUITECTURA.md) — Documentación técnica detallada: modelos, navegación, schema SQL objetivo, flujo POS y estado de implementación.
- [PROMOCION.md](PROMOCION.md) — Análisis comercial para MiPymes cubanas.
- [SPLASH_SETUP.md](SPLASH_SETUP.md) — Configuración del splash nativo.
