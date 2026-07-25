# Gestión de Turnos - Consideraciones para Producción

## 🔄 Verificación Automática de Cambio de Día

### Implementación Actual (Desarrollo)
La verificación del cambio de día se realiza automáticamente cada vez que se accede a las propiedades `estaActivo`, `cuadreEnviadoHoy` o `horaInicio` del `TurnoRepository`.

**Funcionamiento:**
- Se guarda `_fechaCuadre` cuando el dependiente envía su cuadre
- Cada acceso al estado compara la fecha del cuadre con la fecha actual
- Si detecta un nuevo día, resetea automáticamente el estado

**Limitación actual:**
⚠️ Los datos se almacenan en memoria. Al cerrar la app, se pierden.

---

## 🚀 Migración a Producción

### 1. Persistencia de Datos

**Actualmente:** Datos en memoria volátil
**Producción:** Persiste en `SharedPreferences` o base de datos local

#### Implementación con SharedPreferences

```dart
import 'package:shared_preferences/shared_preferences.dart';

class TurnoRepository {
  static const _keyEstaActivo = 'turno_esta_activo';
  static const _keyHoraInicio = 'turno_hora_inicio';
  static const _keyCuadreEnviadoHoy = 'turno_cuadre_enviado_hoy';
  static const _keyFechaCuadre = 'turno_fecha_cuadre';

  bool _estaActivo = false;
  DateTime? _horaInicio;
  bool _cuadreEnviadoHoy = false;
  DateTime? _fechaCuadre;
  SharedPreferences? _prefs;

  // Cargar datos al inicializar
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _estaActivo = _prefs?.getBool(_keyEstaActivo) ?? false;
    _cuadreEnviadoHoy = _prefs?.getBool(_keyCuadreEnviadoHoy) ?? false;
    
    final horaInicioMs = _prefs?.getInt(_keyHoraInicio);
    if (horaInicioMs != null) {
      _horaInicio = DateTime.fromMillisecondsSinceEpoch(horaInicioMs);
    }
    
    final fechaCuadreMs = _prefs?.getInt(_keyFechaCuadre);
    if (fechaCuadreMs != null) {
      _fechaCuadre = DateTime.fromMillisecondsSinceEpoch(fechaCuadreMs);
    }
    
    // Verificar cambio de día al cargar
    _verificarCambioDeDia();
  }

  Future<void> iniciarTurno() async {
    _estaActivo = true;
    _horaInicio = DateTime.now();
    _cuadreEnviadoHoy = false;
    _fechaCuadre = null;

    await _prefs?.setBool(_keyEstaActivo, true);
    await _prefs?.setInt(_keyHoraInicio, _horaInicio!.millisecondsSinceEpoch);
    await _prefs?.setBool(_keyCuadreEnviadoHoy, false);
    await _prefs?.remove(_keyFechaCuadre);
  }

  Future<void> enviarCuadre() async {
    _estaActivo = false;
    _cuadreEnviadoHoy = true;
    _fechaCuadre = DateTime.now();

    await _prefs?.setBool(_keyEstaActivo, false);
    await _prefs?.setBool(_keyCuadreEnviadoHoy, true);
    await _prefs?.setInt(_keyFechaCuadre, _fechaCuadre!.millisecondsSinceEpoch);
  }

  Future<void> resetearDia() async {
    _cuadreEnviadoHoy = false;
    _fechaCuadre = null;

    await _prefs?.setBool(_keyCuadreEnviadoHoy, false);
    await _prefs?.remove(_keyFechaCuadre);
  }

  void _verificarCambioDeDia() {
    if (_fechaCuadre == null || !_cuadreEnviadoHoy) {
      return;
    }

    final ahora = DateTime.now();
    final fechaCuadreSoloDia = DateTime(
      _fechaCuadre!.year,
      _fechaCuadre!.month,
      _fechaCuadre!.day,
    );
    final hoyDia = DateTime(ahora.year, ahora.month, ahora.day);

    if (fechaCuadreSoloDia.isBefore(hoyDia)) {
      resetearDia();
    }
  }

  // Getters con verificación automática
  bool get estaActivo {
    _verificarCambioDeDia();
    return _estaActivo;
  }

  DateTime? get horaInicio {
    _verificarCambioDeDia();
    return _horaInicio;
  }

  bool get cuadreEnviadoHoy {
    _verificarCambioDeDia();
    return _cuadreEnviadoHoy;
  }
}
```

