import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/rol.dart';
import '../models/usuario_model.dart';

class FirestoreDatasource {
  final FirebaseFirestore _firestore;

  FirestoreDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _usuariosRef => _firestore.collection('usuarios');
  CollectionReference get _padronRef =>
      _firestore.collection('padron_institucional');

  Future<UsuarioModel?> obtenerUsuarioPorUid(String uid) async {
    final doc = await _usuariosRef.doc(uid).get();
    if (!doc.exists) return null;
    return UsuarioModel.fromFirestore(doc);
  }

  /// Escucha en tiempo real todo el padrón de usuarios para el Administrador (Vista 5 y 6)
  Stream<List<UsuarioModel>> escucharTodosLosUsuarios() {
    return _usuariosRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UsuarioModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<bool> existeCedulaRegistrada(String cedula) async {
    final query = await _usuariosRef
        .where('numeroCedula', isEqualTo: cedula.trim())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> verificarCoincidenciaInstitucional({
    required String cedula,
    required String correo,
  }) async {
    final query = await _padronRef
        .where('numeroCedula', isEqualTo: cedula.trim())
        .where('correoElectronico', isEqualTo: correo.trim().toLowerCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> guardarUsuario(UsuarioModel usuario) async {
    await _usuariosRef.doc(usuario.uid).set(usuario.toMap());
  }

  /// RF-ADM-005, 006, 007: Aprobar solicitud de registro manualmente
  Future<void> aprobarUsuarioInFirestore({
    required String uid,
    required List<Rol> roles,
    String? areaResponsable,
    List<String>? especialidades,
    required String adminUid,
  }) async {
    final updateData = <String, dynamic>{
      'estado': EstadoCuenta.ACTIVO.toStorageString(),
      'roles': roles.map((r) => r.toStorageString()).toList(),
      'fechaAprobacion': FieldValue.serverTimestamp(),
      'aprobadoPorAdminUid': adminUid,
    };

    if (roles.contains(Rol.ENCARGADO)) {
      updateData['areaResponsable'] = areaResponsable;
      updateData['tipoDeEncargado'] = especialidades ?? [];
      updateData['numeroTareasActivas'] = 0;
    } else {
      updateData['areaResponsable'] = FieldValue.delete();
      updateData['tipoDeEncargado'] = FieldValue.delete();
      updateData['numeroTareasActivas'] = FieldValue.delete();
    }

    await _usuariosRef.doc(uid).update(updateData);
  }

  /// RF-ADM-008, 009, 010: Rechazar solicitud de registro
  Future<void> rechazarUsuarioInFirestore({
    required String uid,
    required String motivo,
    required String adminUid,
  }) async {
    await _usuariosRef.doc(uid).update({
      'estado': EstadoCuenta.RECHAZADO.toStorageString(),
      'motivoRechazo': motivo,
      'fechaRechazo': FieldValue.serverTimestamp(),
      'rechazadoPorAdminUid': adminUid,
    });
  }

  /// RF-ADM-013, 014: Modificar roles y datos condicionales de Encargado
  Future<void> actualizarRolesYCampos({
    required String uid,
    required List<Rol> nuevosRoles,
    String? areaResponsable,
    List<String>? especialidades,
  }) async {
    final updateData = <String, dynamic>{
      'roles': nuevosRoles.map((r) => r.toStorageString()).toList(),
      'fechaUltimaModificacion': FieldValue.serverTimestamp(),
    };

    if (nuevosRoles.contains(Rol.ENCARGADO)) {
      updateData['areaResponsable'] = areaResponsable;
      updateData['tipoDeEncargado'] = especialidades ?? [];
      // Mantiene el número de tareas activas previo o lo inicializa en 0
      final doc = await _usuariosRef.doc(uid).get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data['numeroTareasActivas'] == null) {
        updateData['numeroTareasActivas'] = 0;
      }
    } else {
      updateData['areaResponsable'] = FieldValue.delete();
      updateData['tipoDeEncargado'] = FieldValue.delete();
      updateData['numeroTareasActivas'] = FieldValue.delete();
    }

    await _usuariosRef.doc(uid).update(updateData);
  }

  /// RF-ADM-015: Desactivar cuenta
  Future<void> desactivarUsuarioInFirestore({
    required String uid,
    required String adminUid,
  }) async {
    await _usuariosRef.doc(uid).update({
      'estado': EstadoCuenta.INACTIVO.toStorageString(),
      'fechaDesactivacion': FieldValue.serverTimestamp(),
      'desactivadoPorAdminUid': adminUid,
    });
  }

  /// RF-ADM-018: Reactivar cuenta
  Future<void> reactivarUsuarioInFirestore({
    required String uid,
    required List<Rol> roles,
    String? areaResponsable,
    List<String>? especialidades,
    required String adminUid,
  }) async {
    final updateData = <String, dynamic>{
      'estado': EstadoCuenta.ACTIVO.toStorageString(),
      'roles': roles.map((r) => r.toStorageString()).toList(),
      'fechaReactivacion': FieldValue.serverTimestamp(),
      'reactivadoPorAdminUid': adminUid,
      'motivoRechazo': FieldValue.delete(),
    };

    if (roles.contains(Rol.ENCARGADO)) {
      updateData['areaResponsable'] = areaResponsable;
      updateData['tipoDeEncargado'] = especialidades ?? [];
      updateData['numeroTareasActivas'] = 0;
    }

    await _usuariosRef.doc(uid).update(updateData);
  }

  /// RF-AUT-009: Desmarcar el indicador de clave temporal tras el cambio obligatorio
  Future<void> desmarcarCambioObligatorioContrasena(String uid) async {
    await _usuariosRef.doc(uid).update({
      'indicador_cambio_obligatorio': false,
      'fechaUltimoCambioClave': FieldValue.serverTimestamp(),
    });
  }
}
