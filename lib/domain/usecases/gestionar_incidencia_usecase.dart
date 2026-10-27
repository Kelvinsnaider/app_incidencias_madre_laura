import '../entities/incidencia.dart';
import '../entities/rol.dart';
import '../entities/usuario.dart';
import '../repositories/i_incidencia_repository.dart';

/// Clase CasoDeUsoGestionarIncidencia especificada en SDD 3.2.2 y 3.4.2
class CasoDeUsoGestionarIncidencia {
  final IIncidenciaRepository _repository;

  CasoDeUsoGestionarIncidencia(this._repository);

  void _validarPermisoInspector(Usuario invocante) {
    if (!invocante.tieneRol(Rol.INSPECTOR)) {
      throw Exception(
        'Acceso denegado: Se requiere el rol de Inspector para ejecutar esta operación.',
      );
    }
  }

  Stream<List<Incidencia>> escucharIncidenciasPorEstado(String estadoStorage) {
    return _repository.escucharIncidenciasPorEstado(estadoStorage);
  }

  Future<List<Usuario>> obtenerEncargadosActivos() {
    return _repository.obtenerEncargadosActivos();
  }

  /// RF-INS-004, RF-INS-005: Auditoría inicial (Aprobar o Rechazar reporte)
  Future<void> validarIncidencia({
    required Usuario inspectorInvocante,
    required Incidencia incidencia,
    required bool aprobada,
    String? motivoRechazo,
  }) async {
    _validarPermisoInspector(inspectorInvocante);

    if (aprobada) {
      await _repository.aprobarIncidencia(
        idIncidencia: incidencia.id,
        idInspector: inspectorInvocante.uid,
      );
    } else {
      if (motivoRechazo == null || motivoRechazo.trim().isEmpty) {
        throw Exception(
          'Debe ingresar una justificación o motivo obligatorio para el rechazo.',
        );
      }
      await _repository.rechazarIncidencia(
        idIncidencia: incidencia.id,
        motivoRechazo: motivoRechazo.trim(),
        idInspector: inspectorInvocante.uid,
      );
    }
  }

  /// RF-INS-007, RF-INS-009: Asignación multicriterio a un técnico Encargado
  Future<void> asignarEncargado({
    required Usuario inspectorInvocante,
    required Incidencia incidencia,
    required Usuario encargado,
  }) async {
    _validarPermisoInspector(inspectorInvocante);

    if (encargado.estadoCuenta != EstadoCuenta.ACTIVO) {
      throw Exception(
        'El técnico seleccionado ya no se encuentra en estado ACTIVO.',
      );
    }

    if (!encargado.tieneRol(Rol.ENCARGADO)) {
      throw Exception('El usuario seleccionado no posee el rol de Encargado.');
    }

    await _repository.asignarEncargadoIncidencia(
      idIncidencia: incidencia.id,
      encargado: encargado,
      idInspector: inspectorInvocante.uid,
    );
  }

  /// RF-INS-011, RF-INS-012: Auditoría final de solución (Finalizar o Devolver)
  Future<void> revisarSolucion({
    required Usuario inspectorInvocante,
    required Incidencia incidencia,
    required bool aprobada,
    String? motivoDevolucion,
  }) async {
    _validarPermisoInspector(inspectorInvocante);

    if (aprobada) {
      await _repository.finalizarIncidencia(
        idIncidencia: incidencia.id,
        idInspector: inspectorInvocante.uid,
      );
    } else {
      if (motivoDevolucion == null || motivoDevolucion.trim().isEmpty) {
        throw Exception(
          'Debe ingresar una retroalimentación obligatoria indicando las observaciones.',
        );
      }
      await _repository.devolverTareaIncidencia(
        idIncidencia: incidencia.id,
        motivoDevolucion: motivoDevolucion.trim(),
        idInspector: inspectorInvocante.uid,
      );
    }
  }
}
