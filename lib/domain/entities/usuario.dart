import 'rol.dart';

class Usuario {
  final String uid;
  final String nombreCompleto;
  final String correoElectronico;
  final String numeroCedula;
  final EstadoCuenta estadoCuenta;
  final List<Rol> roles;
  final bool indicadorCambioObligatorio;
  final String? areaResponsable;
  final List<String>? tipoDeEncargado;
  final int? numeroTareasActivas;
  final int? nivelDeAcceso;
  final DateTime? fechaRegistro;
  final String? motivoRechazo;

  const Usuario({
    required this.uid,
    required this.nombreCompleto,
    required this.correoElectronico,
    required this.numeroCedula,
    required this.estadoCuenta,
    required this.roles,
    this.indicadorCambioObligatorio = false,
    this.areaResponsable,
    this.tipoDeEncargado,
    this.numeroTareasActivas,
    this.nivelDeAcceso,
    this.fechaRegistro,
    this.motivoRechazo,
  });

  /// Método de dominio especificado en SDD 3.2.2
  bool tieneRol(Rol rol) {
    return roles.contains(rol);
  }

  Usuario copyWith({
    String? uid,
    String? nombreCompleto,
    String? correoElectronico,
    String? numeroCedula,
    EstadoCuenta? estadoCuenta,
    List<Rol>? roles,
    bool? indicadorCambioObligatorio,
    String? areaResponsable,
    List<String>? tipoDeEncargado,
    int? numeroTareasActivas,
    int? nivelDeAcceso,
    DateTime? fechaRegistro,
    String? motivoRechazo,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      numeroCedula: numeroCedula ?? this.numeroCedula,
      estadoCuenta: estadoCuenta ?? this.estadoCuenta,
      roles: roles ?? this.roles,
      indicadorCambioObligatorio:
          indicadorCambioObligatorio ?? this.indicadorCambioObligatorio,
      areaResponsable: areaResponsable ?? this.areaResponsable,
      tipoDeEncargado: tipoDeEncargado ?? this.tipoDeEncargado,
      numeroTareasActivas: numeroTareasActivas ?? this.numeroTareasActivas,
      nivelDeAcceso: nivelDeAcceso ?? this.nivelDeAcceso,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
    );
  }
}