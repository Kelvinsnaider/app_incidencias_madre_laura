import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/rol.dart';
import '../../domain/entities/usuario.dart';

class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.uid,
    required super.nombreCompleto,
    required super.correoElectronico,
    required super.numeroCedula,
    required super.estadoCuenta,
    required super.roles,
    super.indicadorCambioObligatorio = false,
    super.areaResponsable,
    super.tipoDeEncargado,
    super.numeroTareasActivas,
    super.nivelDeAcceso,
    super.fechaRegistro,
    super.motivoRechazo,
  });

  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final rolesRaw = data['roles'] as List<dynamic>? ?? [];
    final rolesList = rolesRaw
        .map((r) => Rol.fromStorageString(r.toString()))
        .toList();

    List<String>? especialidades;
    if (data['tipoDeEncargado'] is List) {
      especialidades = (data['tipoDeEncargado'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (data['tipoDeEncargado'] is String &&
        (data['tipoDeEncargado'] as String).isNotEmpty) {
      especialidades = [data['tipoDeEncargado'] as String];
    }

    DateTime? fechaReg;
    if (data['fechaRegistro'] is Timestamp) {
      fechaReg = (data['fechaRegistro'] as Timestamp).toDate();
    }

    return UsuarioModel(
      uid: doc.id,
      nombreCompleto: data['nombreCompleto'] ?? '',
      correoElectronico: data['correoElectronico'] ?? '',
      numeroCedula: data['numeroCedula'] ?? '',
      estadoCuenta: EstadoCuenta.fromStorageString(
        data['estado'] ?? data['estadoCuenta'] ?? 'PENDIENTE',
      ),
      roles: rolesList,
      indicadorCambioObligatorio:
          data['indicador_cambio_obligatorio'] as bool? ?? false,
      areaResponsable: data['areaResponsable'] as String?,
      tipoDeEncargado: especialidades,
      numeroTareasActivas: data['numeroTareasActivas'] as int?,
      nivelDeAcceso: data['nivelDeAcceso'] as int?,
      fechaRegistro: fechaReg,
      motivoRechazo: data['motivoRechazo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'nombreCompleto': nombreCompleto,
      'correoElectronico': correoElectronico,
      'numeroCedula': numeroCedula,
      'estado': estadoCuenta.toStorageString(),
      'roles': roles.map((r) => r.toStorageString()).toList(),
      'indicador_cambio_obligatorio': indicadorCambioObligatorio,
      'fechaRegistro': fechaRegistro != null
          ? Timestamp.fromDate(fechaRegistro!)
          : FieldValue.serverTimestamp(),
    };

    if (tieneRol(Rol.ENCARGADO)) {
      map['areaResponsable'] = areaResponsable;
      map['tipoDeEncargado'] = tipoDeEncargado ?? [];
      map['numeroTareasActivas'] = numeroTareasActivas ?? 0;
    }
    if (tieneRol(Rol.ADMINISTRADOR)) {
      map['nivelDeAcceso'] = nivelDeAcceso ?? 1;
    }
    if (motivoRechazo != null) {
      map['motivoRechazo'] = motivoRechazo;
    }
    return map;
  }
}