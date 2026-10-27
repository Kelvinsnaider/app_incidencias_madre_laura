import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/incidencias_repository_impl.dart';
import '../../domain/entities/incidencia.dart';
import '../../domain/entities/rol.dart';
import '../../domain/repositories/i_incidencia_repository.dart';
import '../../domain/usecases/gestionar_incidencia_usecase.dart';
import '../../domain/usecases/reportar_usecase.dart';
import '../../domain/usecases/resolver_incidencia_usecase.dart';
import 'auth_provider.dart';

final incidenciaRepositoryProvider = Provider<IIncidenciaRepository>((ref) {
  return IncidenciasRepositoryImpl();
});

final reportarUseCaseProvider = Provider<CasoDeUsoReportar>((ref) {
  final repo = ref.watch(incidenciaRepositoryProvider);
  return CasoDeUsoReportar(repo);
});

final gestionarIncidenciaUseCaseProvider =
    Provider<CasoDeUsoGestionarIncidencia>((ref) {
      final repo = ref.watch(incidenciaRepositoryProvider);
      return CasoDeUsoGestionarIncidencia(repo);
    });

final resolverIncidenciaUseCaseProvider = Provider<CasoDeUsoResolverIncidencia>(
  (ref) {
    final repo = ref.watch(incidenciaRepositoryProvider);
    return CasoDeUsoResolverIncidencia(repo);
  },
);

// --- StreamProviders Módulo Ciudadano (Sprint 3) ---

final misIncidenciasStreamProvider = StreamProvider<List<Incidencia>>((ref) {
  final useCase = ref.watch(reportarUseCaseProvider);
  final usuario = ref.watch(authProvider).usuario;
  if (usuario == null) return Stream.value([]);
  return useCase.consultarMisIncidencias(usuario);
});

final comunidadIncidenciasStreamProvider = StreamProvider<List<Incidencia>>((
  ref,
) {
  final useCase = ref.watch(reportarUseCaseProvider);
  return useCase.consultarIncidenciasComunidad();
});

// --- StreamProviders Módulo Inspector (Sprint 4: 5 Pestañas) ---

final incidenciasNuevasStreamProvider = StreamProvider<List<Incidencia>>((ref) {
  final useCase = ref.watch(gestionarIncidenciaUseCaseProvider);
  return useCase.escucharIncidenciasPorEstado(
    EstadoIncidencia.NUEVO.toStorageString(),
  );
});

final incidenciasAprobadasStreamProvider = StreamProvider<List<Incidencia>>((
  ref,
) {
  final useCase = ref.watch(gestionarIncidenciaUseCaseProvider);
  return useCase.escucharIncidenciasPorEstado(
    EstadoIncidencia.APROBADO.toStorageString(),
  );
});

final incidenciasEnProcesoStreamProvider = StreamProvider<List<Incidencia>>((
  ref,
) {
  final useCase = ref.watch(gestionarIncidenciaUseCaseProvider);
  return useCase.escucharIncidenciasPorEstado(
    EstadoIncidencia.EN_PROCESO.toStorageString(),
  );
});

final incidenciasParaValidarStreamProvider = StreamProvider<List<Incidencia>>((
  ref,
) {
  final useCase = ref.watch(gestionarIncidenciaUseCaseProvider);
  return useCase.escucharIncidenciasPorEstado(
    EstadoIncidencia.PARA_VALIDAR.toStorageString(),
  );
});

final incidenciasFinalizadasStreamProvider = StreamProvider<List<Incidencia>>((
  ref,
) {
  final useCase = ref.watch(gestionarIncidenciaUseCaseProvider);
  return useCase.escucharIncidenciasPorEstado(
    EstadoIncidencia.FINALIZADO.toStorageString(),
  );
});

// --- StreamProviders Módulo Encargado (Sprint 4: 3 Secciones) ---

final tareasActivasEncargadoStreamProvider = StreamProvider<List<Incidencia>>((
  ref,
) {
  final useCase = ref.watch(resolverIncidenciaUseCaseProvider);
  final usuario = ref.watch(authProvider).usuario;
  if (usuario == null) return Stream.value([]);
  return useCase.escucharTareasPersonal(
    encargadoInvocante: usuario,
    tipoSeccion: 'ACTIVAS',
  );
});

final tareasDevueltasEncargadoStreamProvider = StreamProvider<List<Incidencia>>(
  (ref) {
    final useCase = ref.watch(resolverIncidenciaUseCaseProvider);
    final usuario = ref.watch(authProvider).usuario;
    if (usuario == null) return Stream.value([]);
    return useCase.escucharTareasPersonal(
      encargadoInvocante: usuario,
      tipoSeccion: 'DEVUELTAS',
    );
  },
);

final tareasEnviadasEncargadoStreamProvider = StreamProvider<List<Incidencia>>((
  ref,
) {
  final useCase = ref.watch(resolverIncidenciaUseCaseProvider);
  final usuario = ref.watch(authProvider).usuario;
  if (usuario == null) return Stream.value([]);
  return useCase.escucharTareasPersonal(
    encargadoInvocante: usuario,
    tipoSeccion: 'ENVIADAS',
  );
});
