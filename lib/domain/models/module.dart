/// Modulo educativo del simulador (ITIL, Incidentes, Cambios, Scrum, etc.).
class LearningModule {
  const LearningModule({
    required this.id,
    required this.title,
    required this.area,
    required this.summary,
    required this.framework,
    required this.competencies,
    required this.scenarioFile,
    required this.order,
    this.requiresModuleId,
    this.isDiagnostic = false,
  });

  final String id;
  final String title;
  final String area;
  final String summary;
  final String framework;
  final List<String> competencies;
  final String scenarioFile;
  final int order;

  /// Modulo que debe completarse antes de habilitar este (ruta guiada).
  final String? requiresModuleId;
  final bool isDiagnostic;

  factory LearningModule.fromJson(Map<String, dynamic> json) {
    return LearningModule(
      id: json['id'] as String,
      title: json['title'] as String,
      area: json['area'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      framework: json['framework'] as String? ?? '',
      competencies: (json['competencies'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e as String)
          .toList(),
      scenarioFile: json['scenarioFile'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      requiresModuleId: json['requiresModuleId'] as String?,
      isDiagnostic: json['isDiagnostic'] as bool? ?? false,
    );
  }
}
