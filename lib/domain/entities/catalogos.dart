/// Catálogos Institucionales Oficiales U.E.P. "Madre Laura" (Anexo A.1.1 y A.1.2)
class CatalogosUbicacion {
  /// Retorna si un bloque requiere selección intermedia de Piso/Nivel (Estructura de 3 niveles)
  static bool requierePisoNivel(String bloque) {
    return bloque == 'Bloque D' ||
        bloque == 'Bloque E – Administración y Servicios' ||
        bloque == 'Área Recreativa y Deportiva';
  }

  /// Lista principal de Bloques / Áreas (Nivel 1)
  static const List<String> bloquesPrincipales = [
    'Bloque A – Jardín',
    'Bloque B – Educación Básica',
    'Bloque C – Educación Básica',
    'Bloque D',
    'Bloque E – Administración y Servicios',
    'Bloque F – Capilla',
    'Área Recreativa y Deportiva',
    'Bar / Comedor',
  ];

  /// Mapa de Pisos/Niveles para bloques de 3 niveles (Nivel 2)
  static const Map<String, List<String>> nivelesPorBloque = {
    'Bloque D': ['1.º piso', '2.º piso', '3.º piso', '4.º piso'],
    'Bloque E – Administración y Servicios': ['1.º piso', '2.º piso'],
    'Área Recreativa y Deportiva': ['Nivel inferior', 'Nivel superior'],
  };

  /// Mapa de Lugares Específicos según Bloque y Piso/Nivel (Anexo A.1.1)
  static List<String> obtenerLugaresEspecificos({
    required String bloque,
    String? pisoNivel,
  }) {
    switch (bloque) {
      case 'Bloque A – Jardín':
        return [
          'Jardín A',
          'Jardín B',
          'Jardín C',
          'Baño de niños',
          'Baño de niñas',
          'Área recreativa infantil',
        ];
      case 'Bloque B – Educación Básica':
        return [
          '2.º grado',
          '3.º grado',
          '4.º grado',
          '5.º grado',
          'Baño de hombres',
          'Baño de mujeres',
        ];
      case 'Bloque C – Educación Básica':
        return ['6.º grado', '7.º grado', 'Baño de hombres', 'Baño de mujeres'];
      case 'Bloque F – Capilla':
        return ['Capilla', 'Baño de hombres', 'Baño de mujeres'];
      case 'Bar / Comedor':
        return ['Comedor principal', 'Cocina / Bar', 'Bodega', 'Baños'];

      // Bloques de 3 Niveles
      case 'Bloque D':
        switch (pisoNivel) {
          case '1.º piso':
            return ['3.º Bachillerato', 'Secretaría'];
          case '2.º piso':
            return [
              '1.º Bachillerato',
              '2.º Bachillerato',
              'Rectorado',
              'Baños',
            ];
          case '3.º piso':
            return ['9.º grado', '10.º grado', 'Baños'];
          case '4.º piso':
            return ['8.º grado'];
          default:
            return [];
        }

      case 'Bloque E – Administración y Servicios':
        switch (pisoNivel) {
          case '1.º piso':
            return ['Psicología', 'Enfermería', 'Bodega', 'Lab. de Ciencias'];
          case '2.º piso':
            return [
              'Lab. de Computación',
              'Sala Audiovisual',
              'Sala de Reuniones',
            ];
          default:
            return [];
        }

      case 'Área Recreativa y Deportiva':
        switch (pisoNivel) {
          case 'Nivel inferior':
            return ['Juegos infantiles', 'Cancha de básquet'];
          case 'Nivel superior':
            return ['Cancha de vóley', 'Cancha de fútbol'];
          default:
            return [];
        }

      default:
        return [];
    }
  }
}

class CatalogosCategorias {
  /// Lista oficial de las 9 categorías (Anexo A.1.2)
  static const List<String> categoriasOficiales = [
    'Agua y Saneamiento',
    'Energía y Electricidad',
    'Equipamiento de Aulas',
    'Infraestructura y Acceso',
    'Equipamiento de Enfermería y Emergencias',
    'Mobiliario Exterior y Gestión de Residuos',
    'Áreas Recreativas y Deportivas',
    'Telecomunicaciones y Equipos Audiovisuales',
    'Otras',
  ];

  /// Mapa de Subcategorías estandarizadas por Categoría
  static const Map<String, List<String>> subcategoriasPorCategoria = {
    'Agua y Saneamiento': [
      'fuga de agua',
      'inodoro/urinario dañado',
      'lavamanos dañado',
      'falta de suministro',
      'bebedero fuera de servicio',
      'otro',
    ],
    'Energía y Electricidad': [
      'luminaria quemada',
      'interruptor/tomacorriente dañado',
      'fallo eléctrico de área',
      'cableado expuesto',
      'timbre/campana no funciona',
      'otro',
    ],
    'Equipamiento de Aulas': [
      'silla/pupitre roto',
      'pizarra dañada',
      'escritorio del docente dañado',
      'ventana/persiana rota',
      'puerta/cerradura dañada',
      'otro',
    ],
    'Infraestructura y Acceso': [
      'pared/techo con grietas o humedad',
      'piso roto o resbaladizo',
      'gradas/pasamanos en mal estado',
      'puerta de acceso dañada',
      'rampa obstruida o dañada',
      'otro',
    ],
    'Equipamiento de Enfermería y Emergencias': [
      'camilla en mal estado',
      'falta de insumos básicos',
      'extintor obstruido o vencido',
      'señalización de emergencia dañada',
      'lámpara de emergencia no funciona',
      'otro',
    ],
    'Mobiliario Exterior y Gestión de Residuos': [
      'banca exterior rota',
      'basurero lleno o dañado',
      'acumulación de basura',
      'mesa exterior dañada',
      'jardinera descuidada',
      'otro',
    ],
    'Áreas Recreativas y Deportivas': [
      'juego infantil roto o inseguro',
      'arco/canasta dañada',
      'superficie de cancha en mal estado',
      'graderíos dañados',
      'falta de equipamiento deportivo',
      'otro',
    ],
    'Telecomunicaciones y Equipos Audiovisuales': [
      'proyector/pizarra digital no funciona',
      'computadora/equipo de laboratorio dañado',
      'problema de red/Wi-Fi',
      'parlante defectuoso',
      'teléfono/intercomunicador no funciona',
      'otro',
    ],
    'Otras': [],
  };
}
