import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/auth_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/admin_dashboard_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/ciudadano_dashboard_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/encargado_dashboard_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/inspector_dashboard_page.dart';

/// Vista 3: Selección de Rol (Manual Funcional Parte 1 y RF-AUT-014, RF-AUT-015)
class SeleccionRolPage extends ConsumerWidget {
  const SeleccionRolPage({super.key});

  IconData _obtenerIconoRol(Rol rol) {
    switch (rol) {
      case Rol.CIUDADANO:
        return Icons.people_alt_rounded;
      case Rol.INSPECTOR:
        return Icons.verified_user_rounded;
      case Rol.ENCARGADO:
        return Icons.engineering_rounded;
      case Rol.ADMINISTRADOR:
        return Icons.admin_panel_settings_rounded;
    }
  }

  String _obtenerDescripcionRol(Rol rol) {
    switch (rol) {
      case Rol.CIUDADANO:
        return 'Reportar novedades de infraestructura y consultar el feed de la comunidad.';
      case Rol.INSPECTOR:
        return 'Auditar reportes, validar soluciones y asignar encargados técnicos.';
      case Rol.ENCARGADO:
        return 'Consultar tareas asignadas, registrar inicio y enviar evidencias de reparación.';
      case Rol.ADMINISTRADOR:
        return 'Gestionar el padrón de usuarios, solicitudes de registro y control de acceso.';
    }
  }

  void _seleccionarRol(
    BuildContext context,
    WidgetRef ref,
    Rol rolElegido,
  ) async {
    // Actualiza y persiste reactivamente el rol activo en Riverpod y almacenamiento local
    await ref.read(authProvider.notifier).seleccionarRolActivo(rolElegido);

    if (!context.mounted) return;

    // Navegación directa al módulo correspondiente (RF-AUT-015)
    switch (rolElegido) {
      case Rol.CIUDADANO:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CiudadanoDashboardPage()),
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
      case Rol.ADMINISTRADOR:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authProvider).usuario;

    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rolesDisponibles = usuario.roles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Perfil de Acceso'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido(a), ${usuario.nombreCompleto}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Su cuenta dispone de múltiples roles autorizados. Seleccione el módulo con el que desea operar:',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: rolesDisponibles.length,
                  itemBuilder: (context, index) {
                    final rol = rolesDisponibles[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _seleccionarRol(context, ref, rol),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                child: Icon(
                                  _obtenerIconoRol(rol),
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Acceder como ${rol.etiquetaVisual}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _obtenerDescripcionRol(rol),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
