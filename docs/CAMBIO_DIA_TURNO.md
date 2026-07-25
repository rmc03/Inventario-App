# Fix: Cambio de Día Automático en Turnos

## 🐛 Problema Original

Cuando un dependiente enviaba su cuadre, quedaba bloqueado en la pantalla de "Cuadre enviado" indefinidamente. No había lógica para detectar el cambio de día y resetear el estado.

**Estado antes:**
```
Dependiente envía cuadre → Pantalla estática → Bloqueado hasta reiniciar app
```

---

## ✅ Solución Implementada

Se agregó verificación automática de cambio de día en `TurnoRepository`:

### Cambios principales:

1. **Nueva propiedad `_fechaCuadre`**: Guarda cuándo se envió el cuadre
2. **Método `_verificarCambioDeDia()`**: Compara la fecha del cuadre con hoy
3. **Verificación en getters**: Cada acceso al estado verifica si cambió el día
4. **Reset automático**: Si detecta nuevo día, limpia el estado

### Cómo funciona:

```dart
// Al enviar cuadre
repository.enviarCuadre(); // Guarda fecha actual

// Horas después (o al día siguiente)
repository.cuadreEnviadoHoy; // Getter verifica fecha
                             // Si es nuevo día → resetea automáticamente
                             // Retorna false
```

---

## 🎯 Comportamiento Actual

**Mismo día:**
```
09:00 - Dependiente envía cuadre
15:00 - App sigue mostrando "Cuadre enviado" ✅
```

**Día siguiente:**
```
09:00 - Dependiente envía cuadre (Viernes)
00:00 - Medianoche (Sábado)
08:00 - Dependiente abre app → Pantalla normal ✅
```

**App cerrada durante la noche:**
```
22:00 - Dependiente envía cuadre y cierra app
08:00 - (Día siguiente) Abre app → Estado limpio ✅
```

---

## ⚠️ Limitación Actual (Desarrollo)

**Memoria volátil:** Si cierras y reabres la app, el estado se pierde.

**Esto NO es un problema para testing**, pero para producción necesitas persistencia.

---

## 🚀 Para Producción

Ver guía completa en: `docs/TURNO_PRODUCCION.md`

**Cambios necesarios:**
1. ✅ Persistir `_fechaCuadre` en SharedPreferences
2. ✅ Agregar listener de ciclo de vida de la app
3. ✅ Sincronizar con backend (si aplica)
4. ✅ Tests unitarios e integración
5. ✅ Manejo de zonas horarias

---

## 🧪 Testing

**Tests incluidos:** `test/features/turno/turno_repository_test.dart`

Para probar manualmente el cambio de día:

### Opción 1: Cambiar hora del sistema
1. Enviar cuadre
2. Cambiar fecha del dispositivo al día siguiente
3. Reabrir app
4. Verificar estado limpio

### Opción 2: Esperar medianoche (no recomendado 😅)

### Opción 3: Mock de fecha (para tests automatizados)
```dart
// Requiere refactorizar para inyectar clock
class TurnoRepository {
  final Clock clock;
  
  DateTime _ahora() => clock.now();
}
```

---

## 📝 Archivos Modificados

- ✅ `lib/features/turno/data/turno_repository.dart`
- ✅ `test/features/turno/turno_repository_test.dart` (nuevo)
- ✅ `docs/TURNO_PRODUCCION.md` (guía completa)
- ✅ `docs/CAMBIO_DIA_TURNO.md` (este archivo)

---

## 🔍 Verificación Rápida

Para confirmar que funciona:

```dart
void testCambioDia() {
  final repo = TurnoRepository();
  
  // Simular cuadre enviado
  repo.iniciarTurno();
  repo.enviarCuadre();
  print('Cuadre enviado: ${repo.cuadreEnviadoHoy}'); // true
  
  // Simular paso de un día (cambiar fecha sistema)
  // ...esperar o cambiar fecha...
  
  // Verificar reseteo automático
  print('Nuevo día: ${repo.cuadreEnviadoHoy}'); // false (automático)
}
```

---

**Implementado:** 25/07/2026  
**Desarrollador:** Kiro AI  
**Estado:** ✅ Funcionando en desarrollo  
**Siguiente paso:** Migrar a persistencia para producción
