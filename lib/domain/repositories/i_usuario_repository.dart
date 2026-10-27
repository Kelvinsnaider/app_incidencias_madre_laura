import '../entities/rol.dart';
import '../entities/usuario.dart';

abstract class IUsuarioRepository {
  Future<Usuario?> obtenerSesionActual();
  Future<Usuario> iniciarSesion({
    required String correo,
    required String password,
  });
  Future<Usuario> registrarUsuario({
    required String nombreCompleto,
    required String correo,
    required String cedula,
    required String password,
  });
  Future<void> enviarCorreoRecuperacion(String correo);
  Future<void> cambiarContrasena({
    required String passwordActual,
    required String passwordNueva,
  });
  Future<void> completarCambioObligatorioContrasena({
    required String uid,
    required String passwordNueva,
  });
  Future<void> cerrarSesion();

  // --- Métodos del Módulo Administrador (Sprint 2) ---
  Stream<List<Usuario>> escucharTodosLosUsuarios();
  Future<void> aprobarSolicitudUsuario({
    required String uidUsuario,
    required List<Rol> rolesAsignados,
    String? areaResponsable,
    List<String>? especialidades,
    required String adminUid,
  });
  Future<void> rechazarSolicitudUsuario({
    required String uidUsuario,
    required String motivoRechazo,
    required String adminUid,
  });
  Future<void> actualizarRolesYDatosUsuario({
    required String uidUsuario,
    required List<Rol> nuevosRoles,
    String? areaResponsable,
    List<String>? especialidades,
  });
  Future<void> desactivarUsuario({
    required String uidUsuario,
    required String adminActualUid,
  });
  Future<void> reactivarUsuario({
    required String uidUsuario,
    required List<Rol> rolesActivos,
    String? areaResponsable,
    List<String>? especialidades,
    required String adminUid,
  });
  Future<String> crearUsuarioDirectoPorAdmin({
    required String nombreCompleto,
    required String correo,
    required String cedula,
    required List<Rol> rolesIniciales,
    String? areaResponsable,
    List<String>? especialidades,
  });
}
