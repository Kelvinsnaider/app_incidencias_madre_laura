import 'dart:io';
import '../entities/incidencia.dart';
import '../entities/usuario.dart';
import '../repositories/i_incidencia_repository.dart';

/// Clase CasoDeUsoReportar especificada en SDD 3.2.2 y 3.4.2
class CasoDeUsoReportar {
  final IIncidenciaRepository _repository;

  CasoDeUsoReportar(this._repository);

  Future<void> reportarIncidencia({
    required Usuario usuarioInvocante,
    required Map<String, String> ubicacion,
    required String categoria,
    required String subcategoria,
    String? descripcion,
    required List<File> fotosEvidencia,
  }) async {
    // RF-CIU-008: Carga obligatoria de al menos 1 y máximo 3 fotografías
    if (fotosEvidencia.isEmpty) {
      throw Exception(
        'Debe adjuntar al menos una (1) fotografía como evidencia.',
      );
    }
    if (fotosEvidencia.length > 3) {
      throw Exception(
        'Se permite un máximo de tres (3) fotografías por reporte.',
      );
    }

    // RNF-USA-006: Restricción de longitud de texto a máximo 500 caracteres
    if (descripcion != null && descripcion.trim().length > 500) {
      throw Exception(
        'La descripción no puede superar los 500 caracteres (actual: ${descripcion.trim().length}).',
      );
    }

    // RF-CIU-006: Validación para categoría "Otras"
    if (categoria == 'Otras' &&
        (descripcion == null || descripcion.trim().isEmpty)) {
      throw Exception(
        'Para la categoría "Otras", debe especificar la naturaleza del problema en la descripción.',
      );
    }

    await _repository.reportarIncidencia(
      idUsuarioReporta: usuarioInvocante.uid,
      nombreUsuarioReporta: usuarioInvocante.nombreCompleto,
      ubicacion: ubicacion,
      categoria: categoria,
      subcategoria: subcategoria,
      descripcion: descripcion?.trim(),
      archivosFotos: fotosEvidencia,
    );
  }

  Stream<List<Incidencia>> consultarMisIncidencias(Usuario usuario) {
    return _repository.escucharMisIncidencias(usuario.uid);
  }

  Stream<List<Incidencia>> consultarIncidenciasComunidad() {
    return _repository.escucharIncidenciasComunidad();
  }
}
