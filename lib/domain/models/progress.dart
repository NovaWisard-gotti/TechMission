import 'competency.dart';
import 'kpi.dart';

/// Nivel del estudiante, determinado por el diagnostico inicial y el desempeno.
enum LearnerLevel { basico, intermedio, avanzado }

LearnerLevel levelFromString(String? value) {
  switch (value) {
    case 'avanzado':
      return LearnerLevel.avanzado;
    case 'intermedio':
      return LearnerLevel.intermedio;
    default:
      return LearnerLevel.basico;
  }
}

extension LearnerLevelX on LearnerLevel {
  String get id => name;

  String get label {
    switch (this) {
      case LearnerLevel.basico:
        return 'Basico';
      case LearnerLevel.intermedio:
        return 'Intermedio';
      case LearnerLevel.avanzado:
        return 'Avanzado';
    }
  }

  String get advice {
    switch (this) {
      case LearnerLevel.basico:
        return 'Empieza por Fundamentos ITIL y Gestion de incidentes con las pistas activadas.';
      case LearnerLevel.intermedio:
        return 'Puedes saltar directo a Incidentes, Problemas y Cambios; usa la pista solo si te bloqueas.';
      case LearnerLevel.avanzado:
        return 'Ve a los escenarios de Cambios, PMBOK y Producto, y trabaja sin pistas para medir tu criterio real.';
    }
  }
}

/// Resultado de una corrida completa de un escenario.
class ScenarioResult {
  const ScenarioResult({
    required this.scenarioId,
    required this.moduleId,
    required this.scenarioTitle,
    required this.scorePercent,
    required this.competencyScores,
    required this.finalKpis,
    required this.completedAt,
    required this.durationSeconds,
    required this.optimalDecisions,
    required this.totalDecisions,
  });

  final String scenarioId;
  final String moduleId;
  final String scenarioTitle;
  final double scorePercent;
  final Map<String, double> competencyScores;
  final Map<String, int> finalKpis;
  final DateTime completedAt;
  final int durationSeconds;
  final int optimalDecisions;
  final int totalDecisions;

  KpiSnapshot get kpis => KpiSnapshot(finalKpis);

  String get grade {
    if (scorePercent >= 85) return 'Excelente';
    if (scorePercent >= 70) return 'Competente';
    if (scorePercent >= 55) return 'En desarrollo';
    return 'Requiere refuerzo';
  }

  bool get approved => scorePercent >= 70;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'scenarioId': scenarioId,
        'moduleId': moduleId,
        'scenarioTitle': scenarioTitle,
        'scorePercent': scorePercent,
        'competencyScores': competencyScores,
        'finalKpis': finalKpis,
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'optimalDecisions': optimalDecisions,
        'totalDecisions': totalDecisions,
      };

  factory ScenarioResult.fromJson(Map<String, dynamic> json) {
    final Map<String, double> comps = <String, double>{};
    (json['competencyScores'] as Map<String, dynamic>? ?? <String, dynamic>{})
        .forEach((String key, dynamic value) {
      comps[key] = (value as num).toDouble();
    });
    final Map<String, int> kpis = <String, int>{};
    (json['finalKpis'] as Map<String, dynamic>? ?? <String, dynamic>{})
        .forEach((String key, dynamic value) {
      kpis[key] = (value as num).toInt();
    });
    return ScenarioResult(
      scenarioId: json['scenarioId'] as String,
      moduleId: json['moduleId'] as String? ?? '',
      scenarioTitle: json['scenarioTitle'] as String? ?? '',
      scorePercent: (json['scorePercent'] as num).toDouble(),
      competencyScores: comps,
      finalKpis: kpis,
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
              DateTime.now(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      optimalDecisions: (json['optimalDecisions'] as num?)?.toInt() ?? 0,
      totalDecisions: (json['totalDecisions'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Progreso acumulado del estudiante (persistido localmente).
class LearnerProgress {
  const LearnerProgress({
    this.results = const <ScenarioResult>[],
    this.level = LearnerLevel.basico,
    this.diagnosticDone = false,
  });

  final List<ScenarioResult> results;
  final LearnerLevel level;
  final bool diagnosticDone;

  LearnerProgress copyWith({
    List<ScenarioResult>? results,
    LearnerLevel? level,
    bool? diagnosticDone,
  }) {
    return LearnerProgress(
      results: results ?? this.results,
      level: level ?? this.level,
      diagnosticDone: diagnosticDone ?? this.diagnosticDone,
    );
  }

  /// Mejor resultado obtenido en cada escenario.
  Map<String, ScenarioResult> get bestByScenario {
    final Map<String, ScenarioResult> map = <String, ScenarioResult>{};
    for (final ScenarioResult r in results) {
      final ScenarioResult? current = map[r.scenarioId];
      if (current == null || r.scorePercent > current.scorePercent) {
        map[r.scenarioId] = r;
      }
    }
    return map;
  }

  ScenarioResult? bestFor(String scenarioId) => bestByScenario[scenarioId];

  bool isCompleted(String scenarioId) => bestByScenario.containsKey(scenarioId);

  bool isModuleCompleted(String moduleId, List<String> scenarioIds) {
    if (scenarioIds.isEmpty) return false;
    final Map<String, ScenarioResult> best = bestByScenario;
    return scenarioIds.every((String id) => best.containsKey(id));
  }

  /// Promedio por competencia usando el mejor intento de cada escenario.
  Map<String, double> get competencyAverages {
    final Map<String, List<double>> buckets = <String, List<double>>{};
    for (final ScenarioResult r in bestByScenario.values) {
      r.competencyScores.forEach((String key, double value) {
        buckets.putIfAbsent(key, () => <double>[]).add(value);
      });
    }
    final Map<String, double> out = <String, double>{};
    for (final CompetencyDef def in CompetencyCatalog.all) {
      final List<double>? values = buckets[def.id];
      if (values == null || values.isEmpty) continue;
      out[def.id] =
          values.reduce((double a, double b) => a + b) / values.length;
    }
    return out;
  }

  double get overallScore {
    final Iterable<ScenarioResult> best = bestByScenario.values;
    if (best.isEmpty) return 0;
    return best
            .map((ScenarioResult r) => r.scorePercent)
            .reduce((double a, double b) => a + b) /
        best.length;
  }

  /// Competencia con el promedio mas bajo (para recomendar el siguiente paso).
  String? get weakestCompetency {
    final Map<String, double> avg = competencyAverages;
    if (avg.isEmpty) return null;
    String? worst;
    double worstValue = 101;
    avg.forEach((String key, double value) {
      if (value < worstValue) {
        worstValue = value;
        worst = key;
      }
    });
    return worst;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'level': level.id,
        'diagnosticDone': diagnosticDone,
        'results':
            results.map((ScenarioResult r) => r.toJson()).toList(),
      };

  factory LearnerProgress.fromJson(Map<String, dynamic> json) {
    return LearnerProgress(
      level: levelFromString(json['level'] as String?),
      diagnosticDone: json['diagnosticDone'] as bool? ?? false,
      results: (json['results'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) =>
              ScenarioResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
