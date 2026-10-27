import 'rol.dart';

/// Clase de dominio central especificada en SDD 3.2.2
class Incidencia {
  final String id;
  final DateTime fechaCreacion;
  final Map<String, String>
  ubicacion; // bloque_area, piso_nivel, lugar_especifico
  final String categoria;
  final String subcategoria;
  final String? descripcion;
  final List<String> urlsFotosEvidencia;
  final EstadoIncidencia estado;
  final String idUsuarioReporta;
  final String? nombreUsuarioReporta;

  // Atributos de gestión (Inspector / Encargado)
  final String? idEncargadoAsignado;
  final String? nombreEncargadoAsignado;
  final DateTime? fechaAsignacion;
  final DateTime? fechaInicioTrabajo;
  final DateTime? fechaSolucion;
  final List<String>? urlsFotosSolucion;
  final String? comentariosSolucion;
  final String? motivoRechazoDevolucion;
  final List<Map<String, String>>? historialDevoluciones;

  const Incidencia({
    required this.id,
    required this.fechaCreacion,
    required this.ubicacion,
    required this.categoria,
    required this.subcategoria,
    this.descripcion,
    required this.urlsFotosEvidencia,
    required this.estado,
    required this.idUsuarioReporta,
    this.nombreUsuarioReporta,
    this.idEncargadoAsignado,
    this.nombreEncargadoAsignado,
    this.fechaAsignacion,
    this.fechaInicioTrabajo,
    this.fechaSolucion,
    this.urlsFotosSolucion,
    this.comentariosSolucion,
    this.motivoRechazoDevolucion,
    this.historialDevoluciones,
  });

  /// Métodos de dominio del ciclo de vida (SDD 3.2.2)
  Incidencia copyWith({
    String? id,
    DateTime? fechaCreacion,
    Map<String, String>? ubicacion,
    String? categoria,
    String? subcategoria,
    String? descripcion,
    List<String>? urlsFotosEvidencia,
    EstadoIncidencia? estado,
    String? idUsuarioReporta,
    String? nombreUsuarioReporta,
    String? idEncargadoAsignado,
    String? nombreEncargadoAsignado,
    DateTime? fechaAsignacion,
    DateTime? fechaInicioTrabajo,
    DateTime? fechaSolucion,
    List<String>? urlsFotosSolucion,
    String? comentariosSolucion,
    String? motivoRechazoDevolucion,
    List<Map<String, String>>? historialDevoluciones,
  }) {
    return Incidencia(
      id: id ?? this.id,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      ubicacion: ubicacion ?? this.ubicacion,
      categoria: categoria ?? this.categoria,
      subcategoria: subcategoria ?? this.subcategoria,
      descripcion: descripcion ?? this.descripcion,
      urlsFotosEvidencia: urlsFotosEvidencia ?? this.urlsFotosEvidencia,
      estado: estado ?? this.estado,
      idUsuarioReporta: idUsuarioReporta ?? this.idUsuarioReporta,
      nombreUsuarioReporta: nombreUsuarioReporta ?? this.nombreUsuarioReporta,
      idEncargadoAsignado: idEncargadoAsignado ?? this.idEncargadoAsignado,
      nombreEncargadoAsignado:
          nombreEncargadoAsignado ?? this.nombreEncargadoAsignado,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      fechaInicioTrabajo: fechaInicioTrabajo ?? this.fechaInicioTrabajo,
      fechaSolucion: fechaSolucion ?? this.fechaSolucion,
      urlsFotosSolucion: urlsFotosSolucion ?? this.urlsFotosSolucion,
      comentariosSolucion: comentariosSolucion ?? this.comentariosSolucion,
      motivoRechazoDevolucion:
          motivoRechazoDevolucion ?? this.motivoRechazoDevolucion,
      historialDevoluciones:
          historialDevoluciones ?? this.historialDevoluciones,
    );
  }

  String get ubicacionFormateada {
    final bloque = ubicacion['bloque_area'] ?? '';
    final piso = ubicacion['piso_nivel'];
    final lugar = ubicacion['lugar_especifico'] ?? '';

    if (piso != null && piso.isNotEmpty) {
      return '$bloque ➔ $piso ➔ $lugar';
    }
    return '$bloque ➔ $lugar';
  }
}
