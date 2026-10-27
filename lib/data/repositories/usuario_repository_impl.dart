import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/rol.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/i_usuario_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/local_storage_datasource.dart';
import '../datasources/notificaciones_datasource.dart';
import '../models/usuario_model.dart';

class UsuarioRepositoryImpl implements IUsuarioRepository {
  final FirebaseAuthDatasource _authDatasource;
  final FirestoreDatasource _firestoreDatasource;
  final LocalStorageDatasource _localStorageDatasource;
  final NotificacionesDatasource _notificacionesDatasource;
  final FirebaseFirestore _firestore;

  UsuarioRepositoryImpl({
    required FirebaseAuthDatasource authDatasource,
    required FirestoreDatasource firestoreDatasource,
    required LocalStorageDatasource localStorageDatasource,
    NotificacionesDatasource? notificacionesDatasource,
    FirebaseFirestore? firestore,
  }) : _authDatasource = authDatasource,
       _firestoreDatasource = firestoreDatasource,
       _localStorageDatasource = localStorageDatasource,
       _notificacionesDatasource =
           notificacionesDatasource ?? NotificacionesDatasource(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Usuario?> obtenerSesionActual() async {
    final currentUser = _authDatasource.usuarioActual;
    if (currentUser == null) return null;

    final usuario = await _firestoreDatasource.obtenerUsuarioPorUid(
      currentUser.uid,
    );
    if (usuario == null) {
      await _authDatasource.cerrarSesion();
      return null;
    }

    if (usuario.estadoCuenta != EstadoCuenta.ACTIVO) {
      await _authDatasource.cerrarSesion();
      return null;
    }

    return usuario;
  }

  @override
  Future<Usuario> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    try {
      final credencial = await _authDatasource.iniciarSesion(correo, password);
      final uid = credencial.user!.uid;

      final usuario = await _firestoreDatasource.obtenerUsuarioPorUid(uid);
      if (usuario == null) {
        await _authDatasource.cerrarSesion();
        throw Exception(
          'El correo electrónico o la contraseña no son válidos.',
        );
      }

      switch (usuario.estadoCuenta) {
        case EstadoCuenta.PENDIENTE:
          await _authDatasource.cerrarSesion();
          throw Exception(
            'Su solicitud de registro aún se encuentra pendiente de aprobación por parte del administrador.',
          );
        case EstadoCuenta.RECHAZADO:
          await _authDatasource.cerrarSesion();
          final motivo = usuario.motivoRechazo != null
              ? ' Motivo: ${usuario.motivoRechazo}'
              : '';
          throw Exception(
            'Su solicitud de acceso fue rechazada por la administración.$motivo',
          );
        case EstadoCuenta.INACTIVO:
          await _authDatasource.cerrarSesion();
          throw Exception(
            'Su cuenta ha sido deshabilitada. Comuníquese con el administrador del sistema.',
          );
        case EstadoCuenta.ACTIVO:
          if (usuario.roles.isNotEmpty) {
            await _localStorageDatasource.guardarRolActivo(usuario.roles.first);
          }
          return usuario;
      }
    } on FirebaseAuthException {
      throw Exception('El correo electrónico o la contraseña no son válidos.');
    }
  }

