import 'package:flutter_test/flutter_test.dart';
import 'package:mypiutil_app/features/turno/data/turno_repository.dart';

void main() {
  group('TurnoRepository', () {
    late TurnoRepository repository;

    setUp(() {
      repository = TurnoRepository();
    });

    test('Estado inicial: sin turno activo', () {
      expect(repository.estaActivo, false);
      expect(repository.cuadreEnviadoHoy, false);
      expect(repository.horaInicio, null);
    });

    test('Iniciar turno actualiza el estado correctamente', () {
      repository.iniciarTurno();

      expect(repository.estaActivo, true);
      expect(repository.cuadreEnviadoHoy, false);
      expect(repository.horaInicio, isNotNull);
    });

    test('Enviar cuadre marca el turno como inactivo y cuadre enviado', () {
      repository.iniciarTurno();
      repository.enviarCuadre();

      expect(repository.estaActivo, false);
      expect(repository.cuadreEnviadoHoy, true);
    });

    test('Resetear día limpia el estado de cuadre enviado', () {
      repository.iniciarTurno();
      repository.enviarCuadre();
      repository.resetearDia();

      expect(repository.cuadreEnviadoHoy, false);
    });

    test('Verificar cambio de día NO resetea si el cuadre fue hoy', () {
      repository.iniciarTurno();
      repository.enviarCuadre();

      // Simular acceso al estado (trigger de verificación)
      final cuadreEnviado = repository.cuadreEnviadoHoy;

      // Debe seguir marcado como enviado porque es el mismo día
      expect(cuadreEnviado, true);
    });

    // NOTA: Para probar el cambio de día real, necesitarías:
    // 1. Inyectar un clock/time provider mockeado
    // 2. O ejecutar el test cerca de medianoche y esperar
    // 3. O refactorizar TurnoRepository para aceptar una función de tiempo
    //
    // Ejemplo de cómo debería funcionar:
    // test('Verificar cambio de día resetea el cuadre automáticamente', () {
    //   repository.iniciarTurno();
    //   repository.enviarCuadre();
    //   
    //   // Mock: simular que _fechaCuadre fue ayer
    //   // repository._fechaCuadre = DateTime.now().subtract(Duration(days: 1));
    //   
    //   // Al acceder al estado, debe detectar el cambio de día
    //   final cuadreEnviado = repository.cuadreEnviadoHoy;
    //   
    //   expect(cuadreEnviado, false);
    // });
  });
}
