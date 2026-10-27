import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/incidencia.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/incidencia_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/widgets/boton_notificaciones.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/detalle_incidencia_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/formulario_reporte_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/perfil_page.dart';

/// Vista 9: Pantalla Principal del Ciudadano (Manual Funcional Parte 3 y Vista 16)
class CiudadanoDashboardPage extends ConsumerStatefulWidget {
  const CiudadanoDashboardPage({super.key});

  @override
  ConsumerState<CiudadanoDashboardPage> createState() =>
      _CiudadanoDashboardPageState();
}

class _CiudadanoDashboardPageState extends ConsumerState<CiudadanoDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroComunidad = 'Todas';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  Widget _buildBadgeEstado(EstadoIncidencia estado, {bool esPublico = false}) {
    Color bg = Colors.blue.shade100;
    Color fg = Colors.blue.shade900;
    String texto = estado.name;

    switch (estado) {
      case EstadoIncidencia.NUEVO:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        texto = 'NUEVO';
        break;
      case EstadoIncidencia.APROBADO:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        texto = esPublico ? 'EN PROCESO' : 'APROBADO';
        break;
      case EstadoIncidencia.EN_PROCESO:
        bg = Colors.indigo.shade100;
        fg = Colors.indigo.shade900;
        texto = 'EN PROCESO';
        break;
      case EstadoIncidencia.PARA_VALIDAR:
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade900;
        texto = esPublico ? 'EN PROCESO' : 'PARA VALIDAR';
        break;
      case EstadoIncidencia.FINALIZADO:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        texto = 'FINALIZADO';
        break;
      case EstadoIncidencia.RECHAZADO:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        texto = 'RECHAZADO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildTarjetaIncidencia(Incidencia inc, {bool esPublica = false}) {
    final tieneFoto = inc.urlsFotosEvidencia.isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleIncidenciaPage(
                incidencia: inc,
                esVistaPublicaComunidad: esPublica,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
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
                        _buildBadgeEstado(inc.estado, esPublico: esPublica),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inc.subcategoria,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 4),
                    Text(
                      _formatearFecha(inc.fechaCreacion),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final misIncidenciasAsync = ref.watch(misIncidenciasStreamProvider);
    final comunidadAsync = ref.watch(comunidadIncidenciasStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidencias U.E. "Madre Laura"'),
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
            Tab(text: 'Mis Reportes'),
            Tab(text: 'Comunidad'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          misIncidenciasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (misLista) {
              if (misLista.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No existen incidencias registradas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Presione el botón "Nueva Incidencia" para reportar un desperfecto en la institución.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: misLista.length,
                itemBuilder: (ctx, idx) =>
                    _buildTarjetaIncidencia(misLista[idx]),
              );
            },
          ),
          comunidadAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (comunidadLista) {
              final filtradas = comunidadLista.where((inc) {
                if (_filtroComunidad == 'En Proceso') {
                  return inc.estado == EstadoIncidencia.APROBADO ||
                      inc.estado == EstadoIncidencia.EN_PROCESO ||
                      inc.estado == EstadoIncidencia.PARA_VALIDAR;
                } else if (_filtroComunidad == 'Finalizadas') {
                  return inc.estado == EstadoIncidencia.FINALIZADO;
                }
                return true;
              }).toList();

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: Colors.white,
                    child: Row(
                      children: ['Todas', 'En Proceso', 'Finalizadas'].map((f) {
                        final esSeleccionado = _filtroComunidad == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              f,
                              style: TextStyle(
                                fontSize: 12,
                                color: esSeleccionado
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            selected: esSeleccionado,
                            selectedColor: AppTheme.primaryColor,
                            onSelected: (val) {
                              if (val) setState(() => _filtroComunidad = f);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: filtradas.isEmpty
                        ? Center(
                            child: Text(
                              'No hay incidencias públicas en "$_filtroComunidad".',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: filtradas.length,
                            itemBuilder: (ctx, idx) => _buildTarjetaIncidencia(
                              filtradas[idx],
                              esPublica: true,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormularioReportePage()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nueva Incidencia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
