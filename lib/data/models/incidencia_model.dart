import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/incidencia.dart';
import '../../domain/entities/rol.dart';

class IncidenciaModel extends Incidencia {
  const IncidenciaModel({
    required super.id,
    required super.fechaCreacion,
    required super.ubicacion,
    required super.categoria,
    required super.subcategoria,
    super.descripcion,
    required super.urlsFotosEvidencia,
    required super.estado,
    required super.idUsuarioReporta,
    super.nombreUsuarioReporta,
    super.idEncargadoAsignado,
    super.nombreEncargadoAsignado,
    super.fechaAsignacion,
    super.fechaInicioTrabajo,
    super.fechaSolucion,
    super.urlsFotosSolucion,
    super.comentariosSolucion,
    super.motivoRechazoDevolucion,
    super.historialDevoluciones,
  });

  factory IncidenciaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Mapeo de ubicación jerárquica
    final ubiRaw = data['ubicacion'] as Map<String, dynamic>? ?? {};
    final ubicacionMap = ubiRaw.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    // Mapeo de fotos iniciales de evidencia
    final fotosRaw = data['urlsFotosEvidencia'] as List<dynamic>? ?? [];
    final fotosList = fotosRaw.map((e) => e.toString()).toList();

    // Mapeo de fotos de solución
    List<String>? fotosSol;
    if (data['urlsFotosSolucion'] is List) {
      fotosSol = (data['urlsFotosSolucion'] as List)
          .map((e) => e.toString())
          .toList();
    }

    // Mapeo del historial de devoluciones
    List<Map<String, String>>? historialDev;
    if (data['historialDevoluciones'] is List) {
      historialDev = (data['historialDevoluciones'] as List).map((item) {
        if (item is Map) {
          return item.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
        return <String, String>{};
      }).toList();
    }

    DateTime parseFecha(dynamic field) {
      if (field is Timestamp) return field.toDate();
      return DateTime.now();
    }

    return IncidenciaModel(
      id: doc.id,
      fechaCreacion: parseFecha(data['fechaCreacion']),
      ubicacion: ubicacionMap,
      categoria: data['categoria'] ?? '',
      subcategoria: data['subcategoria'] ?? '',
      descripcion: data['descripcion'] as String?,
      urlsFotosEvidencia: fotosList,
      estado: EstadoIncidencia.fromStorageString(data['estado'] ?? 'NUEVO'),
      idUsuarioReporta: data['idUsuarioReporta'] ?? '',
      nombreUsuarioReporta: data['nombreUsuarioReporta'] as String?,
      idEncargadoAsignado: data['idEncargadoAsignado'] as String?,
      nombreEncargadoAsignado: data['nombreEncargadoAsignado'] as String?,
      fechaAsignacion: data['fechaAsignacion'] != null
          ? parseFecha(data['fechaAsignacion'])
          : null,
      fechaInicioTrabajo: data['fechaInicioTrabajo'] != null
          ? parseFecha(data['fechaInicioTrabajo'])
          : null,
      fechaSolucion: data['fechaSolucion'] != null
          ? parseFecha(data['fechaSolucion'])
          : null,
      urlsFotosSolucion: fotosSol,
      comentariosSolucion: data['comentariosSolucion'] as String?,
      motivoRechazoDevolucion: data['motivoRechazoDevolucion'] as String?,
      historialDevoluciones: historialDev,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'ubicacion': ubicacion,
      'categoria': categoria,
      'subcategoria': subcategoria,
      'descripcion': descripcion,
      'urlsFotosEvidencia': urlsFotosEvidencia,
      'estado': estado.toStorageString(),
      'idUsuarioReporta': idUsuarioReporta,
      'nombreUsuarioReporta': nombreUsuarioReporta,
    };

    if (idEncargadoAsignado != null) {
      map['idEncargadoAsignado'] = idEncargadoAsignado;
      map['nombreEncargadoAsignado'] = nombreEncargadoAsignado;
    }
    if (fechaAsignacion != null) {
      map['fechaAsignacion'] = Timestamp.fromDate(fechaAsignacion!);
    }
    if (fechaInicioTrabajo != null) {
      map['fechaInicioTrabajo'] = Timestamp.fromDate(fechaInicioTrabajo!);
    }
    if (fechaSolucion != null) {
      map['fechaSolucion'] = Timestamp.fromDate(fechaSolucion!);
    }
    if (urlsFotosSolucion != null) {
      map['urlsFotosSolucion'] = urlsFotosSolucion;
    }
    if (comentariosSolucion != null) {
      map['comentariosSolucion'] = comentariosSolucion;
    }
    if (motivoRechazoDevolucion != null) {
      map['motivoRechazoDevolucion'] = motivoRechazoDevolucion;
    }
    if (historialDevoluciones != null) {
      map['historialDevoluciones'] = historialDevoluciones;
    }

    return map;
  }
}