**Provider actualizado:**

```dart
final turnoRepositoryProvider = Provider<TurnoRepository>((ref) {
  final repo = TurnoRepository();
  // Inicializar de forma asíncrona
  repo.init();
  return repo;
});
```

---

### 2. Zonas Horarias y Sincronización

#### Consideraciones:

**Si opera en una sola ubicación:**
- Usa `DateTime.now()` directamente
- El cambio de día ocurre a medianoche local

**Si opera en múltiples zonas horarias:**
- Sincroniza con hora del servidor
- Guarda la zona horaria del local/sucursal
- Usa `DateTime.now().toUtc()` para cálculos

```dart
// Ejemplo con zona horaria fija
final zonaHorariaLocal = 'America/Bogota'; // O la que corresponda

DateTime obtenerFechaLocal() {
  // Si usas un backend, obtén la hora del servidor
  // return DateTime.parse(response['serverTime']);
  
  // Por ahora, hora local del dispositivo
  return DateTime.now();
}
```

---

### 3. Ciclo de Vida de la App

#### Verificación al abrir/reactivar la app

Agrega un listener para verificar el cambio de día cuando la app vuelve del background:

```dart
import 'package:flutter/widgets.dart';

class TurnoRepository with WidgetsBindingObserver {
  // ... código existente ...

  void inicializarObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // La app volvió al foreground
      _verificarCambioDeDia();
    }
  }
}
```

---

### 4. Backend y Sincronización

#### Escenario de producción con backend:

**Flujo recomendado:**
1. El dependiente envía el cuadre → Se guarda en el backend con timestamp
2. El admin revisa y aprueba/rechaza → Actualiza estado en backend
3. La app consulta el estado al iniciar o cada X minutos

**Endpoints necesarios:**
- `POST /api/turnos` - Iniciar turno
- `POST /api/turnos/{id}/cuadre` - Enviar cuadre
- `GET /api/turnos/actual` - Consultar estado del turno actual
- `GET /api/cuadres/pendientes` - Para admin: ver cuadres pendientes

**Ejemplo de sincronización:**

```dart
class TurnoRepository {
  final ApiClient _api;
  
  Future<TurnoState> obtenerEstadoActual() async {
    try {
      final response = await _api.get('/api/turnos/actual');
      
      // El backend indica si el cuadre del día de hoy ya fue enviado
      return TurnoState(
        estaActivo: response['activo'],
        cuadreEnviadoHoy: response['cuadre_enviado_hoy'],
        horaInicio: response['hora_inicio'] != null 
          ? DateTime.parse(response['hora_inicio']) 
          : null,
      );
    } catch (e) {
      // Si no hay conexión, usa datos locales
      return _obtenerEstadoLocal();
    }
  }
}
```

---

### 5. Testing

#### Escenarios críticos a probar:

1. **Cambio de día mientras la app está abierta**
   - Abrir app a las 23:50, esperar hasta 00:10
   - Verificar que el estado se resetea

2. **Cambio de día con app cerrada**
   - Enviar cuadre un día
   - Cerrar completamente la app
   - Abrir al día siguiente
   - Verificar estado limpio

3. **Cambio de fecha del sistema**
   - Simular cambio manual de fecha
   - Verificar comportamiento correcto

4. **Sin conexión a internet**
   - Enviar cuadre sin conexión
   - Sincronizar cuando vuelva conexión

