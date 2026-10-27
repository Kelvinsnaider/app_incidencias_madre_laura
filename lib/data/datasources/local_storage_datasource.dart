import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/rol.dart';

class LocalStorageDatasource {
  static const String _keyRolActivo = 'rol_activo_usuario';

  Future<void> guardarRolActivo(Rol rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRolActivo, rol.toStorageString());
  }

  Future<Rol?> obtenerRolActivo() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString(_keyRolActivo);
    if (valor == null || valor.isEmpty) return null;
    return Rol.fromStorageString(valor);
  }

  Future<void> limpiarSesionLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRolActivo);
  }
}