import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthDatasource({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  User? get usuarioActual => _firebaseAuth.currentUser;

  Future<UserCredential> iniciarSesion(String correo, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: password,
    );
  }

  Future<UserCredential> crearCuenta(String correo, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: correo.trim(),
      password: password,
    );
  }

  /// RF-ADM-019 y RF-ADM-020: Crear cuenta directa por el Admin sin cerrar la sesión activa del Administrador
  Future<String> crearUsuarioPorAdminSinCerrarSesion({
    required String correo,
    required String passwordTemporal,
  }) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempAppAdmin_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      UserCredential cred = await tempAuth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: passwordTemporal,
      );
      String newUid = cred.user!.uid;
      await tempAuth.signOut();
      return newUid;
    } finally {
      await tempApp.delete();
    }
  }

  Future<void> enviarEnlaceRecuperacion(String correo) async {
    await _firebaseAuth.sendPasswordResetEmail(email: correo.trim());
  }

  Future<void> actualizarContrasena({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No existe una sesión activa.');
    }
    final credencial = EmailAuthProvider.credential(
      email: user.email!,
      password: passwordActual,
    );
    await user.reauthenticateWithCredential(credencial);
    await user.updatePassword(passwordNueva);
  }

  /// RF-AUT-009: Completar el cambio obligatorio de contraseña temporal (Vista 1B)
  Future<void> actualizarContrasenaDirecta(String passwordNueva) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No existe una sesión activa para cambiar contraseña.');
    }
    await user.updatePassword(passwordNueva);
  }

  Future<void> cerrarSesion() async {
    await _firebaseAuth.signOut();
  }
}
