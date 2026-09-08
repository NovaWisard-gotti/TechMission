import '../../domain/models/module.dart';
import '../../domain/models/scenario.dart';
import '../datasources/asset_data_source.dart';

/// Catalogo completo de contenido educativo cargado en memoria.
class ContentCatalog {
  const ContentCatalog({required this.modules, required this.scenarios});

  final List<LearningModule> modules;
  final List<Scenario> scenarios;

  List<Scenario> scenariosOf(String moduleId) =>
      scenarios.where((Scenario s) => s.moduleId == moduleId).toList();

  List<String> scenarioIdsOf(String moduleId) =>
      scenariosOf(moduleId).map((Scenario s) => s.id).toList();

  Scenario? scenarioById(String id) {
    for (final Scenario s in scenarios) {
      if (s.id == id) return s;
    }
    return null;
  }

  LearningModule? moduleById(String id) {
    for (final LearningModule m in modules) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Modulos de aprendizaje sin contar el diagnostico inicial.
  List<LearningModule> get learningModules =>
      modules.where((LearningModule m) => !m.isDiagnostic).toList();

  LearningModule? get diagnosticModule {
    for (final LearningModule m in modules) {
      if (m.isDiagnostic) return m;
    }
    return null;
  }
}

class ScenarioRepository {
  ScenarioRepository({AssetDataSource? source})
      : _source = source ?? const AssetDataSource();

  final AssetDataSource _source;
  ContentCatalog? _cache;

  Future<ContentCatalog> loadCatalog() async {
    final ContentCatalog? cached = _cache;
    if (cached != null) return cached;

    final Map<String, dynamic> modulesJson = await _source.readModules();
    final List<LearningModule> modules =
        (modulesJson['modules'] as List<dynamic>)
            .map((dynamic e) =>
                LearningModule.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((LearningModule a, LearningModule b) =>
              a.order.compareTo(b.order));

    final List<Scenario> scenarios = <Scenario>[];
    for (final LearningModule module in modules) {
      final Map<String, dynamic> file =
          await _source.readScenarioFile(module.scenarioFile);
      final List<dynamic> list = file['scenarios'] as List<dynamic>;
      for (final dynamic item in list) {
        scenarios.add(Scenario.fromJson(item as Map<String, dynamic>));
      }
    }

    final ContentCatalog catalog =
        ContentCatalog(modules: modules, scenarios: scenarios);
    _cache = catalog;
    return catalog;
  }

  void clearCache() => _cache = null;
}
