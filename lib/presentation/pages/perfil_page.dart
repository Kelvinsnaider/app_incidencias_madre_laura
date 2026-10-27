import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/auth_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/login_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/seleccion_rol_page.dart';

/// Vista 4: Mi Perfil (Manual Funcional Parte 1 y RF-AUT-011, RF-AUT-014, RF-AUT-016, RF-AUT-017)
class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  void _mostrarDialogoCambiarPassword(BuildContext context, WidgetRef ref) {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();
    final confirmarCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: actualCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nuevaCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                  ),
                  validator: (v) {
                    if (v == null ||
                        !ValidadoresSistema.validarPoliticaContrasena(v)) {
                      return 'Mín. 8 caracteres (letras y números)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmarCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                  ),
                  validator: (v) => v != nuevaCtrl.text ? 'No coinciden' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(110, 42)),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final exito = await ref
                  .read(authProvider.notifier)
                  .cambiarContrasena(
                    passwordActual: actualCtrl.text,
                    passwordNueva: nuevaCtrl.text,
                  );
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (exito) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contraseña actualizada correctamente.'),
                    backgroundColor: AppTheme.accentColor,
                  ),
                );
              } else {
                final err =
                    ref.read(authProvider).error ??
                    'Error al actualizar contraseña.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;

    if (usuario == null) {
      return const LoginPage();
    }

    final tieneMultiplesRoles = usuario.roles.length > 1;

    // Lectura reactiva del rol seleccionado actualmente
    final rolActivo =
        authState.rolActivo ??
        (usuario.roles.isNotEmpty ? usuario.roles.first : Rol.CIUDADANO);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(Icons.person, size: 46, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      usuario.nombreCompleto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.correoElectronico,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const Divider(height: 28),
                    ListTile(
                      leading: const Icon(
                        Icons.badge_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      title: const Text('Cédula de Identidad'),
                      subtitle: Text(usuario.numeroCedula),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.verified_user_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      title: const Text('Roles asignados'),
                      subtitle: Text(
                        usuario.roles.map((r) => r.etiquetaVisual).join(', '),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.work_outline,
                        color: AppTheme.accentColor,
                      ),
                      title: const Text('Rol actualmente activo'),
                      subtitle: Text(
                        rolActivo.etiquetaVisual, // Reactivo 100%
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // RF-AUT-014: "Cambiar de rol" habilitado para cuentas multirrol
            if (tieneMultiplesRoles) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SeleccionRolPage()),
                  );
                },
                icon: const Icon(Icons.switch_account_rounded),
                label: const Text('Cambiar de rol'),
              ),
              const SizedBox(height: 12),
            ],

            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoCambiarPassword(context, ref),
              icon: const Icon(Icons.key_outlined),
              label: const Text('Cambiar contraseña'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).cerrarSesion();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text(
                'Cerrar sesión',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
