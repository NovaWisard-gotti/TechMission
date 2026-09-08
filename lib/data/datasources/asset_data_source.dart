import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Lee el contenido educativo empaquetado con la app.
///
/// El contenido vive en assets y no en un backend: el MVP funciona 100%
/// offline y el contenido puede ser revisado y versionado por un docente
/// en el repositorio.
class AssetDataSource {
  const AssetDataSource();

  static const String modulesPath = 'assets/data/modules.json';
  static const String scenariosDir = 'assets/data/scenarios/';

  Future<Map<String, dynamic>> readJson(String path) async {
    final String raw = await rootBundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> readModules() => readJson(modulesPath);

  Future<Map<String, dynamic>> readScenarioFile(String fileName) =>
      readJson('$scenariosDir$fileName');
}
