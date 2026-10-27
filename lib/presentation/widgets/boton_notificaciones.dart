import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/notificaciones_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/notificaciones_page.dart';

/// Componente reutilizable del ícono de campana para las barras superiores (Vista 16 y RF-NOT-006)
class BotonNotificaciones extends ConsumerWidget {
  const BotonNotificaciones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cantidadNoLeidas = ref.watch(contadorNotificacionesNoLeidasProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Centro de Notificaciones',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificacionesPage()),
            );
          },
        ),
        if (cantidadNoLeidas > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                cantidadNoLeidas > 9 ? '9+' : '$cantidadNoLeidas',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