  @override
  Future<Usuario> registrarUsuario({
    required String nombreCompleto,
    required String correo,
    required String cedula,
    required String password,
  }) async {
    final cedulaExiste = await _firestoreDatasource.existeCedulaRegistrada(
      cedula,
    );
    if (cedulaExiste) {
      throw Exception(
        'El número de cédula ingresado ya se encuentra registrado en el sistema.',
      );
    }

    final coincideInstitucion = await _firestoreDatasource
        .verificarCoincidenciaInstitucional(cedula: cedula, correo: correo);

    try {
      final credencial = await _authDatasource.crearCuenta(correo, password);
      final uid = credencial.user!.uid;

      final estadoInicial = coincideInstitucion
          ? EstadoCuenta.ACTIVO
          : EstadoCuenta.PENDIENTE;
      final rolesIniciales = coincideInstitucion
          ? <Rol>[Rol.CIUDADANO]
          : <Rol>[];

      final nuevoUsuario = UsuarioModel(
        uid: uid,
        nombreCompleto: nombreCompleto.trim(),
        correoElectronico: correo.trim().toLowerCase(),
        numeroCedula: cedula.trim(),
        estadoCuenta: estadoInicial,
        roles: rolesIniciales,
        indicadorCambioObligatorio: false,
        fechaRegistro: DateTime.now(),
      );

      await _firestoreDatasource.guardarUsuario(nuevoUsuario);

      if (estadoInicial == EstadoCuenta.PENDIENTE) {
        await _authDatasource.cerrarSesion();
      } else {
        await _localStorageDatasource.guardarRolActivo(Rol.CIUDADANO);
      }

      return nuevoUsuario;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'El correo electrónico ingresado ya se encuentra registrado.',
        );
      }
      throw Exception('No se pudo completar el registro: ${e.message}');
    }
  }

  @override
  Future<void> enviarCorreoRecuperacion(String correo) async {
    try {
      await _authDatasource.enviarEnlaceRecuperacion(correo);
    } catch (_) {}
  }

  @override
  Future<void> cambiarContrasena({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    try {
      await _authDatasource.actualizarContrasena(
        passwordActual: passwordActual,
        passwordNueva: passwordNueva,
      );
    } on FirebaseAuthException {
      throw Exception('La contraseña actual ingresada es incorrecta.');
    }
  }

  @override
  Future<void> completarCambioObligatorioContrasena({
    required String uid,
    required String passwordNueva,
  }) async {
    await _authDatasource.actualizarContrasenaDirecta(passwordNueva);
    await _firestoreDatasource.desmarcarCambioObligatorioContrasena(uid);
  }

  @override
  Future<void> cerrarSesion() async {
    await _localStorageDatasource.limpiarSesionLocal();
    await _authDatasource.cerrarSesion();
  }

  // --- Módulo Administrador e Integración Final (Sprint 5) ---

  @override
  Stream<List<Usuario>> escucharTodosLosUsuarios() {
    return _firestoreDatasource.escucharTodosLosUsuarios();
  }

  @override
  Future<void> aprobarSolicitudUsuario({
    required String uidUsuario,
    required List<Rol> rolesAsignados,
    String? areaResponsable,
    List<String>? especialidades,
    required String adminUid,
  }) async {
    await _firestoreDatasource.aprobarUsuarioInFirestore(
      uid: uidUsuario,
      roles: rolesAsignados,
      areaResponsable: areaResponsable,
      especialidades: especialidades,
      adminUid: adminUid,
    );
  }

  @override
  Future<void> rechazarSolicitudUsuario({
    required String uidUsuario,
    required String motivoRechazo,
    required String adminUid,
  }) async {
    await _firestoreDatasource.rechazarUsuarioInFirestore(
      uid: uidUsuario,
      motivo: motivoRechazo,
      adminUid: adminUid,
    );
  }

  @override
  Future<void> actualizarRolesYDatosUsuario({
    required String uidUsuario,
    required List<Rol> nuevosRoles,
    String? areaResponsable,
    List<String>? especialidades,
  }) async {
    await _firestoreDatasource.actualizarRolesYCampos(
      uid: uidUsuario,
      nuevosRoles: nuevosRoles,
      areaResponsable: areaResponsable,
      especialidades: especialidades,
    );
  }

  @override
  Future<void> desactivarUsuario({
    required String uidUsuario,
    required String adminActualUid,
  }) async {
    // RF-ADM-016: Protección de último Administrador activo
    final snapshot = await _firestoreDatasource
        .escucharTodosLosUsuarios()
        .first;
    final adminsActivos = snapshot.where(
      (u) =>
          u.estadoCuenta == EstadoCuenta.ACTIVO &&
          u.tieneRol(Rol.ADMINISTRADOR),
    );

    if (adminsActivos.length <= 1 &&
        adminsActivos.any((u) => u.uid == uidUsuario)) {
      throw Exception(
        'No se permite desactivar a la cuenta del último Administrador activo del sistema.',
      );
    }

    // RF-ADM-017 y RF-NOT-007: Liberación en cascada de tareas de Encargado en EN_PROCESO
    final usuarioObjetivo = await _firestoreDatasource.obtenerUsuarioPorUid(
      uidUsuario,
    );

    if (usuarioObjetivo != null && usuarioObjetivo.tieneRol(Rol.ENCARGADO)) {
      final tareasEnProceso = await _firestore
          .collection('incidencias')
          .where('idEncargadoAsignado', isEqualTo: uidUsuario)
          .where(
            'estado',
            isEqualTo: EstadoIncidencia.EN_PROCESO.toStorageString(),
          )
          .get();

      for (final doc in tareasEnProceso.docs) {
        // Conmuta a APROBADO y revoca la asignación
        await doc.reference.update({
          'estado': EstadoIncidencia.APROBADO.toStorageString(),
          'idEncargadoAsignado': FieldValue.delete(),
          'nombreEncargadoAsignado': FieldValue.delete(),
          'fechaLiberacion': FieldValue.serverTimestamp(),
          'motivoLiberacion':
              'Tarea liberada automáticamente por desactivación del técnico asignado.',
        });

        // RF-NOT-007: Notifica a todos los Inspectores sobre la liberación
        await _notificacionesDatasource.notificarATodosLosInspectores(
          titulo: 'Incidencia Liberada para Reasignación',
          mensaje:
              'La incidencia [${doc.id.substring(0, 5)}...] ha sido liberada por desactivación del técnico asignado y requiere reasignación.',
          incidenciaId: doc.id,
        );
      }
    }

    // Desactiva físicamente el estado de la cuenta a INACTIVO
    await _firestoreDatasource.desactivarUsuarioInFirestore(
      uid: uidUsuario,
      adminUid: adminActualUid,
    );
  }

  @override
  Future<void> reactivarUsuario({
    required String uidUsuario,
    required List<Rol> rolesActivos,
    String? areaResponsable,
    List<String>? especialidades,
    required String adminUid,
  }) async {
    await _firestoreDatasource.reactivarUsuarioInFirestore(
      uid: uidUsuario,
      roles: rolesActivos,
      areaResponsable: areaResponsable,
      especialidades: especialidades,
      adminUid: adminUid,
    );
  }

  @override
  Future<String> crearUsuarioDirectoPorAdmin({
    required String nombreCompleto,
    required String correo,
    required String cedula,
    required List<Rol> rolesIniciales,
    String? areaResponsable,
    List<String>? especialidades,
  }) async {
    final cedulaExiste = await _firestoreDatasource.existeCedulaRegistrada(
      cedula,
    );
    if (cedulaExiste) {
      throw Exception(
        'El número de cédula ingresado ya se encuentra registrado.',
      );
    }

    final passTemporal =
        'Temp${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}!';

    final newUid = await _authDatasource.crearUsuarioPorAdminSinCerrarSesion(
      correo: correo,
      passwordTemporal: passTemporal,
    );

    final nuevoModel = UsuarioModel(
      uid: newUid,
      nombreCompleto: nombreCompleto.trim(),
      correoElectronico: correo.trim().toLowerCase(),
      numeroCedula: cedula.trim(),
      estadoCuenta: EstadoCuenta.ACTIVO,
      roles: rolesIniciales,
      indicadorCambioObligatorio: true,
      areaResponsable: areaResponsable,
      tipoDeEncargado: especialidades,
      numeroTareasActivas: rolesIniciales.contains(Rol.ENCARGADO) ? 0 : null,
      fechaRegistro: DateTime.now(),
    );

    await _firestoreDatasource.guardarUsuario(nuevoModel);
    return passTemporal;
  }
}
