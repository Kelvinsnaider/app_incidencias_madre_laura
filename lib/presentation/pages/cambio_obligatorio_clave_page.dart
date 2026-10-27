import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../state_management/auth_provider.dart';
import 'perfil_page.dart';

/// Vista 1B: Restablecimiento Obligatorio de Contraseña (Manual Funcional y RF-AUT-009)
class CambioObligatorioClavePage extends ConsumerStatefulWidget {
  const CambioObligatorioClavePage({super.key});

  @override
  ConsumerState<CambioObligatorioClavePage> createState() =>
      _CambioObligatorioClavePageState();
}

class _CambioObligatorioClavePageState
    extends ConsumerState<CambioObligatorioClavePage> {
  final _formKey = GlobalKey<FormState>();
  final _nuevaPassCtrl = TextEditingController();
  final _confirmarPassCtrl = TextEditingController();

  bool _ocultarPass = true;
  bool _esFormularioValido = false;

  void _validarFormulario() {
    final pass = _nuevaPassCtrl.text;
    final confirm = _confirmarPassCtrl.text;
    final esValido =
        ValidadoresSistema.validarPoliticaContrasena(pass) && pass == confirm;

    if (esValido != _esFormularioValido) {
      setState(() => _esFormularioValido = esValido);
    }
  }

  @override
  void initState() {
    super.initState();
    _nuevaPassCtrl.addListener(_validarFormulario);
    _confirmarPassCtrl.addListener(_validarFormulario);
  }

  @override
  void dispose() {
    _nuevaPassCtrl.dispose();
    _confirmarPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _procesarCambioClave() async {
    if (!_formKey.currentState!.validate()) return;

    final exito = await ref
        .read(authProvider.notifier)
        .completarCambioObligatorioContrasena(_nuevaPassCtrl.text);

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente.'),
          backgroundColor: AppTheme.accentColor,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PerfilPage()),
      );
    } else {
      final error =
          ref.read(authProvider).error ??
          'Ocurrió un error al actualizar la contraseña.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoAuth = ref.watch(authProvider);

    // RF-AUT-009: Inhabilita la navegación hacia atrás (Back)
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cambio Obligatorio de Contraseña'),
          automaticallyImplyLeading: false, // Oculta la flecha de regresar
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Por razones de seguridad, al ser una contraseña temporal creada por la administración, debe establecer una nueva contraseña personal para continuar.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nuevaPassCtrl,
                    obscureText: _ocultarPass,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarPass
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _ocultarPass = !_ocultarPass);
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v == null ||
                          !ValidadoresSistema.validarPoliticaContrasena(v)) {
                        return 'Mínimo 8 caracteres (debe incluir letras y números).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmarPassCtrl,
                    obscureText: _ocultarPass,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (v) {
                      if (v != _nuevaPassCtrl.text) {
                        return 'Las contraseñas no coinciden.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: (_esFormularioValido && !estadoAuth.cargando)
                        ? _procesarCambioClave
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
                        : const Text('Guardar y Continuar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
