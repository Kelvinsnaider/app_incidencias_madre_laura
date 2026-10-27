import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/incidencia.dart';
import 'package:app_incidencias_madre_laura/domain/entities/notificacion.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/auth_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/incidencia_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/notificaciones_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/detalle_incidencia_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/detalle_incidencia_inspector_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/detalle_tarea_encargado_page.dart';

/// Vista 16: Centro de Notificaciones con Deep Link (Manual Funcional Parte 6 y RF-NOT-006)
class NotificacionesPage extends ConsumerWidget {
  const NotificacionesPage({super.key});

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes $hora:$min';
  }

  /// RF-NOT-006: Comportamiento de Navegación Directa (Deep Link)
  Future<void> _ejecutarDeepLink({
    required BuildContext context,
    required WidgetRef ref,
    required NotificacionSistema notificacion,
  }) async {
    final usuario = ref.read(authProvider).usuario;
    if (usuario == null) return;

    // Marca la alerta como leída
    await ref
        .read(notificacionesDatasourceProvider)
        .marcarNotificacionLeida(usuario.uid, notificacion.id);

    // Si la notificación no tiene incidenciaId asociada, solo se marca leída
    if (notificacion.incidenciaId.isEmpty) return;

    // Obtiene la incidencia completa desde Firestore
    final repo = ref.read(incidenciaRepositoryProvider);
    final incidencia = await repo.obtenerDetalleIncidencia(
      notificacion.incidenciaId,
    );

    if (!context.mounted) return;

    if (incidencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El reporte asociado a esta alerta ya no se encuentra disponible.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Enrutamiento Deep Link condicional según el rol activo
    final rolActivo = usuario.roles.isNotEmpty
        ? usuario.roles.first
        : Rol.CIUDADANO;

    if (rolActivo == Rol.INSPECTOR) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DetalleIncidenciaInspectorPage(incidencia: incidencia),
        ),
      );
    } else if (rolActivo == Rol.ENCARGADO) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleTareaEncargadoPage(incidencia: incidencia),
        ),
      );
    } else {
      // Rol Ciudadano
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleIncidenciaPage(
            incidencia: incidencia,
            esVistaPublicaComunidad: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificacionesAsync = ref.watch(notificacionesUsuarioStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: notificacionesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (lista) {
          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No tiene notificaciones recibidas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Aquí aparecerán las alertas sobre los cambios de estado de sus reportes o asignaciones.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notif = lista[index];
              return Card(
                elevation: notif.leida ? 1 : 2.5,
                color: notif.leida ? Colors.white : Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: notif.leida
                        ? Colors.grey.shade200
                        : AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: notif.leida
                        ? Colors.grey.shade300
                        : AppTheme.primaryColor,
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: notif.leida ? Colors.grey.shade600 : Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.titulo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notif.leida
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: notif.leida
                                ? Colors.black87
                                : AppTheme.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatearFecha(notif.fecha),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notif.mensaje,
                      style: TextStyle(
                        fontSize: 12,
                        color: notif.leida ? Colors.black54 : Colors.black87,
                      ),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.black38,
                  ),
                  onTap: () => _ejecutarDeepLink(
                    context: context,
                    ref: ref,
                    notificacion: notif,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
