import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_incidencias_madre_laura/core/app_theme.dart';
import 'package:app_incidencias_madre_laura/domain/entities/rol.dart';
import 'package:app_incidencias_madre_laura/domain/entities/usuario.dart';
import 'package:app_incidencias_madre_laura/presentation/state_management/auth_provider.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/crear_usuario_admin_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/detalle_usuario_admin_page.dart';
import 'package:app_incidencias_madre_laura/presentation/pages/perfil_page.dart';

/// Vistas 5 y 6: Panel Principal del Administrador (Manual Funcional Parte 2)
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _filtroBusqueda = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _coincideFiltro(Usuario u) {
    if (_filtroBusqueda.isEmpty) return true;
    final nombre = u.nombreCompleto.toLowerCase();
    final correo = u.correoElectronico.toLowerCase();
    final cedula = u.numeroCedula.toLowerCase();
    return nombre.contains(_filtroBusqueda) ||
        correo.contains(_filtroBusqueda) ||
        cedula.contains(_filtroBusqueda);
  }

  Widget _buildListaTarjetasUsuarios({
    required List<Usuario> usuarios,
    required String mensajeVacio,
    required bool esPendientes,
  }) {
    final filtrados = usuarios.where(_coincideFiltro).toList();

    if (filtrados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _filtroBusqueda.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                _filtroBusqueda.isNotEmpty
                    ? 'No se encontraron resultados para "$_filtroBusqueda"'
                    : mensajeVacio,
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
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final u = filtrados[index];
        final esActivo = u.estadoCuenta == EstadoCuenta.ACTIVO;
        final esRechazado = u.estadoCuenta == EstadoCuenta.RECHAZADO;

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: CircleAvatar(
              backgroundColor: esActivo
                  ? Colors.green.shade100
                  : (esPendientes
                        ? Colors.amber.shade100
                        : Colors.red.shade100),
              child: Icon(
                Icons.person_rounded,
                color: esActivo
                    ? Colors.green.shade800
                    : (esPendientes
                          ? Colors.amber.shade900
                          : Colors.red.shade800),
              ),
            ),
            title: Text(
              u.nombreCompleto,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(u.correoElectronico, style: const TextStyle(fontSize: 13)),
                Text(
                  'Cédula: ${u.numeroCedula}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                if (esActivo && u.roles.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: u.roles.map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.etiquetaVisual,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else if (esRechazado)
                  Text(
                    'RECHAZADO ${u.motivoRechazo != null ? "- ${u.motivoRechazo}" : ""}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Estado: ${u.estadoCuenta.name}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalleUsuarioAdminPage(usuarioObjetivo: u),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final padronAsync = ref.watch(padronUsuariosStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Comunidad'),
        actions: [
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
            Tab(text: 'Pendientes'),
            Tab(text: 'Activos'),
            Tab(text: 'Inactivos'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo o cédula...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _filtroBusqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          Expanded(
            child: padronAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error al cargar la comunidad: $err')),
              data: (listaUsuarios) {
                final pendientes =
                    listaUsuarios
                        .where((u) => u.estadoCuenta == EstadoCuenta.PENDIENTE)
                        .toList()
                      ..sort(
                        (a, b) => (b.fechaRegistro ?? DateTime.now()).compareTo(
                          a.fechaRegistro ?? DateTime.now(),
                        ),
                      );

                final activos =
                    listaUsuarios
                        .where((u) => u.estadoCuenta == EstadoCuenta.ACTIVO)
                        .toList()
                      ..sort(
                        (a, b) => a.nombreCompleto.toLowerCase().compareTo(
                          b.nombreCompleto.toLowerCase(),
                        ),
                      );

                final inactivos =
                    listaUsuarios
                        .where(
                          (u) =>
                              u.estadoCuenta == EstadoCuenta.INACTIVO ||
                              u.estadoCuenta == EstadoCuenta.RECHAZADO,
                        )
                        .toList()
                      ..sort(
                        (a, b) => a.nombreCompleto.toLowerCase().compareTo(
                          b.nombreCompleto.toLowerCase(),
                        ),
                      );

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListaTarjetasUsuarios(
                      usuarios: pendientes,
                      mensajeVacio:
                          'No existen solicitudes de registro pendientes.',
                      esPendientes: true,
                    ),
                    _buildListaTarjetasUsuarios(
                      usuarios: activos,
                      mensajeVacio: 'No existen usuarios activos registrados.',
                      esPendientes: false,
                    ),
                    _buildListaTarjetasUsuarios(
                      usuarios: inactivos,
                      mensajeVacio:
                          'No existen usuarios inactivos o rechazados.',
                      esPendientes: false,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearUsuarioAdminPage()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Crear Usuario',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
