import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/notificaciones_datasource.dart';
import '../../domain/entities/notificacion.dart';
import 'auth_provider.dart';

final notificacionesDatasourceProvider = Provider<NotificacionesDatasource>((
  ref,
) {
  return NotificacionesDatasource();
});

final notificacionesUsuarioStreamProvider =
    StreamProvider<List<NotificacionSistema>>((ref) {
      final ds = ref.watch(notificacionesDatasourceProvider);
      final usuario = ref.watch(authProvider).usuario;
      if (usuario == null) return Stream.value([]);
      return ds.escucharNotificacionesUsuario(usuario.uid);
    });

final contadorNotificacionesNoLeidasProvider = Provider<int>((ref) {
  final notifAsync = ref.watch(notificacionesUsuarioStreamProvider);
  return notifAsync.maybeWhen(
    data: (lista) => lista.where((n) => !n.leida).length,
    orElse: () => 0,
  );
});
