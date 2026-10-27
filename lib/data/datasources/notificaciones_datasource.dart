import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notificacion.dart';
import '../../domain/entities/rol.dart';

class NotificacionesDatasource {
  final FirebaseFirestore _firestore;

  NotificacionesDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _notificacionesRef(String uid) =>
      _firestore.collection('usuarios').doc(uid).collection('notificaciones');

  /// RF-NOT-006: Escucha en tiempo real del listado cronológico de alertas del usuario
  Stream<List<NotificacionSistema>> escucharNotificacionesUsuario(String uid) {
    return _notificacionesRef(
      uid,
    ).orderBy('fecha', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        DateTime f = DateTime.now();
        if (data['fecha'] is Timestamp) {
          f = (data['fecha'] as Timestamp).toDate();
        }
        return NotificacionSistema(
          id: doc.id,
          titulo: data['titulo'] ?? 'Notificación',
          mensaje: data['mensaje'] ?? '',
          fecha: f,
          incidenciaId: data['incidenciaId'] ?? '',
          leida: data['leida'] as bool? ?? false,
        );
      }).toList();
    });
  }

  /// Despacha una notificación individual a un usuario específico
  Future<void> enviarNotificacionAUsuario({
    required String uidDestino,
    required String titulo,
    required String mensaje,
    required String incidenciaId,
  }) async {
    await _notificacionesRef(uidDestino).add({
      'titulo': titulo,
      'mensaje': mensaje,
      'incidenciaId': incidenciaId,
      'fecha': FieldValue.serverTimestamp(),
      'leida': false,
    });
  }

  /// Despacha una notificación push/in-app a todos los Inspectores activos (RF-NOT-001, 003, 007)
  Future<void> notificarATodosLosInspectores({
    required String titulo,
    required String mensaje,
    required String incidenciaId,
  }) async {
    final snapInspectores = await _firestore
        .collection('usuarios')
        .where('estado', isEqualTo: 'ACTIVO')
        .where('roles', arrayContains: Rol.INSPECTOR.toStorageString())
        .get();

    for (final doc in snapInspectores.docs) {
      await _notificacionesRef(doc.id).add({
        'titulo': titulo,
        'mensaje': mensaje,
        'incidenciaId': incidenciaId,
        'fecha': FieldValue.serverTimestamp(),
        'leida': false,
      });
    }
  }

  Future<void> marcarNotificacionLeida(
    String uid,
    String notificacionId,
  ) async {
    await _notificacionesRef(uid).doc(notificacionId).update({'leida': true});
  }
}
