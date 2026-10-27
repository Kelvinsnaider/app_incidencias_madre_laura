import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/auth_provider.dart';

/// Vista 8: Crear Nuevo Usuario (Manual Funcional Parte 2 y RF-ADM-019, RF-ADM-020)
class CrearUsuarioAdminPage extends ConsumerStatefulWidget {
  const CrearUsuarioAdminPage({super.key});

  @override
  ConsumerState<CrearUsuarioAdminPage> createState() =>
      _CrearUsuarioAdminPageState();
}

class _CrearUsuarioAdminPageState extends ConsumerState<CrearUsuarioAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();

  final Set<Rol> _rolesSeleccionados = {Rol.CIUDADANO};
  String _areaResponsableSeleccionada = 'Servicios Generales y Mantenimiento';
  final List<String> _especialidadesSeleccionadas = [];

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

  bool get _esEncargadoSeleccionado =>
      _rolesSeleccionados.contains(Rol.ENCARGADO);
  bool get _esInspectorSeleccionado =>
      _rolesSeleccionados.contains(Rol.INSPECTOR);

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _cedulaCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearUsuarioDirecto() async {
    if (!_formKey.currentState!.validate()) return;

    final adminActual = ref.read(authProvider).usuario;
    if (adminActual == null) return;

    if (_rolesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos un rol inicial.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_esEncargadoSeleccionado && _especialidadesSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debe seleccionar al menos una especialidad para el Encargado.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final useCase = ref.read(gestionarUsuariosUseCaseProvider);
      final claveTemporalGenerada = await useCase.crearUsuario(
        adminInvocante: adminActual,
        nombre: _nombreCtrl.text,
        correo: _correoCtrl.text,
        cedula: _cedulaCtrl.text,
        rolesIniciales: _rolesSeleccionados.toList(),
        areaResponsable: _esEncargadoSeleccionado
            ? _areaResponsableSeleccionada
            : null,
        especialidades: _esEncargadoSeleccionado
            ? _especialidadesSeleccionadas
            : null,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Cuenta Creada Exitosamente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se ha registrado el usuario ${_nombreCtrl.text} con estado ACTIVO.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Contraseña temporal generada:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SelectableText(
                      claveTemporalGenerada,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: claveTemporalGenerada),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Contraseña copiada al portapapeles.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nota: El usuario deberá cambiar obligatoriamente esta contraseña al ingresar por primera vez (Vista 1B).',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );

      if (!mounted) return;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nuevo Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos de la Nueva Cuenta',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                  counterText: '',
                ),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Ingrese nombres y apellidos completos'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico institucional',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) =>
                    (v == null || !ValidadoresSistema.validarCorreo(v))
                    ? 'Correo electrónico inválido'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cedulaCtrl,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Número de cédula (Ecuador)',
                  prefixIcon: Icon(Icons.badge_outlined),
                  counterText: '',
                ),
                validator: (v) =>
                    (v == null ||
                        !ValidadoresSistema.validarCedulaEcuatoriana(v))
                    ? 'Cédula de identidad ecuatoriana inválida'
                    : null,
              ),
              const SizedBox(height: 20),

              // Selección multirrol inicial
              const Text(
                'Selección de Rol(es) Inicial(es)',
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
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              if (_esInspectorSeleccionado) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El rol Inspector se creará con permisos globales de inspección sobre todo el establecimiento educativo.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_esEncargadoSeleccionado) ...[
                const SizedBox(height: 16),
                const Text(
                  'Campos Obligatorios de Encargado',
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
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _areaResponsableSeleccionada = v);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Especialidad(es) técnica(s):',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
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
              ElevatedButton.icon(
                onPressed: _crearUsuarioDirecto,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Crear Usuario y Generar Acceso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
