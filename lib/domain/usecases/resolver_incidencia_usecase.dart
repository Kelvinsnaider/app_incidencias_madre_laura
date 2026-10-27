import 'dart:io';
import '../entities/incidencia.dart';
import '../entities/rol.dart';
import '../entities/usuario.dart';
import '../repositories/i_incidencia_repository.dart';

/// Clase CasoDeUsoResolverIncidencia especificada en SDD 3.2.2 y 3.4.2
class CasoDeUsoResolverIncidencia {
  final IIncidenciaRepository _repository;

  CasoDeUsoResolverIncidencia(this._repository);

  void _validarPermisoEncargado(Usuario invocante) {
    if (!invocante.tieneRol(Rol.ENCARGADO)) {
      throw Exception(
        'Acceso denegado: Se requiere el rol de Encargado para ejecutar esta operación.',
      );
    }
  }

  Stream<List<Incidencia>> escucharTareasPersonal({
    required Usuario encargadoInvocante,
    required String tipoSeccion, // 'ACTIVAS', 'DEVUELTAS', 'ENVIADAS'
  }) {
    _validarPermisoEncargado(encargadoInvocante);
    return _repository.escucharTareasEncargado(
      idEncargado: encargadoInvocante.uid,
      tipoSeccion: tipoSeccion,
    );
  }

  /// RF-ENC-003: Registrar marca de tiempo inmutable de inicio físico de trabajo
  Future<void> iniciarTrabajo({
    required Usuario encargadoInvocante,
    required Incidencia incidencia,
  }) async {
    _validarPermisoEncargado(encargadoInvocante);

    if (incidencia.estado != EstadoIncidencia.EN_PROCESO) {
      throw Exception('La tarea no se encuentra en estado En Proceso.');
    }

    await _repository.registrarInicioTrabajo(idIncidencia: incidencia.id);
  }

  /// RF-ENC-004, RF-ENC-005: Enviar evidencia de solución
  Future<void> marcarComoSolucionada({
    required Usuario encargadoInvocante,
    required Incidencia incidencia,
    String? comentarios,
    required List<File> fotosSolucion,
  }) async {
    _validarPermisoEncargado(encargadoInvocante);

    // Exige haber presionado "Iniciar trabajo" previamente
    if (incidencia.fechaInicioTrabajo == null) {
      throw Exception(
        'Debe haber registrado primero el inicio físico de actividades presionando "Iniciar trabajo".',
      );
    }

    // RF-ENC-005: Exige entre 1 y 3 fotografías como evidencia
    if (fotosSolucion.isEmpty) {
      throw Exception(
        'Debe adjuntar al menos una (1) fotografía tomada en tiempo real como evidencia de la reparación.',
      );
    }
    if (fotosSolucion.length > 3) {
      throw Exception(
        'Se permite un máximo de tres (3) fotografías de solución.',
      );
    }

    // RNF-USA-006: Límite de 500 caracteres en comentarios
    if (comentarios != null && comentarios.trim().length > 500) {
      throw Exception(
        'Los comentarios de solución no pueden superar los 500 caracteres (actual: ${comentarios.trim().length}).',
      );
    }

    await _repository.registrarSolucionTarea(
      idIncidencia: incidencia.id,
      comentarios: comentarios?.trim(),
      archivosFotosSolucion: fotosSolucion,
    );
  }
}
