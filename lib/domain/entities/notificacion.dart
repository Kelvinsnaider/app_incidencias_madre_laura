/// Entidad de Dominio para el Centro de Notificaciones (Vista 16 y RF-NOT-006)
class NotificacionSistema {
  final String id;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  final String incidenciaId;
  final bool leida;

  const NotificacionSistema({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.incidenciaId,
    this.leida = false,
  });

  NotificacionSistema copyWith({
    String? id,
    String? titulo,
    String? mensaje,
    DateTime? fecha,
    String? incidenciaId,
    bool? leida,
  }) {
    return NotificacionSistema(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      fecha: fecha ?? this.fecha,
      incidenciaId: incidenciaId ?? this.incidenciaId,
      leida: leida ?? this.leida,
    );
  }
}
