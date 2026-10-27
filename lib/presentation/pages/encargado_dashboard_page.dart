import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/incidencia.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/incidencia_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/widgets/boton_notificaciones.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/detalle_tarea_encargado_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/perfil_page.dart';

/// Vista 14: Panel del Encargado - Mis Tareas (Manual Funcional Parte 5 y Vista 16)
class EncargadoDashboardPage extends ConsumerStatefulWidget {
  const EncargadoDashboardPage({super.key});

  @override
  ConsumerState<EncargadoDashboardPage> createState() =>
      _EncargadoDashboardPageState();
}

class _EncargadoDashboardPageState extends ConsumerState<EncargadoDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  Widget _buildBadgeEstado(Incidencia inc) {
    if (inc.estado == EstadoIncidencia.PARA_VALIDAR) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.purple.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'En Revisión',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade900,
          ),
        ),
      );
    } else if (inc.estado == EstadoIncidencia.FINALIZADO) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Finalizada',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'En Proceso',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      ),
    );
  }

  Widget _buildListaTareas(
    List<Incidencia> tareas,
    String mensajeVacio, {
    bool esDevueltas = false,
  }) {
    if (tareas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.build_circle_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
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
      itemCount: tareas.length,
      itemBuilder: (ctx, idx) {
        final inc = tareas[idx];
        final tieneFoto = inc.urlsFotosEvidencia.isNotEmpty;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalleTareaEncargadoPage(incidencia: inc),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    inc.categoria,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _buildBadgeEstado(inc),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              inc.subcategoria,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              inc.ubicacionFormateada,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Resaltado de observaciones en tareas devueltas (RF-ENC-008)
                  if (esDevueltas &&
                      inc.motivoRechazoDevolucion != null &&
                      inc.motivoRechazoDevolucion!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.assignment_return_outlined,
                                size: 16,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Observación del Inspector:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inc.motivoRechazoDevolucion!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activasAsync = ref.watch(tareasActivasEncargadoStreamProvider);
    final devueltasAsync = ref.watch(tareasDevueltasEncargadoStreamProvider);
    final enviadasAsync = ref.watch(tareasEnviadasEncargadoStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
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
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Activas'),
            Tab(text: 'Devueltas'),
            Tab(text: 'Enviadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          activasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => _buildListaTareas(
              list,
              'No tiene tareas activas asignadas pendientes de ejecución.',
            ),
          ),
          devueltasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => _buildListaTareas(
              list,
              'No tiene tareas devueltas por observaciones del Inspector.',
              esDevueltas: true,
            ),
          ),
          enviadasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => _buildListaTareas(
              list,
              'No existen trabajos enviados en su historial.',
            ),
          ),
        ],
      ),
    );
  }
}
