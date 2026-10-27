import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/incidencia.dart';
import '../../domain/entities/rol.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/i_incidencia_repository.dart';
import '../datasources/notificaciones_datasource.dart';
import '../datasources/storage_datasource.dart';
import '../models/incidencia_model.dart';
import '../models/usuario_model.dart';

class IncidenciasRepositoryImpl implements IIncidenciaRepository {
  final FirebaseFirestore _firestore;
  final StorageDatasource _storageDatasource;
  final NotificacionesDatasource _notificacionesDatasource;

  IncidenciasRepositoryImpl({
    FirebaseFirestore? firestore,
    StorageDatasource? storageDatasource,
    NotificacionesDatasource? notificacionesDatasource,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storageDatasource = storageDatasource ?? StorageDatasource(),
       _notificacionesDatasource =
           notificacionesDatasource ?? NotificacionesDatasource();

  CollectionReference get _incidenciasRef =>
      _firestore.collection('incidencias');
  CollectionReference get _usuariosRef => _firestore.collection('usuarios');

  // =========================================================================
  // 1. MÓDULO CIUDADANO
  // =========================================================================

  @override
  Future<void> reportarIncidencia({
    required String idUsuarioReporta,
    required String nombreUsuarioReporta,
    required Map<String, String> ubicacion,
    required String categoria,
    required String subcategoria,
    String? descripcion,
    required List<File> archivosFotos,
  }) async {
    final nuevoDoc = _incidenciasRef.doc();
    final idIncidencia = nuevoDoc.id;

    final urlsFotos = await _storageDatasource.subirEvidenciasIncidencia(
      idIncidencia: idIncidencia,
      archivosFotos: archivosFotos,
    );

    try {
      final modelo = IncidenciaModel(
        id: idIncidencia,
        fechaCreacion: DateTime.now(),
        ubicacion: ubicacion,
        categoria: categoria,
        subcategoria: subcategoria,
        descripcion: descripcion,
        urlsFotosEvidencia: urlsFotos,
        estado: EstadoIncidencia.NUEVO,
        idUsuarioReporta: idUsuarioReporta,
        nombreUsuarioReporta: nombreUsuarioReporta,
      );

      await nuevoDoc.set(modelo.toMap());

      // RF-NOT-001: Disparo de notificación a TODOS los Inspectores activos
      await _notificacionesDatasource.notificarATodosLosInspectores(
        titulo: 'Nueva Incidencia Registrada',
        mensaje:
            'Novedad en ${ubicacion['bloque_area']} ($categoria - $subcategoria).',
        incidenciaId: idIncidencia,
      );
    } catch (e) {
      await _storageDatasource.eliminarEvidenciasSubidas(urlsFotos);
      throw Exception(
        'Error al registrar el reporte de incidencia en Firestore: ${e.toString()}',
      );
    }
  }

  @override
  Stream<List<Incidencia>> escucharMisIncidencias(String idUsuarioReporta) {
    return _incidenciasRef
        .where('idUsuarioReporta', isEqualTo: idUsuarioReporta)
        .snapshots()
        .map((snapshot) {
          final lista = snapshot.docs
              .map((doc) => IncidenciaModel.fromFirestore(doc))
              .toList();
          lista.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
          return lista;
        });
  }

  @override
  Stream<List<Incidencia>> escucharIncidenciasComunidad() {
    final estadosPublicos = [
      EstadoIncidencia.APROBADO.toStorageString(),
      EstadoIncidencia.EN_PROCESO.toStorageString(),
      EstadoIncidencia.PARA_VALIDAR.toStorageString(),
      EstadoIncidencia.FINALIZADO.toStorageString(),
    ];

    return _incidenciasRef
        .where('estado', whereIn: estadosPublicos)
        .snapshots()
        .map((snapshot) {
          final lista = snapshot.docs
              .map((doc) => IncidenciaModel.fromFirestore(doc))
              .toList();
          lista.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
          return lista;
        });
  }

  @override
  Future<Incidencia?> obtenerDetalleIncidencia(String idIncidencia) async {
    final doc = await _incidenciasRef.doc(idIncidencia).get();
    if (!doc.exists) return null;
    return IncidenciaModel.fromFirestore(doc);
  }

  // =========================================================================
  // 2. MÓDULO INSPECTOR
  // =========================================================================

  @override
  Stream<List<Incidencia>> escucharIncidenciasPorEstado(String estadoStorage) {
    return _incidenciasRef
        .where('estado', isEqualTo: estadoStorage)
        .snapshots()
        .map((snapshot) {
          final lista = snapshot.docs
              .map((doc) => IncidenciaModel.fromFirestore(doc))
              .toList();
          lista.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
          return lista;
        });
  }

  @override
  Future<List<Usuario>> obtenerEncargadosActivos() async {
    final snapshot = await _usuariosRef
        .where('estado', isEqualTo: EstadoCuenta.ACTIVO.toStorageString())
        .get();

    return snapshot.docs
        .map((doc) => UsuarioModel.fromFirestore(doc))
        .where((u) => u.tieneRol(Rol.ENCARGADO))
        .toList();
  }

  @override
  Future<void> aprobarIncidencia({
    required String idIncidencia,
    required String idInspector,
  }) async {
    // Control de Concurrencia Optimista (OCC / RF-INS-006)
    final doc = await _incidenciasRef.doc(idIncidencia).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    if (data['estado'] != EstadoIncidencia.NUEVO.toStorageString()) {
      throw Exception('La incidencia ya fue gestionada por otro inspector.');
    }

    await _incidenciasRef.doc(idIncidencia).update({
      'estado': EstadoIncidencia.APROBADO.toStorageString(),
      'idInspectorAprueba': idInspector,
      'fechaAprobacion': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> rechazarIncidencia({
    required String idIncidencia,
    required String motivoRechazo,
    required String idInspector,
  }) async {
    final doc = await _incidenciasRef.doc(idIncidencia).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    if (data['estado'] != EstadoIncidencia.NUEVO.toStorageString()) {
      throw Exception('La incidencia ya fue gestionada por otro inspector.');
    }

    await _incidenciasRef.doc(idIncidencia).update({
      'estado': EstadoIncidencia.RECHAZADO.toStorageString(),
      'motivoRechazoDevolucion': motivoRechazo,
      'idInspectorRechaza': idInspector,
      'fechaRechazo': FieldValue.serverTimestamp(),
    });

    // RF-NOT-005: Disparo de notificación al CIUDADANO creador
    final idReportante = data['idUsuarioReporta'] as String? ?? '';
    if (idReportante.isNotEmpty) {
      await _notificacionesDatasource.enviarNotificacionAUsuario(
        uidDestino: idReportante,
        titulo: 'Reporte Rechazado por Inspección',
        mensaje:
            'Su incidencia en ${data['ubicacion']?['bloque_area'] ?? 'la institución'} fue rechazada. Motivo: $motivoRechazo',
        incidenciaId: idIncidencia,
      );
    }
  }

  @override
  Future<void> asignarEncargadoIncidencia({
    required String idIncidencia,
    required Usuario encargado,
    required String idInspector,
  }) async {
    String bloque = 'la institución';
    String cat = 'Mantenimiento';

    await _firestore.runTransaction((transaction) async {
      final incDocRef = _incidenciasRef.doc(idIncidencia);
      final encDocRef = _usuariosRef.doc(encargado.uid);

      final incSnap = await transaction.get(incDocRef);
      final encSnap = await transaction.get(encDocRef);

      if (!incSnap.exists || !encSnap.exists) {
        throw Exception(
          'El documento de la incidencia o del técnico no existe.',
        );
      }

      final incData = incSnap.data() as Map<String, dynamic>? ?? {};
      if (incData['estado'] != EstadoIncidencia.APROBADO.toStorageString()) {
        throw Exception(
          'La incidencia ya no se encuentra en estado Aprobado para asignación.',
        );
      }

      bloque = incData['ubicacion']?['bloque_area'] ?? 'la institución';
      cat = incData['categoria'] ?? 'Mantenimiento';

      // 1. Actualiza la incidencia a EN_PROCESO
      transaction.update(incDocRef, {
        'estado': EstadoIncidencia.EN_PROCESO.toStorageString(),
        'idEncargadoAsignado': encargado.uid,
        'nombreEncargadoAsignado': encargado.nombreCompleto,
        'idInspectorAsigna': idInspector,
        'fechaAsignacion': FieldValue.serverTimestamp(),
      });

      // 2. Incrementa (+1) el contador denormalizado del técnico
      transaction.update(encDocRef, {
        'numeroTareasActivas': FieldValue.increment(1),
      });
    });

    // RF-NOT-002: Disparo de notificación al ENCARGADO designado
    await _notificacionesDatasource.enviarNotificacionAUsuario(
      uidDestino: encargado.uid,
      titulo: 'Nueva Tarea Asignada',
      mensaje:
          'Se le ha asignado una incidencia de reparación en $bloque ($cat).',
      incidenciaId: idIncidencia,
    );
  }

  @override
  Future<void> finalizarIncidencia({
    required String idIncidencia,
    required String idInspector,
  }) async {
    String idReportante = '';
    String bloque = 'la institución';

    await _firestore.runTransaction((transaction) async {
      final incDocRef = _incidenciasRef.doc(idIncidencia);
      final incSnap = await transaction.get(incDocRef);

      if (!incSnap.exists) {
        throw Exception('La incidencia especificada no existe.');
      }

      final incData = incSnap.data() as Map<String, dynamic>? ?? {};
      if (incData['estado'] !=
          EstadoIncidencia.PARA_VALIDAR.toStorageString()) {
        throw Exception(
          'La incidencia ya no se encuentra en estado Para Validar.',
        );
      }

      final idEncargado = incData['idEncargadoAsignado'] as String?;
      idReportante = incData['idUsuarioReporta'] as String? ?? '';
      bloque = incData['ubicacion']?['bloque_area'] ?? 'la institución';

      // 1. Conmuta la incidencia a FINALIZADO
      transaction.update(incDocRef, {
        'estado': EstadoIncidencia.FINALIZADO.toStorageString(),
        'idInspectorFinaliza': idInspector,
        'fechaFinalizacion': FieldValue.serverTimestamp(),
      });

      // 2. Decrementa (-1) el contador del Encargado
      if (idEncargado != null && idEncargado.isNotEmpty) {
        final encDocRef = _usuariosRef.doc(idEncargado);
        transaction.update(encDocRef, {
          'numeroTareasActivas': FieldValue.increment(-1),
        });
      }
    });

    // RF-NOT-005: Disparo de notificación al CIUDADANO creador
    if (idReportante.isNotEmpty) {
      await _notificacionesDatasource.enviarNotificacionAUsuario(
        uidDestino: idReportante,
        titulo: 'Incidencia Finalizada y Cerrada',
        mensaje:
            'Su reporte en $bloque ha sido solucionado satisfactoriamente por la institución.',
        incidenciaId: idIncidencia,
      );
    }
  }

  @override
  Future<void> devolverTareaIncidencia({
    required String idIncidencia,
    required String motivoDevolucion,
    required String idInspector,
  }) async {
    final doc = await _incidenciasRef.doc(idIncidencia).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    if (data['estado'] != EstadoIncidencia.PARA_VALIDAR.toStorageString()) {
      throw Exception(
        'La incidencia ya no se encuentra en estado Para Validar.',
      );
    }

    final registroDevolucion = {
      'fecha': DateTime.now().toIso8601String(),
      'idInspector': idInspector,
      'motivo': motivoDevolucion,
    };

    await _incidenciasRef.doc(idIncidencia).update({
      'estado': EstadoIncidencia.EN_PROCESO.toStorageString(),
      'motivoRechazoDevolucion': motivoDevolucion,
      'historialDevoluciones': FieldValue.arrayUnion([registroDevolucion]),
      'fechaDevolucion': FieldValue.serverTimestamp(),
    });

    // RF-NOT-004: Disparo de notificación al ENCARGADO responsable
    final idEncargado = data['idEncargadoAsignado'] as String? ?? '';
    if (idEncargado.isNotEmpty) {
      await _notificacionesDatasource.enviarNotificacionAUsuario(
        uidDestino: idEncargado,
        titulo: 'Tarea Devuelta para Corrección',
        mensaje:
            'El Inspector devolvió su trabajo con observaciones: $motivoDevolucion',
        incidenciaId: idIncidencia,
      );
    }
  }

  // =========================================================================
  // 3. MÓDULO ENCARGADO
  // =========================================================================

  @override
  Stream<List<Incidencia>> escucharTareasEncargado({
    required String idEncargado,
    required String tipoSeccion,
  }) {
    return _incidenciasRef
        .where('idEncargadoAsignado', isEqualTo: idEncargado)
        .snapshots()
        .map((snapshot) {
          final todas = snapshot.docs
              .map((doc) => IncidenciaModel.fromFirestore(doc))
              .toList();

          List<Incidencia> filtradas = [];

          if (tipoSeccion == 'ACTIVAS') {
            filtradas = todas
                .where(
                  (i) =>
                      i.estado == EstadoIncidencia.EN_PROCESO &&
                      (i.motivoRechazoDevolucion == null ||
                          i.motivoRechazoDevolucion!.isEmpty),
                )
                .toList();
          } else if (tipoSeccion == 'DEVUELTAS') {
            filtradas = todas
                .where(
                  (i) =>
                      i.estado == EstadoIncidencia.EN_PROCESO &&
                      i.motivoRechazoDevolucion != null &&
                      i.motivoRechazoDevolucion!.isNotEmpty,
                )
                .toList();
          } else if (tipoSeccion == 'ENVIADAS') {
            filtradas = todas
                .where(
                  (i) =>
                      i.estado == EstadoIncidencia.PARA_VALIDAR ||
                      i.estado == EstadoIncidencia.FINALIZADO,
                )
                .toList();
          }

          filtradas.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
          return filtradas;
        });
  }

  @override
  Future<void> registrarInicioTrabajo({required String idIncidencia}) async {
    await _incidenciasRef.doc(idIncidencia).update({
      'fechaInicioTrabajo': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> registrarSolucionTarea({
    required String idIncidencia,
    String? comentarios,
    required List<File> archivosFotosSolucion,
  }) async {
    final urlsFotos = await _storageDatasource.subirEvidenciasIncidencia(
      idIncidencia: '${idIncidencia}_solucion',
      archivosFotos: archivosFotosSolucion,
    );

    try {
      await _incidenciasRef.doc(idIncidencia).update({
        'estado': EstadoIncidencia.PARA_VALIDAR.toStorageString(),
        'urlsFotosSolucion': urlsFotos,
        'comentariosSolucion': comentarios,
        'fechaSolucion': FieldValue.serverTimestamp(),
      });

      // RF-NOT-003: Disparo de notificación a TODOS los Inspectores
      await _notificacionesDatasource.notificarATodosLosInspectores(
        titulo: 'Solución Enviada para Validación',
        mensaje:
            'Un Encargado ha reportado la solución de una tarea y espera su verificación técnica.',
        incidenciaId: idIncidencia,
      );
    } catch (e) {
      await _storageDatasource.eliminarEvidenciasSubidas(urlsFotos);
      throw Exception(
        'Error al enviar la solución a Firestore: ${e.toString()}',
      );
    }
  }
}
