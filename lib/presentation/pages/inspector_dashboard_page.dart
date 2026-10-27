import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/incidencia.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/incidencia_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/widgets/boton_notificaciones.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/detalle_incidencia_inspector_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/perfil_page.dart';

/// Vista 12: Panel del Inspector (Manual Funcional Parte 4 y Vista 16)
class InspectorDashboardPage extends ConsumerStatefulWidget {
  const InspectorDashboardPage({super.key});

  @override
  ConsumerState<InspectorDashboardPage> createState() =>
      _InspectorDashboardPageState();
}

class _InspectorDashboardPageState extends ConsumerState<InspectorDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Widget _buildImagenMiniaura(String fotoData) {
    if (fotoData.startsWith('http')) {
      return Image.network(fotoData, fit: BoxFit.cover);
    }
    try {
      final bytes = base64Decode(fotoData.replaceAll(RegExp(r'\s+'), ''));
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return const Icon(Icons.broken_image, color: Colors.black38);
    }
  }

  Widget _buildListaIncidencias(List<Incidencia> lista, String mensajeVacio) {
    if (lista.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                mensajeVacio,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: lista.length,
      itemBuilder: (ctx, idx) {
        final inc = lista[idx];
        final tieneFoto = inc.urlsFotosEvidencia.isNotEmpty;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: tieneFoto
                  ? _buildImagenMiniaura(inc.urlsFotosEvidencia.first)
                  : const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.black38,
                    ),
            ),
            title: Text(
              inc.categoria,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inc.subcategoria,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  inc.ubicacionFormateada,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Text(
                  'Fecha: ${_formatearFecha(inc.fechaCreacion)}',
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DetalleIncidenciaInspectorPage(incidencia: inc),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTabConContador(String titulo, int cantidad) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titulo),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cantidad > 0 ? Colors.amber : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$cantidad',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cantidad > 0 ? Colors.black87 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nuevasAsync = ref.watch(incidenciasNuevasStreamProvider);
    final aprobadasAsync = ref.watch(incidenciasAprobadasStreamProvider);
    final enProcesoAsync = ref.watch(incidenciasEnProcesoStreamProvider);
    final paraValidarAsync = ref.watch(incidenciasParaValidarStreamProvider);
    final finalizadasAsync = ref.watch(incidenciasFinalizadasStreamProvider);

    final cntNuevas = nuevasAsync.value?.length ?? 0;
    final cntAprobadas = aprobadasAsync.value?.length ?? 0;
    final cntEnProceso = enProcesoAsync.value?.length ?? 0;
    final cntParaValidar = paraValidarAsync.value?.length ?? 0;
    final cntFinalizadas = finalizadasAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Incidencias'),
        actions: [
          // Vista 16 / RF-NOT-006: Ícono interactivo de campana
          const BotonNotificaciones(),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Mi Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: [
            _buildTabConContador('Nuevas', cntNuevas),
            _buildTabConContador('Aprobadas', cntAprobadas),
            _buildTabConContador('En Proceso', cntEnProceso),
            _buildTabConContador('Para Validar', cntParaValidar),
            _buildTabConContador('Finalizadas', cntFinalizadas),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          nuevasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => _buildListaIncidencias(
              list,
              'No existen incidencias nuevas pendientes de evaluación.',
            ),
          ),
          aprobadasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => _buildListaIncidencias(
              list,
              'No existen incidencias aprobadas pendientes de asignación.',
            ),
          ),
          enProcesoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => _buildListaIncidencias(
              list,
              'No existen incidencias en proceso de atención.',
            ),
          ),
          paraValidarAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => _buildListaIncidencias(
              list,
              'No existen incidencias con solución pendiente de validación.',
            ),
          ),
          finalizadasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => _buildListaIncidencias(
              list,
              'No existen incidencias en el histórico de finalizadas.',
            ),
          ),
        ],
      ),
    );
  }
}
