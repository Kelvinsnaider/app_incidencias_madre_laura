import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../domain/entities/rol.dart';
import '../state_management/auth_provider.dart';
import 'perfil_page.dart';

/// Vista 2: Registro de usuario (Manual Funcional Parte 1 y RF-AUT-001 a 006)
class RegistroPage extends ConsumerStatefulWidget {
  const RegistroPage({super.key});

  @override
  ConsumerState<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends ConsumerState<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _aceptaTerminos = false;
  bool _ocultarPass = true;
  bool _formularioValido = false;

  void _actualizarEstadoBoton() {
    final valido = _nombreCtrl.text.trim().length >= 5 &&
        ValidadoresSistema.validarCorreo(_correoCtrl.text) &&
        ValidadoresSistema.validarCedulaEcuatoriana(_cedulaCtrl.text) &&
        ValidadoresSistema.validarPoliticaContrasena(_passCtrl.text) &&
        _passCtrl.text == _confirmPassCtrl.text &&
        _aceptaTerminos;

    if (valido != _formularioValido) {
      setState(() => _formularioValido = valido);
    }
  }

  @override
  void initState() {
    super.initState();
    _nombreCtrl.addListener(_actualizarEstadoBoton);
    _correoCtrl.addListener(_actualizarEstadoBoton);
    _cedulaCtrl.addListener(_actualizarEstadoBoton);
    _passCtrl.addListener(_actualizarEstadoBoton);
    _confirmPassCtrl.addListener(_actualizarEstadoBoton);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _cedulaCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate() || !_aceptaTerminos) return;

    final nuevoUsuario =
        await ref.read(authProvider.notifier).registrarUsuario(
              nombreCompleto: _nombreCtrl.text,
              correo: _correoCtrl.text,
              cedula: _cedulaCtrl.text,
              password: _passCtrl.text,
            );

    if (!mounted) return;

    if (nuevoUsuario == null) {
      final error =
          ref.read(authProvider).error ?? 'Error al registrar la cuenta.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (nuevoUsuario.estadoCuenta == EstadoCuenta.ACTIVO) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Registro Validado Automáticamente'),
          content: const Text(
            'Sus datos coinciden con los registros institucionales de la U.E.P. "Madre Laura". Su cuenta ha sido activada con el rol Ciudadano.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ingresar al Sistema'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PerfilPage()),
        (route) => false,
      );
    } else {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Solicitud en Revisión'),
          content: const Text(
            'Su cuenta ha sido registrada con estado PENDIENTE. Un Administrador verificará su solicitud antes de habilitar el acceso.',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoAuth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete sus datos institucionales',
                  style: TextStyle(
                    fontSize: 18,
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
                  validator: (val) {
                    if (val == null || val.trim().length < 5) {
                      return 'Ingrese sus nombres y apellidos completos.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val == null || !ValidadoresSistema.validarCorreo(val)) {
                      return 'Ingrese un correo electrónico válido.';
                    }
                    return null;
                  },
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
                  validator: (val) {
                    if (val == null ||
                        !ValidadoresSistema.validarCedulaEcuatoriana(val)) {
                      return 'Número de cédula ecuatoriana inválido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _ocultarPass,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarPass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _ocultarPass = !_ocultarPass);
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null ||
                        !ValidadoresSistema.validarPoliticaContrasena(val)) {
                      return 'Mínimo 8 caracteres, incluyendo letras y números.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _ocultarPass,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (val) {
                    if (val != _passCtrl.text) {
                      return 'Las contraseñas no coinciden.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // RF-AUT-005 y Sección 1.6.3 de la Tesis: Consentimiento informado y menores de edad
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _aceptaTerminos,
                    onChanged: (v) {
                      setState(() => _aceptaTerminos = v ?? false);
                      _actualizarEstadoBoton();
                    },
                    title: const Text(
                      'Acepto los términos, condiciones y política de privacidad institucional.',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Nota para estudiantes menores de edad: La creación de esta cuenta debe ser supervisada y autorizada por su representante legal.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_formularioValido && !estadoAuth.cargando)
                      ? _registrar
                      : null,
                  child: estadoAuth.cargando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Registrarse'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}