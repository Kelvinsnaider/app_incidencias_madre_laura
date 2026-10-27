import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../domain/entities/incidencia.dart';
import '../../domain/entities/rol.dart';

class DetalleIncidenciaPage extends StatelessWidget {
  final Incidencia incidencia;
  final bool esVistaPublicaComunidad;

  const DetalleIncidenciaPage({
    super.key,
    required this.incidencia,
    this.esVistaPublicaComunidad = false,
  });

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio a las $hora:$min';
  }

  Widget _buildImagenGeneral(String fotoData) {
    if (fotoData.startsWith('http')) {
      return Image.network(
        fotoData,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.black38),
        ),
      );
    }
    try {
      final cleanBase64 = fotoData.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64Decode(cleanBase64);
      return Image.memory(
        bytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.black38),
        ),
      );
    } catch (_) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.black38),
      );
    }
  }

  /// Visor nativo a pantalla completa con soporte de Zoom HD (InteractiveViewer)
  void _abrirVisorFotoAmpliada(BuildContext context, String fotoData) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 5.0, // Zoom de alta precisión
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: fotoData.startsWith('http')
                    ? Image.network(
                        fotoData,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      )
                    : Image.memory(
                        base64Decode(fotoData.replaceAll(RegExp(r'\s+'), '')),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineUI() {
    final esRechazado = incidencia.estado == EstadoIncidencia.RECHAZADO;

    if (esRechazado) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppTheme.errorColor, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Línea de tiempo interrumpida: El reporte fue rechazado por la inspección técnica.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final nodos = [
      EstadoIncidencia.NUEVO,
      EstadoIncidencia.APROBADO,
      EstadoIncidencia.EN_PROCESO,
      EstadoIncidencia.PARA_VALIDAR,
      EstadoIncidencia.FINALIZADO,
    ];

    int indiceActual = nodos.indexOf(incidencia.estado);
    if (indiceActual == -1) indiceActual = 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seguimiento del Estado de Atención (Timeline)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(nodos.length, (i) {
              final estaCompletado = i <= indiceActual;
              final esUltimo = i == nodos.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: estaCompletado
                          ? AppTheme.accentColor
                          : Colors.grey.shade300,
                      child: Icon(
                        estaCompletado ? Icons.check : Icons.circle,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (!esUltimo)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: i < indiceActual
                              ? AppTheme.accentColor
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEtiquetaNodo('Nuevo', 0 <= indiceActual),
              _buildEtiquetaNodo('Aprobado', 1 <= indiceActual),
              _buildEtiquetaNodo('En Proceso', 2 <= indiceActual),
              _buildEtiquetaNodo('Para Validar', 3 <= indiceActual),
              _buildEtiquetaNodo('Finalizado', 4 <= indiceActual),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEtiquetaNodo(String texto, bool activo) {
    return SizedBox(
      width: 58,
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          fontWeight: activo ? FontWeight.bold : FontWeight.normal,
          color: activo ? AppTheme.accentColor : Colors.black45,
        ),
      ),
    );
  }

  String _obtenerMensajeInformativoEstado() {
    switch (incidencia.estado) {
      case EstadoIncidencia.NUEVO:
        return 'La incidencia se encuentra pendiente de revisión por parte de un Inspector.';
      case EstadoIncidencia.APROBADO:
        return 'La incidencia fue aceptada y está pendiente de asignación al personal técnico.';
      case EstadoIncidencia.EN_PROCESO:
        return 'La incidencia está siendo atendida por el personal responsable de mantenimiento.';
      case EstadoIncidencia.PARA_VALIDAR:
        return 'La reparación fue completada por el encargado y está esperando validación por parte del Inspector.';
      case EstadoIncidencia.FINALIZADO:
        return 'La incidencia fue solucionada satisfactoriamente.';
      case EstadoIncidencia.RECHAZADO:
        return 'La incidencia fue rechazada durante la revisión inicial del Inspector.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final esRechazado = incidencia.estado == EstadoIncidencia.RECHAZADO;
    final esFinalizado = incidencia.estado == EstadoIncidencia.FINALIZADO;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          esVistaPublicaComunidad
              ? 'Detalle Público de Incidencia'
              : 'Detalle de Incidencia',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineUI(),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: esRechazado
                    ? Colors.red.shade50
                    : AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: esRechazado
                      ? Colors.red.shade300
                      : AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    esRechazado
                        ? Icons.info_outline
                        : Icons.info_outline_rounded,
                    color: esRechazado
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _obtenerMensajeInformativoEstado(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: esRechazado
                            ? AppTheme.errorColor
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (esRechazado && incidencia.motivoRechazoDevolucion != null) ...[
              Card(
                color: Colors.red.shade50,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.red.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Motivo del Rechazo (Inspector):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(incidencia.motivoRechazoDevolucion!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoría: ${incidencia.categoria}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha de Reporte: ${_formatearFecha(incidencia.fechaCreacion)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subcategoría: ${incidencia.subcategoria}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Ubicación: ${incidencia.ubicacionFormateada}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (incidencia.descripcion != null &&
                        incidencia.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Descripción:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        incidencia.descripcion!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    if (!esVistaPublicaComunidad &&
                        incidencia.nombreUsuarioReporta != null) ...[
                      const Divider(height: 20),
                      Text(
                        'Reportado por: ${incidencia.nombreUsuarioReporta}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evidencia Fotográfica Inicial',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '(Toque para ampliar en HD)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: incidencia.urlsFotosEvidencia.length,
                itemBuilder: (ctx, idx) {
                  final data = incidencia.urlsFotosEvidencia[idx];
                  return GestureDetector(
                    onTap: () => _abrirVisorFotoAmpliada(context, data),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildImagenGeneral(data),
                    ),
                  );
                },
              ),
            ),
            if (esFinalizado &&
                incidencia.urlsFotosSolucion != null &&
                incidencia.urlsFotosSolucion!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Evidencia de la Reparación (Solución)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  Text(
                    '(Toque para ampliar en HD)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: incidencia.urlsFotosSolucion!.length,
                  itemBuilder: (ctx, idx) {
                    final data = incidencia.urlsFotosSolucion![idx];
                    return GestureDetector(
                      onTap: () => _abrirVisorFotoAmpliada(context, data),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildImagenGeneral(data),
                      ),
                    );
                  },
                ),
              ),
              if (incidencia.comentariosSolucion != null &&
                  incidencia.comentariosSolucion!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Card(
                  color: Colors.green.shade50,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comentarios del Técnico Encargado:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(incidencia.comentariosSolucion!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