```dart
// test/features/turno/turno_repository_test.dart
void main() {
  group('TurnoRepository - Cambio de día', () {
    test('Debe resetear cuadre cuando pasa un día', () {
      final repo = TurnoRepository();
      
      // Simular cuadre enviado ayer
      repo.enviarCuadre();
      // Mock de _fechaCuadre = ayer
      
      // Verificar que hoy se resetea
      expect(repo.cuadreEnviadoHoy, false);
    });
  });
}
```

---

### 6. Monitoreo y Logs

Para producción, agrega logs que ayuden a debuggear:

```dart
import 'package:logger/logger.dart';

class TurnoRepository {
  final _logger = Logger();
  
  void _verificarCambioDeDia() {
    if (_fechaCuadre == null || !_cuadreEnviadoHoy) {
      return;
    }

    final ahora = DateTime.now();
    final fechaCuadreSoloDia = DateTime(
      _fechaCuadre!.year,
      _fechaCuadre!.month,
      _fechaCuadre!.day,
    );
    final hoyDia = DateTime(ahora.year, ahora.month, ahora.day);

    if (fechaCuadreSoloDia.isBefore(hoyDia)) {
      _logger.i('Cambio de día detectado. Reseteando cuadre.');
      _logger.d('Fecha cuadre: $fechaCuadreSoloDia, Hoy: $hoyDia');
      resetearDia();
    }
  }
}
```

---

## 📋 Checklist Pre-Lanzamiento

- [ ] Implementar SharedPreferences para persistencia
- [ ] Agregar listener de ciclo de vida de la app
- [ ] Definir zona horaria o usar hora del servidor
- [ ] Implementar sincronización con backend (si aplica)
- [ ] Escribir tests unitarios para cambio de día
- [ ] Escribir tests de integración para flujo completo
- [ ] Probar manualmente los 4 escenarios críticos
- [ ] Agregar logging para monitoreo en producción
- [ ] Documentar API endpoints (si hay backend)
- [ ] Definir política de respaldo en caso de desincronización

---

## 🔐 Seguridad

**Validaciones adicionales para producción:**

1. **Validar en el backend** que no se pueda:
   - Iniciar un turno si ya hay uno activo
   - Enviar cuadre sin turno activo
   - Enviar múltiples cuadres el mismo día

2. **Token de sesión:**
   - Cada turno debe tener un ID único
   - Vincular turno con el usuario autenticado
   - Invalidar tokens antiguos

3. **Auditoría:**
   - Registrar todos los eventos de turno (inicio, cierre, modificaciones)
   - Guardar IP, dispositivo, timestamp
   - Permitir al admin ver historial completo

---

## 📱 UX Mejorada (Opcional)

Una vez que la lógica de cambio de día funcione, considera:

1. **Notificación cuando se resetea el estado**
   ```dart
   if (fechaCuadreSoloDia.isBefore(hoyDia)) {
     resetearDia();
     // Mostrar snackbar: "Nuevo día iniciado. Ya puedes comenzar tu turno."
   }
   ```

2. **Badge en la navegación** indicando "Turno pendiente"

3. **Estado intermedio**: "Cuadre en revisión" vs "Cuadre aprobado"

4. **Historial de turnos anteriores** en una sección separada

---

## 🐛 Problemas Conocidos y Soluciones

### Problema: Desincronización entre app y backend
**Solución:** 
- Implementar polling cada 5 minutos
- O usar WebSockets/Firebase para actualizaciones en tiempo real

### Problema: Usuario cambia manualmente la fecha del dispositivo
**Solución:**
- Validar timestamps con el servidor
- Rechazar operaciones con fechas futuras

### Problema: App crashea durante cambio de día
**Solución:**
- Wrap `_verificarCambioDeDia()` en try-catch
- Log del error y usar estado por defecto seguro

---

**Última actualización:** 25/07/2026
**Versión actual:** Desarrollo (memoria volátil)
**Versión target:** Producción con persistencia y sincronización
