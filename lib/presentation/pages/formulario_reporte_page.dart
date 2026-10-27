import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_theme.dart';
import '../../domain/entities/catalogos.dart';
import '../state_management/auth_provider.dart';
import '../state_management/incidencia_provider.dart';

/// Vista 11: Formulario de Reporte de Incidencia (Manual Funcional Parte 3 y RNF-PER-003)
class FormularioReportePage extends ConsumerStatefulWidget {
  const FormularioReportePage({super.key});

  @override
  ConsumerState<FormularioReportePage> createState() =>
      _FormularioReportePageState();
}

class _FormularioReportePageState extends ConsumerState<FormularioReportePage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _otraSubcategoriaCtrl = TextEditingController();

  String? _bloqueSeleccionado;
  String? _pisoNivelSeleccionado;
  String? _lugarEspecificoSeleccionado;

  String? _categoriaSeleccionada;
  String? _subcategoriaSeleccionada;

  final List<File> _fotosSeleccionadas = [];
  final ImagePicker _picker = ImagePicker();
  bool _enviando = false;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _otraSubcategoriaCtrl.dispose();
    super.dispose();
  }

  /// RNF-PER-003: Captura optimizada en Alta Definición HD (1280x1280 px a 75% calidad)
  Future<void> _capturarFoto(ImageSource origen) async {
    if (_fotosSeleccionadas.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se permite un máximo de 3 fotografías de evidencia.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final XFile? foto = await _picker.pickImage(
        source: origen,
        maxWidth: 1280, // Resolución HD nítida
        maxHeight: 1280,
        imageQuality: 75, // Máxima nitidez y fidelidad de textura
      );

      if (foto != null) {
        setState(() {
          _fotosSeleccionadas.add(File(foto.path));
        });
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permiso de Cámara / Galería Requerido'),
          content: const Text(
            'Se requiere permiso de acceso a la cámara o galería para adjuntar la evidencia fotográfica. Por favor, habilite el permiso en los Ajustes de su dispositivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  void _eliminarFoto(int index) {
    setState(() {
      _fotosSeleccionadas.removeAt(index);
    });
  }

  Future<void> _guardarIncidencia() async {
    if (!_formKey.currentState!.validate()) return;

    if (_bloqueSeleccionado == null || _lugarEspecificoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe completar la ubicación física de la incidencia.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar la categoría del problema.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_fotosSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debe adjuntar al menos una (1) fotografía de evidencia.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final usuarioActual = ref.read(authProvider).usuario;
    if (usuarioActual == null) return;

    setState(() => _enviando = true);

    try {
      final subcatFinal = _categoriaSeleccionada == 'Otras'
          ? _otraSubcategoriaCtrl.text.trim()
          : (_subcategoriaSeleccionada ?? 'No especificada');

      final ubicacionFinal = <String, String>{
        'bloque_area': _bloqueSeleccionado!,
        if (_pisoNivelSeleccionado != null)
          'piso_nivel': _pisoNivelSeleccionado!,
        'lugar_especifico': _lugarEspecificoSeleccionado!,
      };

      final useCase = ref.read(reportarUseCaseProvider);
      await useCase.reportarIncidencia(
        usuarioInvocante: usuarioActual,
        ubicacion: ubicacionFinal,
        categoria: _categoriaSeleccionada!,
        subcategoria: subcatFinal,
        descripcion: _descripcionCtrl.text,
        fotosEvidencia: _fotosSeleccionadas,
      );

      if (!mounted) return;
      setState(() => _enviando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Incidencia registrada correctamente en Alta Definición.',
          ),
          backgroundColor: AppTheme.accentColor,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiereNivel2 =
        _bloqueSeleccionado != null &&
        CatalogosUbicacion.requierePisoNivel(_bloqueSeleccionado!);

    final subcategoriasDisponibles = _categoriaSeleccionada != null
        ? CatalogosCategorias
                  .subcategoriasPorCategoria[_categoriaSeleccionada] ??
              []
        : <String>[];

    final lugaresDisponibles = _bloqueSeleccionado != null
        ? CatalogosUbicacion.obtenerLugaresEspecificos(
            bloque: _bloqueSeleccionado!,
            pisoNivel: _pisoNivelSeleccionado,
          )
        : <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Incidencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aviso Informativo de Privacidad (RF-CIU-018)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: Colors.amber,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aviso de Privacidad y Protección de Datos: Las incidencias aprobadas serán visibles de forma pública e impersonalizada en la sección Comunidad. En cumplimiento de la normativa de protección de datos de menores de edad, evite tomar fotografías donde aparezcan rostros de personas o escribir nombres propios e información personal en la descripción.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ubicación Jerárquica
              const Text(
                'Ubicación Física del Desperfecto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _bloqueSeleccionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Bloque / Área (Nivel 1)',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                        items: CatalogosUbicacion.bloquesPrincipales
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(b, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _bloqueSeleccionado = val;
                            _pisoNivelSeleccionado = null;
                            _lugarEspecificoSeleccionado = null;
                          });
                        },
                      ),
                      if (requiereNivel2) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _pisoNivelSeleccionado,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Piso / Nivel (Nivel 2)',
                            prefixIcon: Icon(Icons.layers_outlined),
                          ),
                          items:
                              (CatalogosUbicacion
                                          .nivelesPorBloque[_bloqueSeleccionado] ??
                                      [])
                                  .map(
                                    (n) => DropdownMenuItem(
                                      value: n,
                                      child: Text(n),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            setState(() {
                              _pisoNivelSeleccionado = val;
                              _lugarEspecificoSeleccionado = null;
                            });
                          },
                        ),
                      ],
                      if (_bloqueSeleccionado != null &&
                          (!requiereNivel2 ||
                              _pisoNivelSeleccionado != null)) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _lugarEspecificoSeleccionado,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Lugar Específico',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                          items: lugaresDisponibles
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l,
                                  child: Text(
                                    l,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _lugarEspecificoSeleccionado = val;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Categoría y Subcategoría
              const Text(
                'Clasificación del Problema',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _categoriaSeleccionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: CatalogosCategorias.categoriasOficiales
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _categoriaSeleccionada = val;
                            _subcategoriaSeleccionada = null;
                          });
                        },
                      ),
                      if (_categoriaSeleccionada != null &&
                          _categoriaSeleccionada != 'Otras') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _subcategoriaSeleccionada,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Subcategoría del desperfecto',
                            prefixIcon: Icon(Icons.build_outlined),
                          ),
                          items: subcategoriasDisponibles
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _subcategoriaSeleccionada = val;
                            });
                          },
                        ),
                      ],
                      if (_categoriaSeleccionada == 'Otras') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _otraSubcategoriaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Especifique el problema (Obligatorio)',
                            prefixIcon: Icon(Icons.edit_note_outlined),
                          ),
                          validator: (v) {
                            if (_categoriaSeleccionada == 'Otras' &&
                                (v == null || v.trim().isEmpty)) {
                              return 'Especifique la naturaleza del problema.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Descripción
              const Text(
                'Descripción Contextual (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Añada detalles adicionales del desperfecto...',
                ),
              ),

              const SizedBox(height: 16),

              // Evidencia fotográfica en Alta Definición
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fotografía(s) de Evidencia HD (1 a 3)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '${_fotosSeleccionadas.length}/3',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _fotosSeleccionadas.isNotEmpty
                          ? AppTheme.accentColor
                          : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _capturarFoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Cámara HD'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _capturarFoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galería'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_fotosSeleccionadas.isNotEmpty)
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _fotosSeleccionadas.length,
                    itemBuilder: (ctx, idx) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: FileImage(_fotosSeleccionadas[idx]),
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 14,
                            child: GestureDetector(
                              onTap: () => _eliminarFoto(idx),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: const Center(
                    child: Text(
                      'No ha adjuntado ninguna fotografía. Debe incluir al menos una (1) evidencia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _enviando ? null : _guardarIncidencia,
                icon: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _enviando ? 'Guardando en HD...' : 'Guardar Incidencia',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
