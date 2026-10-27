import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/domain/entities/usuario.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/auth_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/admin_dashboard_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/cambio_obligatorio_clave_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/ciudadano_dashboard_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/encargado_dashboard_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/inspector_dashboard_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/perfil_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/registro_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/seleccion_rol_page.dart';

void _navegarSegunRolYEstado(BuildContext context, Usuario usuario) {
  // RF-AUT-009 / Vista 1B: Intercepción bloqueante de clave temporal
  if (usuario.indicadorCambioObligatorio) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CambioObligatorioClavePage()),
    );
    return;
  }

  // RF-AUT-014 / Vista 3: Si posee múltiples roles, presenta la Selección de Rol
  if (usuario.roles.length > 1) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SeleccionRolPage()),
    );
    return;
  }

  // Si posee un solo rol, ingresa directamente a su módulo correspondiente
  final unicoRol = usuario.roles.isNotEmpty
      ? usuario.roles.first
      : Rol.CIUDADANO;

  switch (unicoRol) {
    case Rol.ADMINISTRADOR:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
      );
      break;
    case Rol.INSPECTOR:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InspectorDashboardPage()),
      );
      break;
    case Rol.ENCARGADO:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EncargadoDashboardPage()),
      );
      break;
    case Rol.CIUDADANO:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CiudadanoDashboardPage()),
      );
      break;
  }
}

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final usuario = await ref
          .read(authProvider.notifier)
          .verificarSesionInicial();
      if (!mounted) return;
      if (usuario != null) {
        _navegarSegunRolYEstado(context, usuario);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 72,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'U.E.P. "MADRE LAURA"',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestión Colaborativa de Incidencias',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 36),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Vista 1: Inicio de Sesión (Manual Funcional Parte 1)
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _ocultarPassword = true;
  bool _camposCompletos = false;

  @override
  void initState() {
    super.initState();
    _correoController.addListener(_validarCampos);
    _passwordController.addListener(_validarCampos);
  }

  void _validarCampos() {
    final valido =
        _correoController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
    if (valido != _camposCompletos) {
      setState(() => _camposCompletos = valido);
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ejecutarLogin() async {
    final correo = _correoController.text.trim();
    if (!ValidadoresSistema.validarCorreo(correo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un formato de correo electrónico válido.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final usuario = await ref
        .read(authProvider.notifier)
        .iniciarSesion(correo, _passwordController.text);

    if (!mounted) return;
    if (usuario != null) {
      _navegarSegunRolYEstado(context, usuario);
    } else {
      final error =
          ref.read(authProvider).error ??
          'El correo electrónico o la contraseña no son válidos.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _mostrarDialogoRecuperacion() {
    final resetCorreoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingrese su correo electrónico institucional para recibir un enlace de restablecimiento.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetCorreoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 42)),
            onPressed: () async {
              final email = resetCorreoCtrl.text.trim();
              if (!ValidadoresSistema.validarCorreo(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingrese un correo electrónico válido.'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).recuperarContrasena(email);
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Solicitud Procesada'),
                  content: const Text(
                    'Si el correo electrónico se encuentra registrado, recibirá un enlace para restablecer su contraseña.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Aceptar'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoAuth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unidad Educativa "Madre Laura"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sistema de Gestión de Incidencias Escolares',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _ocultarPassword = !_ocultarPassword);
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _mostrarDialogoRecuperacion,
                    child: const Text('¿Olvidó su contraseña?'),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: (_camposCompletos && !estadoAuth.cargando)
                      ? _ejecutarLogin
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
                      : const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistroPage()),
                    );
                  },
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
