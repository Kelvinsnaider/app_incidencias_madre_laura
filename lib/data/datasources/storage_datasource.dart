import 'dart:convert';
import 'dart:io';

class StorageDatasource {
  /// Convierte las imágenes comprimidas a Base64 para guardarlas en Firestore de forma 100% gratuita
  Future<List<String>> subirEvidenciasIncidencia({
    required String idIncidencia,
    required List<File> archivosFotos,
  }) async {
    final List<String> fotosBase64 = [];
    for (final file in archivosFotos) {
      final bytes = await file.readAsBytes();
      final String base64String = base64Encode(bytes);
      fotosBase64.add(base64String);
    }
    return fotosBase64;
  }

  Future<void> eliminarEvidenciasSubidas(List<String> urls) async {}
}
