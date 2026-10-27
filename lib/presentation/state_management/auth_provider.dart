import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/firestore_datasource.dart';
import '../../data/datasources/local_storage_datasource.dart';
import '../../data/repositories/usuario_repository_impl.dart';
import '../../domain/entities/rol.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/i_usuario_repository.dart';
import '../../domain/usecases/gestionar_usuarios_usecase.dart';

final usuarioRepositoryProvider = Provider<IUsuarioRepository>((ref) {
  return UsuarioRepositoryImpl(
    authDatasource: FirebaseAuthDatasource(),
    firestoreDatasource: FirestoreDatasource(),
    localStorageDatasource: LocalStorageDatasource(),
  );
});

final gestionarUsuariosUseCaseProvider = Provider<CasoDeUsoGestionarUsuarios>((
  ref,
) {
  final repo = ref.watch(usuarioRepositoryProvider);
  return CasoDeUsoGestionarUsuarios(repo);
});

final padronUsuariosStreamProvider = StreamProvider<List<Usuario>>((ref) {
  final useCase = ref.watch(gestionarUsuariosUseCaseProvider);
  return useCase.escucharPadronUsuarios();
});

class AuthState {
  final Usuario? usuario;
  final Rol? rolActivo; // Rol seleccionado en el contexto actual
  final bool cargando;
  final String? error;

  const AuthState({
    this.usuario,
    this.rolActivo,
    this.cargando = false,
    this.error,
  });

  AuthState copyWith({
    Usuario? usuario,
    Rol? rolActivo,
    bool? cargando,
    String? error,
    bool limpiarUsuario = false,
  }) {
    return AuthState(
      usuario: limpiarUsuario ? null : (usuario ?? this.usuario),
      rolActivo: rolActivo ?? this.rolActivo,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  IUsuarioRepository get _repository => ref.read(usuarioRepositoryProvider);
  final LocalStorageDatasource _local = LocalStorageDatasource();

  Future<Usuario?> verificarSesionInicial() async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final user = await _repository.obtenerSesionActual();
      final rolGuardado = await _local.obtenerRolActivo();
      final rolFinal =
          rolGuardado ??
          (user?.roles.isNotEmpty == true ? user!.roles.first : null);

      state = AuthState(usuario: user, rolActivo: rolFinal, cargando: false);
      return user;
    } catch (_) {
      state = const AuthState(usuario: null, cargando: false);
      return null;
    }
  }

  Future<Usuario?> iniciarSesion(String correo, String password) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final user = await _repository.iniciarSesion(
        correo: correo,
        password: password,
      );
      final rolGuardado = await _local.obtenerRolActivo();
      final rolFinal =
          rolGuardado ?? (user.roles.isNotEmpty ? user.roles.first : null);

      state = AuthState(usuario: user, rolActivo: rolFinal, cargando: false);
      return user;
    } catch (e) {
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(cargando: false, error: mensaje);
      return null;
    }
  }

  /// Conmuta reactivamente el rol activo y lo persiste localmente
  Future<void> seleccionarRolActivo(Rol nuevoRol) async {
    await _local.guardarRolActivo(nuevoRol);
    state = state.copyWith(rolActivo: nuevoRol);
  }

  Future<Usuario?> registrarUsuario({
    required String nombreCompleto,
    required String correo,
    required String cedula,
    required String password,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final nuevo = await _repository.registrarUsuario(
        nombreCompleto: nombreCompleto,
        correo: correo,
        cedula: cedula,
        password: password,
      );
      final esActivo = nuevo.estadoCuenta == EstadoCuenta.ACTIVO;
      state = AuthState(
        usuario: esActivo ? nuevo : null,
        rolActivo: esActivo ? Rol.CIUDADANO : null,
        cargando: false,
      );
      return nuevo;
    } catch (e) {
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(cargando: false, error: mensaje);
      return null;
    }
  }

  Future<void> recuperarContrasena(String correo) async {
    state = state.copyWith(cargando: true, error: null);
    await _repository.enviarCorreoRecuperacion(correo);
    state = state.copyWith(cargando: false);
  }

  Future<bool> cambiarContrasena({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _repository.cambiarContrasena(
        passwordActual: passwordActual,
        passwordNueva: passwordNueva,
      );
      state = state.copyWith(cargando: false);
      return true;
    } catch (e) {
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(cargando: false, error: mensaje);
      return false;
    }
  }

  Future<bool> completarCambioObligatorioContrasena(String nuevaClave) async {
    if (state.usuario == null) return false;
    state = state.copyWith(cargando: true, error: null);
    try {
      await _repository.completarCambioObligatorioContrasena(
        uid: state.usuario!.uid,
        passwordNueva: nuevaClave,
      );
      final usuarioActualizado = state.usuario!.copyWith(
        indicadorCambioObligatorio: false,
      );
      state = state.copyWith(usuario: usuarioActualizado, cargando: false);
      return true;
    } catch (e) {
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(cargando: false, error: mensaje);
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    await _repository.cerrarSesion();
    state = const AuthState(usuario: null, rolActivo: null, cargando: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
