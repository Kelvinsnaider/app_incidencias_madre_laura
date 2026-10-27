import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/incidencia.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/domain/entities/usuario.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/auth_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/incidencia_provider.dart';

/// Vista 13: Detalle de Incidencia (gestión) (Manual Funcional y RNF-PER-003)
class DetalleIncidenciaInspectorPage extends ConsumerStatefulWidget {
  final Incidencia incidencia;

  const DetalleIncidenciaInspectorPage({super.key, required this.incidencia});

  @override
  ConsumerState<DetalleIncidenciaInspectorPage> createState() =>
      _DetalleIncidenciaInspectorPageState();
}

class _DetalleIncidenciaInspectorPageState
    extends ConsumerState<DetalleIncidenciaInspectorPage> {
  Usuario? _encargadoSeleccionado;
  List<Usuario> _listaEncargados = [];
  bool _cargandoEncargados = false;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    if (widget.incidencia.estado == EstadoIncidencia.APROBADO) {
      _cargarEncargadosActivos();
    }
  }

  Future<void> _cargarEncargadosActivos() async {
    setState(() => _cargandoEncargados = true);
    try {
      final useCase = ref.read(gestionarIncidenciaUseCaseProvider);
      final encargados = await useCase.obtenerEncargadosActivos();
      setState(() {
        _listaEncargados = encargados;
        _cargandoEncargados = false;
      });
    } catch (_) {
      setState(() => _cargandoEncargados = false);
    }
  }

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

  /// Visor nativo a pantalla completa con zoom HD (InteractiveViewer) para el Inspector
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
              maxScale: 5.0, // Zoom de inspección técnica profunda
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

  // RF-INS-004, RF-INS-006 (OCC)
  Future<void> _aprobarIncidencia() async {
    final inspector = ref.read(authProvider).usuario;
    if (inspector == null) return;

    setState(() => _procesando = true);
    try {
      final useCase = ref.read(gestionarIncidenciaUseCaseProvider);
      await useCase.validarIncidencia(
        inspectorInvocante: inspector,
        incidencia: widget.incidencia,
        aprobada: true,
      );

      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incidencia Aprobada. Ahora es pública en Comunidad.'),
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

  // RF-INS-005: Rechazar con motivo obligatorio
  Future<void> _rechazarIncidencia() async {
    final inspector = ref.read(authProvider).usuario;
    if (inspector == null) return;

    final motivoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final dioConfirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Incidencia'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escriba el motivo técnico obligatorio de rechazo:'),
              const SizedBox(height: 12),
              TextFormField(
                controller: motivoCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText:
                      'Ej. No corresponde a desperfectos de infraestructura.',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El motivo de rechazo es obligatorio.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              minimumSize: const Size(100, 42),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (dioConfirmar == true && mounted) {
      setState(() => _procesando = true);
      try {
        final useCase = ref.read(gestionarIncidenciaUseCaseProvider);
        await useCase.validarIncidencia(
          inspectorInvocante: inspector,
          incidencia: widget.incidencia,
          aprobada: false,
          motivoRechazo: motivoCtrl.text,
        );

        if (!mounted) return;
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incidencia Rechazada.'),
            backgroundColor: AppTheme.errorColor,
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
  }

  // RF-INS-007, RF-INS-009: Asignación multicriterio
  Future<void> _asignarTecnicoEncargado() async {
    final inspector = ref.read(authProvider).usuario;
    if (inspector == null || _encargadoSeleccionado == null) return;

    setState(() => _procesando = true);
    try {
      final useCase = ref.read(gestionarIncidenciaUseCaseProvider);
      await useCase.asignarEncargado(
        inspectorInvocante: inspector,
        incidencia: widget.incidencia,
        encargado: _encargadoSeleccionado!,
      );

      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tarea asignada a ${_encargadoSeleccionado!.nombreCompleto}. Estado: En Proceso.',
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
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // RF-INS-011: Finalizar incidencia
  Future<void> _finalizarIncidencia() async {
    final inspector = ref.read(authProvider).usuario;
    if (inspector == null) return;

    setState(() => _procesando = true);
    try {
      final useCase = ref.read(gestionarIncidenciaUseCaseProvider);
      await useCase.revisarSolucion(
        inspectorInvocante: inspector,
        incidencia: widget.incidencia,
        aprobada: true,
      );

      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incidencia Finalizada y cerrada satisfactoriamente.'),
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

  // RF-INS-012: Devolver tarea con retroalimentación obligatoria
  Future<void> _devolverTarea() async {
    final inspector = ref.read(authProvider).usuario;
    if (inspector == null) return;

    final motivoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final dioConfirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Devolver Tarea al Encargado'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escriba las observaciones o retroalimentación técnica obligatoria:',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motivoCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText:
                      'Ej. La reparación del grifo sigue presentando goteo leve.',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La retroalimentación es obligatoria.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              minimumSize: const Size(100, 42),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Devolver Tarea'),
          ),
        ],
      ),
    );

    if (dioConfirmar == true && mounted) {
      setState(() => _procesando = true);
      try {
        final useCase = ref.read(gestionarIncidenciaUseCaseProvider);
        await useCase.revisarSolucion(
          inspectorInvocante: inspector,
          incidencia: widget.incidencia,
          aprobada: false,
          motivoDevolucion: motivoCtrl.text,
        );

        if (!mounted) return;
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tarea devuelta al Encargado para corrección. Estado: En Proceso.',
            ),
            backgroundColor: Colors.orange,
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
  }

  @override
  Widget build(BuildContext context) {
    final inc = widget.incidencia;
    final estado = inc.estado;

    return Scaffold(
      appBar: AppBar(title: const Text('Auditoría de Incidencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            estado.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        Text(
                          _formatearFecha(inc.fechaCreacion),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Categoría: ${inc.categoria}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                    const Divider(height: 20),
                    Text(
                      'Ciudadano Reportante: ${inc.nombreUsuarioReporta ?? "No especificado"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Galería de Fotografías Iniciales (Con Toque para Ampliar en HD)
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
                  '(Toque para ampliar en HD)',
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
            const SizedBox(height: 20),

            // SECCIÓN A: ACCIONES PARA ESTADO "NUEVO"
            if (estado == EstadoIncidencia.NUEVO) ...[
              const Text(
                'Acciones de Auditoría Inicial (Inspector)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                      onPressed: _procesando ? null : _rechazarIncidencia,
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _procesando ? null : _aprobarIncidencia,
                      child: const Text('Aprobar Reporte'),
                    ),
                  ),
                ],
              ),
            ],

            // SECCIÓN B: ACCIONES PARA ESTADO "APROBADO" (Asignación Multicriterio)
            if (estado == EstadoIncidencia.APROBADO) ...[
              const Text(
                'Asignación Multicriterio de Técnico Encargado',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              if (_cargandoEncargados)
                const Center(child: CircularProgressIndicator())
              else if (_listaEncargados.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No existen Encargados activos disponibles para asignación. Solicite al Administrador el registro o activación de personal técnico.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                DropdownButtonFormField<Usuario>(
                  value: _encargadoSeleccionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Seleccione un Encargado Técnico',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  hint: const Text('Seleccionar profesional'),
                  items: _listaEncargados.map((e) {
                    return DropdownMenuItem<Usuario>(
                      value: e,
                      child: Text(
                        '${e.nombreCompleto} (${e.areaResponsable ?? "General"}) - Tareas activas: ${e.numeroTareasActivas ?? 0}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _encargadoSeleccionado = val);
                  },
                ),
                if (_encargadoSeleccionado != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _encargadoSeleccionado!.nombreCompleto,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Área Responsable: ${_encargadoSeleccionado!.areaResponsable ?? "No asignada"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Especialidades: ${_encargadoSeleccionado!.tipoDeEncargado?.join(", ") ?? "Mantenimiento General"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Tareas activas en ejecución: ${_encargadoSeleccionado!.numeroTareasActivas ?? 0}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: (_encargadoSeleccionado != null && !_procesando)
                      ? _asignarTecnicoEncargado
                      : null,
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: const Text('Asignar Tarea a Encargado'),
                ),
              ],
            ],

            // SECCIÓN C: ACCIONES PARA ESTADO "PARA VALIDAR" (Auditoría de Solución con Zoom HD)
            if (estado == EstadoIncidencia.PARA_VALIDAR) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Evidencia de la Solución (Técnico)',
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
              if (inc.urlsFotosSolucion != null &&
                  inc.urlsFotosSolucion!.isNotEmpty)
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
                Text(
                  'Comentarios del Técnico: ${inc.comentariosSolucion}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade800),
                      ),
                      onPressed: _procesando ? null : _devolverTarea,
                      child: const Text('Devolver Tarea'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _procesando ? null : _finalizarIncidencia,
                      child: const Text('Finalizar Incidencia'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
