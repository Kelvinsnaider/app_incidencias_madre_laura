import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/incidencia.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/auth_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/incidencia_provider.dart';

/// Vista 15: Detalle de la Tarea (Manual Funcional Parte 5 y RNF-PER-003)
class DetalleTareaEncargadoPage extends ConsumerStatefulWidget {
  final Incidencia incidencia;

  const DetalleTareaEncargadoPage({super.key, required this.incidencia});

  @override
  ConsumerState<DetalleTareaEncargadoPage> createState() =>
      _DetalleTareaEncargadoPageState();
}

class _DetalleTareaEncargadoPageState
    extends ConsumerState<DetalleTareaEncargadoPage> {
  bool _procesando = false;

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio a las $hora:$min';
  }

  Widget _buildImagen(String fotoData) {
    if (fotoData.startsWith('http')) {
      return Image.network(
        fotoData,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.black38),
        ),
      );
    }
    try {
      final bytes = base64Decode(fotoData.replaceAll(RegExp(r'\s+'), ''));
      return Image.memory(
        bytes,
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

  /// Visor interactivo a pantalla completa con soporte de Zoom HD (InteractiveViewer)
  void _abrirVisorFotoAmpliada(String fotoData) {
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
              maxScale: 4.0,
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

  // RF-ENC-003: Iniciar trabajo con marca de tiempo inmutable
  Future<void> _iniciarTrabajo() async {
    final usuarioActual = ref.read(authProvider).usuario;
    if (usuarioActual == null) return;

    setState(() => _procesando = true);
    try {
      final useCase = ref.read(resolverIncidenciaUseCaseProvider);
      await useCase.iniciarTrabajo(
        encargadoInvocante: usuarioActual,
        incidencia: widget.incidencia,
      );

      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicio de actividades registrado correctamente.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // RF-ENC-004, RF-ENC-005, RF-ENC-006: Captura EXCLUSIVA con cámara nativa en HD
  void _mostrarFormularioSolucion() {
    final comentariosCtrl = TextEditingController();
    final List<File> fotosSolucion = [];
    final ImagePicker picker = ImagePicker();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            Future<void> tomarFotoCamaraExclusiva() async {
              if (fotosSolucion.length >= 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Se permite un máximo de 3 fotografías.'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }

              try {
                // RF-ENC-006 y RNF-PER-003: Captura EXCLUSIVA con cámara nativa a 1280x1280 px
                final XFile? foto = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1280, // Resolución HD
                  maxHeight: 1280,
                  imageQuality: 75, // Nitidez superior
                );

                if (foto != null) {
                  setModalState(() {
                    fotosSolucion.add(File(foto.path));
                  });
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Se requiere permiso de acceso a la cámara.'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reportar Solución de la Tarea',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: comentariosCtrl,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Comentarios técnicos (Opcional)',
                        hintText:
                            'Describa los trabajos de reparación realizados...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Evidencia HD en Tiempo Real (Cámara)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${fotosSolucion.length}/3 (Min 1)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: fotosSolucion.isNotEmpty
                                ? AppTheme.accentColor
                                : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Botón de captura EXCLUSIVA de Cámara HD (RF-ENC-006)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      onPressed: tomarFotoCamaraExclusiva,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Tomar Foto de Solución HD con Cámara'),
                    ),
                    const SizedBox(height: 10),

                    if (fotosSolucion.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: fotosSolucion.length,
                          itemBuilder: (c, idx) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(fotosSolucion[idx]),
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        fotosSolucion.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (fotosSolucion.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Debe tomar al menos una (1) fotografía con la cámara.',
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }

                        final usuarioActual = ref.read(authProvider).usuario;
                        if (usuarioActual == null) return;

                        Navigator.pop(modalCtx);
                        setState(() => _procesando = true);

                        try {
                          final useCase = ref.read(
                            resolverIncidenciaUseCaseProvider,
                          );
                          await useCase.marcarComoSolucionada(
                            encargadoInvocante: usuarioActual,
                            incidencia: widget.incidencia,
                            comentarios: comentariosCtrl.text,
                            fotosSolucion: fotosSolucion,
                          );

                          if (!mounted) return;
                          setState(() => _procesando = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Solución HD enviada correctamente a inspección.',
                              ),
                              backgroundColor: AppTheme.accentColor,
                            ),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _procesando = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceFirst('Exception: ', ''),
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Enviar Solución a Inspección'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inc = widget.incidencia;
    final estado = inc.estado;
    final esEnProceso = estado == EstadoIncidencia.EN_PROCESO;
    final yaIniciado = inc.fechaInicioTrabajo != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la Tarea')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de Estado
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: esEnProceso
                    ? Colors.blue.shade50
                    : (estado == EstadoIncidencia.PARA_VALIDAR
                          ? Colors.purple.shade50
                          : Colors.green.shade50),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: esEnProceso
                      ? Colors.blue.shade300
                      : (estado == EstadoIncidencia.PARA_VALIDAR
                            ? Colors.purple.shade300
                            : Colors.green.shade300),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    esEnProceso
                        ? Icons.build_circle_outlined
                        : (estado == EstadoIncidencia.PARA_VALIDAR
                              ? Icons.hourglass_top_rounded
                              : Icons.check_circle_outline_rounded),
                    color: esEnProceso
                        ? AppTheme.primaryColor
                        : (estado == EstadoIncidencia.PARA_VALIDAR
                              ? Colors.purple.shade800
                              : AppTheme.accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      esEnProceso
                          ? (yaIniciado
                                ? 'Trabajo en Ejecución — Iniciado el ${_formatearFecha(inc.fechaInicioTrabajo!)}'
                                : 'Tarea asignada pendiente de iniciar trabajo físico.')
                          : (estado == EstadoIncidencia.PARA_VALIDAR
                                ? 'Esperando validación del Inspector'
                                : 'Tarea Aprobada y Cerrada'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (inc.motivoRechazoDevolucion != null &&
                inc.motivoRechazoDevolucion!.isNotEmpty) ...[
              Card(
                color: Colors.orange.shade50,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.orange.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Observación del Inspector (Devuelta):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(inc.motivoRechazoDevolucion!),
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
                      'Categoría: ${inc.categoria}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Subcategoría: ${inc.subcategoria}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Ubicación: ${inc.ubicacionFormateada}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (inc.descripcion != null &&
                        inc.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Descripción: ${inc.descripcion}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Evidencia fotográfica inicial con visor táctil y renderizado HD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evidencia Inicial del Ciudadano',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '(Toque para ampliar)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: inc.urlsFotosEvidencia.length,
                itemBuilder: (ctx, idx) {
                  final data = inc.urlsFotosEvidencia[idx];
                  return GestureDetector(
                    onTap: () => _abrirVisorFotoAmpliada(data),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildImagen(data),
                    ),
                  );
                },
              ),
            ),

            // Evidencias de la solución con visor táctil y renderizado HD
            if (inc.urlsFotosSolucion != null &&
                inc.urlsFotosSolucion!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Solución Enviada por Usted',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  Text(
                    '(Toque para ampliar)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: inc.urlsFotosSolucion!.length,
                  itemBuilder: (ctx, idx) {
                    final data = inc.urlsFotosSolucion![idx];
                    return GestureDetector(
                      onTap: () => _abrirVisorFotoAmpliada(data),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildImagen(data),
                      ),
                    );
                  },
                ),
              ),
              if (inc.comentariosSolucion != null &&
                  inc.comentariosSolucion!.isNotEmpty) ...[
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
                        Text(inc.comentariosSolucion!),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 28),

            // Botones de acción
            if (esEnProceso) ...[
              if (!yaIniciado) ...[
                ElevatedButton.icon(
                  onPressed: _procesando ? null : _iniciarTrabajo,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar trabajo'),
                ),
                const SizedBox(height: 10),
              ],

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
                onPressed: (yaIniciado && !_procesando)
                    ? _mostrarFormularioSolucion
                    : null,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Marcar como solucionada'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
