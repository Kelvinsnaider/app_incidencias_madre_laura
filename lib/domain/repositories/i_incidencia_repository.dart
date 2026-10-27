import 'dart:io';
import '../entities/incidencia.dart';
import '../entities/usuario.dart';

abstract class IIncidenciaRepository {
  // --- Módulo Ciudadano (Sprint 3) ---
  Future<void> reportarIncidencia({
    required String idUsuarioReporta,
    required String nombreUsuarioReporta,
    required Map<String, String> ubicacion,
    required String categoria,
    required String subcategoria,
    String? descripcion,
    required List<File> archivosFotos,
  });

  Stream<List<Incidencia>> escucharMisIncidencias(String idUsuarioReporta);
  Stream<List<Incidencia>> escucharIncidenciasComunidad();
  Future<Incidencia?> obtenerDetalleIncidencia(String idIncidencia);

  // --- Módulo Inspector (Sprint 4) ---
  Stream<List<Incidencia>> escucharIncidenciasPorEstado(String estadoStorage);
  Future<List<Usuario>> obtenerEncargadosActivos();
  Future<void> aprobarIncidencia({
    required String idIncidencia,
    required String idInspector,
  });
  Future<void> rechazarIncidencia({
    required String idIncidencia,
    required String motivoRechazo,
    required String idInspector,
  });
  Future<void> asignarEncargadoIncidencia({
    required String idIncidencia,
    required Usuario encargado,
    required String idInspector,
  });
  Future<void> finalizarIncidencia({
    required String idIncidencia,
    required String idInspector,
  });
  Future<void> devolverTareaIncidencia({
    required String idIncidencia,
    required String motivoDevolucion,
    required String idInspector,
  });

  // --- Módulo Encargado (Sprint 4) ---
  Stream<List<Incidencia>> escucharTareasEncargado({
    required String idEncargado,
    required String tipoSeccion, // 'ACTIVAS', 'DEVUELTAS', 'ENVIADAS'
  });
  Future<void> registrarInicioTrabajo({required String idIncidencia});
  Future<void> registrarSolucionTarea({
    required String idIncidencia,
    String? comentarios,
    required List<File> archivosFotosSolucion,
  });
}
