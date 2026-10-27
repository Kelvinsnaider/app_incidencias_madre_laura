import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/domain/entities/usuario.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/auth_provider.dart';

/// Vista 7: Detalle del Usuario (Manual Funcional Parte 2 y RF-ADM-004 a 018)
class DetalleUsuarioAdminPage extends ConsumerStatefulWidget {
  final Usuario usuarioObjetivo;

  const DetalleUsuarioAdminPage({super.key, required this.usuarioObjetivo});

  @override
  ConsumerState<DetalleUsuarioAdminPage> createState() =>
      _DetalleUsuarioAdminPageState();
}

class _DetalleUsuarioAdminPageState
    extends ConsumerState<DetalleUsuarioAdminPage> {
  late Set<Rol> _rolesSeleccionados;
  String? _areaResponsableSeleccionada;
  late List<String> _especialidadesSeleccionadas;

  final List<String> _catalogoAreas = [
    'Servicios Generales y Mantenimiento',
    'TICs/Sistemas',
    'Infraestructura y Obras',
    'Limpieza y Servicios Básicos',
  ];

  final List<String> _catalogoEspecialidades = [
    'Electricista',
    'Plomero',
    'Cerrajero',
    'Mantenimiento General',
    'Técnico de Cómputo/Redes',
    'Pintor/Albañil',
  ];

  @override
  void initState() {
    super.initState();
    _rolesSeleccionados = Set.from(widget.usuarioObjetivo.roles);
    _areaResponsableSeleccionada =
        widget.usuarioObjetivo.areaResponsable ?? _catalogoAreas.first;
    _especialidadesSeleccionadas = List.from(
      widget.usuarioObjetivo.tipoDeEncargado ?? [],
    );
  }

  bool get _esEncargadoSeleccionado =>
      _rolesSeleccionados.contains(Rol.ENCARGADO);
  bool get _esInspectorSeleccionado =>
      _rolesSeleccionados.contains(Rol.INSPECTOR);

  Future<void> _aprobarSolicitud() async {
    final adminActual = ref.read(authProvider).usuario;
    if (adminActual == null) return;

    if (_rolesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos un rol para el usuario.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final useCase = ref.read(gestionarUsuariosUseCaseProvider);
      await useCase.aprobarUsuario(
        adminInvocante: adminActual,
        usuarioObjetivo: widget.usuarioObjetivo,
        roles: _rolesSeleccionados.toList(),
        areaResponsable: _esEncargadoSeleccionado
            ? _areaResponsableSeleccionada
            : null,
        especialidades: _esEncargadoSeleccionado
            ? _especialidadesSeleccionadas
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de registro aprobada exitosamente.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _rechazarSolicitud() async {
    final adminActual = ref.read(authProvider).usuario;
    if (adminActual == null) return;

    final motivoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final dioConfirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Solicitud de Registro'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escriba la justificación o motivo institucional para rechazar este registro:',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motivoCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText:
                      'Ej. No se encuentra matriculado en la institución.',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El motivo es obligatorio'
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
      try {
        final useCase = ref.read(gestionarUsuariosUseCaseProvider);
        await useCase.rechazarUsuario(
          adminInvocante: adminActual,
          usuarioObjetivo: widget.usuarioObjetivo,
          motivo: motivoCtrl.text,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de registro rechazada.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _guardarModificacionRoles() async {
    final adminActual = ref.read(authProvider).usuario;
    if (adminActual == null) return;

    try {
      final useCase = ref.read(gestionarUsuariosUseCaseProvider);
      await useCase.modificarRolesUsuario(
        adminInvocante: adminActual,
        usuarioObjetivo: widget.usuarioObjetivo,
        nuevosRoles: _rolesSeleccionados.toList(),
        areaResponsable: _esEncargadoSeleccionado
            ? _areaResponsableSeleccionada
            : null,
        especialidades: _esEncargadoSeleccionado
            ? _especialidadesSeleccionadas
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Roles y datos de usuario actualizados.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _desactivarCuenta() async {
    final adminActual = ref.read(authProvider).usuario;
    if (adminActual == null) return;

    final dioConfirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar Cuenta de Usuario'),
        content: Text(
          '¿Está seguro de desactivar la cuenta de ${widget.usuarioObjetivo.nombreCompleto}? El usuario no podrá ingresar al sistema.',
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (dioConfirmar == true && mounted) {
      try {
        final useCase = ref.read(gestionarUsuariosUseCaseProvider);
        await useCase.desactivarUsuario(
          adminInvocante: adminActual,
          usuarioObjetivo: widget.usuarioObjetivo,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta deshabilitada exitosamente.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _reactivarCuenta() async {
    final adminActual = ref.read(authProvider).usuario;
    if (adminActual == null) return;

    if (_rolesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Asigne al menos un rol activo para reactivar la cuenta.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final useCase = ref.read(gestionarUsuariosUseCaseProvider);
      await useCase.reactivarUsuario(
        adminInvocante: adminActual,
        usuarioObjetivo: widget.usuarioObjetivo,
        rolesActivos: _rolesSeleccionados.toList(),
        areaResponsable: _esEncargadoSeleccionado
            ? _areaResponsableSeleccionada
            : null,
        especialidades: _esEncargadoSeleccionado
            ? _especialidadesSeleccionadas
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta de usuario habilitada de nuevo.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuarioObjetivo;
    final esPendiente = u.estadoCuenta == EstadoCuenta.PENDIENTE;
    final esActivo = u.estadoCuenta == EstadoCuenta.ACTIVO;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Usuario')),
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
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.nombreCompleto,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                u.correoElectronico,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cédula: ${u.numeroCedula}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: esActivo
                                ? Colors.green.shade100
                                : (esPendiente
                                      ? Colors.amber.shade100
                                      : Colors.red.shade100),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            u.estadoCuenta.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: esActivo
                                  ? Colors.green.shade800
                                  : (esPendiente
                                        ? Colors.amber.shade900
                                        : Colors.red.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Roles de Acceso en la Plataforma',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: Rol.values.map((rol) {
                  final marcado = _rolesSeleccionados.contains(rol);
                  return CheckboxListTile(
                    title: Text(
                      rol.etiquetaVisual,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: marcado,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _rolesSeleccionados.add(rol);
                        } else {
                          if (_rolesSeleccionados.length > 1) {
                            _rolesSeleccionados.remove(rol);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La cuenta debe conservar al menos un rol.',
                                ),
                              ),
                            );
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            if (_esInspectorSeleccionado) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nota sobre el rol Inspector: Otorga alcance operativo global e institucional sobre la totalidad de bloques y dependencias de la U.E.P. "Madre Laura", sin requerir asignación de áreas específicas.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_esEncargadoSeleccionado) ...[
              const SizedBox(height: 18),
              const Text(
                'Datos de Adscripción del Encargado (Obligatorios)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // RNF-USA-006: Previene desbordamiento con isExpanded y TextOverflow.ellipsis
                      DropdownButtonFormField<String>(
                        value: _areaResponsableSeleccionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Área Responsable',
                          prefixIcon: Icon(Icons.apartment),
                        ),
                        items: _catalogoAreas.map((a) {
                          return DropdownMenuItem(
                            value: a,
                            child: Text(a, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _areaResponsableSeleccionada = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Especialidad(es) Técnica(s):',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _catalogoEspecialidades.map((esp) {
                          final selec = _especialidadesSeleccionadas.contains(
                            esp,
                          );
                          return FilterChip(
                            label: Text(
                              esp,
                              style: TextStyle(
                                fontSize: 12,
                                color: selec ? Colors.white : Colors.black87,
                              ),
                            ),
                            selected: selec,
                            selectedColor: AppTheme.accentColor,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _especialidadesSeleccionadas.add(esp);
                                } else {
                                  _especialidadesSeleccionadas.remove(esp);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (esPendiente) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                      onPressed: _rechazarSolicitud,
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _aprobarSolicitud,
                      child: const Text('Aprobar Registro'),
                    ),
                  ),
                ],
              ),
            ] else if (esActivo) ...[
              ElevatedButton.icon(
                onPressed: _guardarModificacionRoles,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar Cambios de Roles'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                ),
                onPressed: _desactivarCuenta,
                icon: const Icon(Icons.block_outlined),
                label: const Text('Desactivar Cuenta'),
              ),
            ] else ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
                onPressed: _reactivarCuenta,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Reactivar / Habilitar Cuenta'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
