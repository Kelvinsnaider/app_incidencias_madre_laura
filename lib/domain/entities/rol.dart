// ignore_for_file: constant_identifier_names

enum Rol {
  CIUDADANO,
  INSPECTOR,
  ENCARGADO,
  ADMINISTRADOR;

  String toStorageString() => name;

  static Rol fromStorageString(String value) {
    final clean = value.trim().toUpperCase();
    return Rol.values.firstWhere(
      (e) => e.name.toUpperCase() == clean,
      orElse: () => Rol.CIUDADANO,
    );
  }

  String get etiquetaVisual {
    switch (this) {
      case Rol.CIUDADANO:
        return 'Ciudadano';
      case Rol.INSPECTOR:
        return 'Inspector';
      case Rol.ENCARGADO:
        return 'Encargado';
      case Rol.ADMINISTRADOR:
        return 'Administrador';
    }
  }
}

enum EstadoCuenta {
  PENDIENTE,
  ACTIVO,
  INACTIVO,
  RECHAZADO;

  String toStorageString() => name;

  static EstadoCuenta fromStorageString(String value) {
    final clean = value.trim().toUpperCase();
    return EstadoCuenta.values.firstWhere(
      (e) => e.name.toUpperCase() == clean,
      orElse: () => EstadoCuenta.PENDIENTE,
    );
  }
}

enum EstadoIncidencia {
  NUEVO,
  APROBADO,
  EN_PROCESO,
  PARA_VALIDAR,
  FINALIZADO,
  RECHAZADO;

  String toStorageString() => name;

  static EstadoIncidencia fromStorageString(String value) {
    final clean = value.trim().toUpperCase();
    return EstadoIncidencia.values.firstWhere(
      (e) => e.name.toUpperCase() == clean,
      orElse: () => EstadoIncidencia.NUEVO,
    );
  }
}
