import '../entities/rol.dart';
import '../entities/usuario.dart';
import '../repositories/i_usuario_repository.dart';

/// Clase CasoDeUsoGestionarUsuarios especificada en SDD 3.2.2 y 3.4.2
class CasoDeUsoGestionarUsuarios {
  final IUsuarioRepository _repository;

  CasoDeUsoGestionarUsuarios(this._repository);

  void _validarPermisoAdmin(Usuario invocante) {
    if (!invocante.tieneRol(Rol.ADMINISTRADOR)) {
      throw Exception(
        'Acceso denegado: Se requiere el rol de Administrador para ejecutar esta operación.',
      );
    }
  }

  Stream<List<Usuario>> escucharPadronUsuarios() {
    return _repository.escucharTodosLosUsuarios();
  }

  Future<void> aprobarUsuario({
    required Usuario adminInvocante,
    required Usuario usuarioObjetivo,
    required List<Rol> roles,
    String? areaResponsable,
    List<String>? especialidades,
  }) async {
    _validarPermisoAdmin(adminInvocante);
    if (roles.isEmpty) {
      throw Exception('Debe asignar al menos un rol activo al usuario.');
    }
    if (roles.contains(Rol.ENCARGADO)) {
      if (areaResponsable == null || areaResponsable.trim().isEmpty) {
        throw Exception(
          'El Área Responsable es obligatoria para el rol Encargado.',
        );
      }
      if (especialidades == null || especialidades.isEmpty) {
        throw Exception(
          'Debe seleccionar al menos una especialidad para el rol Encargado.',
        );
      }
    }
    await _repository.aprobarSolicitudUsuario(
      uidUsuario: usuarioObjetivo.uid,
      rolesAsignados: roles,
      areaResponsable: areaResponsable,
      especialidades: especialidades,
      adminUid: adminInvocante.uid,
    );
  }

  Future<void> rechazarUsuario({
    required Usuario adminInvocante,
    required Usuario usuarioObjetivo,
    required String motivo,
  }) async {
    _validarPermisoAdmin(adminInvocante);
    if (motivo.trim().isEmpty) {
      throw Exception('El motivo de rechazo es obligatorio.');
    }
    await _repository.rechazarSolicitudUsuario(
      uidUsuario: usuarioObjetivo.uid,
      motivoRechazo: motivo.trim(),
      adminUid: adminInvocante.uid,
    );
  }

  Future<void> modificarRolesUsuario({
    required Usuario adminInvocante,
    required Usuario usuarioObjetivo,
    required List<Rol> nuevosRoles,
    String? areaResponsable,
    List<String>? especialidades,
  }) async {
    _validarPermisoAdmin(adminInvocante);
    if (nuevosRoles.isEmpty) {
      throw Exception(
        'La cuenta debe conservar siempre al menos un rol activo.',
      );
    }
    if (nuevosRoles.contains(Rol.ENCARGADO)) {
      if (areaResponsable == null || areaResponsable.trim().isEmpty) {
        throw Exception(
          'El Área Responsable es obligatoria para el rol Encargado.',
        );
      }
      if (especialidades == null || especialidades.isEmpty) {
        throw Exception(
          'Debe seleccionar al menos una especialidad para el rol Encargado.',
        );
      }
    }
    await _repository.actualizarRolesYDatosUsuario(
      uidUsuario: usuarioObjetivo.uid,
      nuevosRoles: nuevosRoles,
      areaResponsable: areaResponsable,
      especialidades: especialidades,
    );
  }

  Future<void> desactivarUsuario({
    required Usuario adminInvocante,
    required Usuario usuarioObjetivo,
  }) async {
    _validarPermisoAdmin(adminInvocante);
    // RF-ADM-021: Impedir autodesactivación
    if (adminInvocante.uid == usuarioObjetivo.uid) {
      throw Exception(
        'No puede desactivar su propia cuenta mientras se encuentra autenticado con ella.',
      );
    }
    await _repository.desactivarUsuario(
      uidUsuario: usuarioObjetivo.uid,
      adminActualUid: adminInvocante.uid,
    );
  }

  Future<void> reactivarUsuario({
    required Usuario adminInvocante,
    required Usuario usuarioObjetivo,
    required List<Rol> rolesActivos,
    String? areaResponsable,
    List<String>? especialidades,
  }) async {
    _validarPermisoAdmin(adminInvocante);
    if (rolesActivos.isEmpty) {
      throw Exception(
        'Debe verificar o reasignar al menos un rol activo antes de reactivar la cuenta.',
      );
    }
    if (rolesActivos.contains(Rol.ENCARGADO)) {
      if (areaResponsable == null || areaResponsable.trim().isEmpty) {
        throw Exception(
          'El Área Responsable es obligatoria para el rol Encargado.',
        );
      }
      if (especialidades == null || especialidades.isEmpty) {
        throw Exception(
          'Debe seleccionar al menos una especialidad para el rol Encargado.',
        );
      }
    }
    await _repository.reactivarUsuario(
      uidUsuario: usuarioObjetivo.uid,
      rolesActivos: rolesActivos,
      areaResponsable: areaResponsable,
      especialidades: especialidades,
      adminUid: adminInvocante.uid,
    );
  }

  Future<String> crearUsuario({
    required Usuario adminInvocante,
    required String nombre,
    required String correo,
    required String cedula,
    required List<Rol> rolesIniciales,
    String? areaResponsable,
    List<String>? especialidades,
  }) async {
    _validarPermisoAdmin(adminInvocante);
    if (rolesIniciales.isEmpty) {
      throw Exception('Debe seleccionar al menos un rol inicial.');
    }
    if (rolesIniciales.contains(Rol.ENCARGADO)) {
      if (areaResponsable == null || areaResponsable.trim().isEmpty) {
        throw Exception(
          'El Área Responsable es obligatoria para el rol Encargado.',
        );
      }
      if (especialidades == null || especialidades.isEmpty) {
        throw Exception(
          'Debe seleccionar al menos una especialidad para el rol Encargado.',
        );
      }
    }
    return await _repository.crearUsuarioDirectoPorAdmin(
      nombreCompleto: nombre,
      correo: correo,
      cedula: cedula,
      rolesIniciales: rolesIniciales,
      areaResponsable: areaResponsable,
      especialidades: especialidades,
    );
  }
}
