# Inventario App

Aplicación móvil de gestión de inventario para tienda retail local. Permite a un admin y dependientes gestionar productos, registrar movimientos de entrada/salida, y generar cuadres de turno con soporte offline.

## Stack Tecnológico

| Componente | Tecnología |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| Offline | sqflite (SQLite local) con sync automático |
| Estado | flutter_riverpod |
| Navegación | go_router con redirección por rol |
| Conectividad | connectivity_plus |

## Características Principales

- **Gestión de productos** con categorías, fotos, alertas de stock bajo y búsqueda
- **Registro de movimientos** (entradas/salidas) por dependiente
- **Cuadres de turno** con aprobación/rechazo del admin
- **Modo offline** — funciona sin internet, sincroniza automáticamente al reconectar
- **Dos roles**: Admin (control total) y Dependiente (consulta + movimientos)
- **Indicador de conexión** visible en todas las pantallas

## Requisitos Previos

- Flutter SDK >= 3.12.1
- Cuenta en [Supabase](https://supabase.com/) con un proyecto creado
- Android Studio o VS Code con plugins de Flutter

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

3. Configura las variables de entorno creando el archivo `lib/core/supabase/supabase_config.dart`:
   ```dart
   class SupabaseConfig {
     static const String url = 'TU_SUPABASE_URL';
     static const String anonKey = 'TU_SUPABASE_ANON_KEY';
   }
   ```

4. Ejecuta la app:
   ```bash
   flutter run
   ```

## Estructura del Proyecto

```
lib/
├── main.dart                           # Entry point
├── app.dart                            # MaterialApp + Riverpod + GoRouter
├── core/
│   ├── router/app_router.dart          # Rutas y redirección por rol
│   ├── theme/
│   │   ├── app_theme.dart              # Tema visual de la app
│   │   └── app_dimens.dart             # Constantes de dimensiones
│   ├── supabase/                       # Configuración de Supabase
│   ├── local_db/                       # SQLite + servicio de sincronización
│   └── utils/                          # Conectividad y formateadores
├── features/
│   ├── auth/                           # Login y autenticación
│   ├── inventario/                     # CRUD de productos y categorías
│   ├── movimientos/                    # Historial de movimientos
│   ├── turno/                          # Mi turno (dependiente) + cierre
│   ├── cuadres/                        # Panel de aprobación de cuadres
│   └── configuracion/                  # Gestión de usuarios y categorías
└── shared/
    ├── models/                         # Modelos de datos
    └── widgets/                        # Componentes reutilizables
```

Cada feature sigue la arquitectura **data / providers / presentation** con repositorios para Supabase y SQLite.

## Roles de Usuario

| Rol | Permisos |
|---|---|
| **Admin** | CRUD productos, ver movimientos, aprobar/rechazar cuadres, gestionar usuarios y categorías |
| **Dependiente** | Consultar inventario, registrar movimientos, cerrar turno |

## Variables de Entorno

El archivo `lib/core/supabase/supabase_config.dart` debe contener las credenciales de tu proyecto Supabase. **No commitees este archivo** — está incluido en `.gitignore`.

## Documentación

- [ARQUITECTURA.md](ARQUITECTURA.md) — Documentación técnica detallada: esquema de base de datos, RLS, flujo offline, navegación por roles y más.

## Plataformas

- Android (distribución principal vía APK directa)
- iOS, Web, Linux, macOS, Windows (soporte Flutter estándar)
