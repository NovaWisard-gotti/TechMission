import 'kpi.dart';

/// Calidad pedagogica de una opcion de decision.
enum OptionQuality { optimal, acceptable, poor }

OptionQuality _qualityFromString(String? value) {
  switch (value) {
    case 'optimal':
      return OptionQuality.optimal;
    case 'acceptable':
      return OptionQuality.acceptable;
    default:
      return OptionQuality.poor;
  }
}

extension OptionQualityX on OptionQuality {
  String get label {
    switch (this) {
      case OptionQuality.optimal:
        return 'Decision correcta';
      case OptionQuality.acceptable:
        return 'Decision aceptable';
      case OptionQuality.poor:
        return 'Decision cuestionable';
    }
  }

  /// Peso de la decision en la nota del escenario (0.0 - 1.0).
  double get score {
    switch (this) {
      case OptionQuality.optimal:
        return 1.0;
      case OptionQuality.acceptable:
        return 0.6;
      case OptionQuality.poor:
        return 0.15;
    }
  }
}

/// Ticket / registro de trabajo mostrado al estudiante en un paso.
class Ticket {
  const Ticket({
    required this.code,
    required this.type,
    required this.title,
    required this.reportedBy,
    required this.service,
    required this.impact,
    required this.urgency,
    this.detail = '',
  });

  final String code;
  final String type;
  final String title;
  final String reportedBy;
  final String service;
  final String impact;
  final String urgency;
  final String detail;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      code: json['code'] as String? ?? 'TKT-000',
      type: json['type'] as String? ?? 'Incidente',
      title: json['title'] as String? ?? '',
      reportedBy: json['reportedBy'] as String? ?? '',
      service: json['service'] as String? ?? '',
      impact: json['impact'] as String? ?? '',
      urgency: json['urgency'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}

/// Una alternativa de decision dentro de un paso.
class DecisionOption {
  const DecisionOption({
    required this.id,
    required this.label,
    required this.quality,
    required this.feedback,
    required this.effects,
    this.consequence = '',
  });

  final String id;
  final String label;
  final OptionQuality quality;

  /// Explicacion pedagogica de por que la decision es correcta o no.
  final String feedback;

  /// Que ocurre en la empresa simulada tras la decision.
  final String consequence;

  /// Impacto sobre los KPI del area.
  final Map<String, int> effects;

  double get score => quality.score;

  factory DecisionOption.fromJson(Map<String, dynamic> json) {
    final Map<String, int> effects = <String, int>{};
    (json['effects'] as Map<String, dynamic>? ?? <String, dynamic>{})
        .forEach((String key, dynamic value) {
      effects[key] = (value as num).toInt();
    });
    return DecisionOption(
      id: json['id'] as String,
      label: json['label'] as String,
      quality: _qualityFromString(json['quality'] as String?),
      feedback: json['feedback'] as String? ?? '',
      consequence: json['consequence'] as String? ?? '',
      effects: effects,
    );
  }
}

/// Un paso de decision dentro del escenario.
class SimStep {
  const SimStep({
    required this.id,
    required this.title,
    required this.situation,
    required this.question,
    required this.competencyId,
    required this.options,
    this.ticket,
    this.hint = '',
    this.frameworkRef = '',
  });

  final String id;
  final String title;
  final String situation;
  final String question;
  final String competencyId;
  final List<DecisionOption> options;
  final Ticket? ticket;

  /// Pista que entrega el asistente sin revelar la respuesta.
  final String hint;

  /// Referencia teorica (practica ITIL, evento Scrum, area de PMBOK).
  final String frameworkRef;

  DecisionOption optionById(String id) =>
      options.firstWhere((DecisionOption o) => o.id == id);

  factory SimStep.fromJson(Map<String, dynamic> json) {
    return SimStep(
      id: json['id'] as String,
      title: json['title'] as String,
      situation: json['situation'] as String? ?? '',
      question: json['question'] as String? ?? '',
      competencyId: json['competencyId'] as String,
      hint: json['hint'] as String? ?? '',
      frameworkRef: json['frameworkRef'] as String? ?? '',
      ticket: json['ticket'] == null
          ? null
          : Ticket.fromJson(json['ticket'] as Map<String, dynamic>),
      options: (json['options'] as List<dynamic>)
          .map((dynamic e) =>
              DecisionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Caso empresarial completo.
class Scenario {
  const Scenario({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.company,
    required this.role,
    required this.briefing,
    required this.difficulty,
    required this.objectives,
    required this.steps,
    required this.takeaways,
    this.initialKpis = const <String, int>{},
    this.estimatedMinutes = 8,
  });

  final String id;
  final String moduleId;
  final String title;
  final String company;
  final String role;
  final String briefing;
  final String difficulty;
  final List<String> objectives;
  final List<SimStep> steps;
  final List<String> takeaways;
  final Map<String, int> initialKpis;
  final int estimatedMinutes;

  KpiSnapshot get startingKpis => KpiSnapshot.initial(initialKpis);

  factory Scenario.fromJson(Map<String, dynamic> json) {
    final Map<String, int> initial = <String, int>{};
    (json['initialKpis'] as Map<String, dynamic>? ?? <String, dynamic>{})
        .forEach((String key, dynamic value) {
      initial[key] = (value as num).toInt();
    });
    return Scenario(
      id: json['id'] as String,
      moduleId: json['moduleId'] as String,
      title: json['title'] as String,
      company: json['company'] as String? ?? '',
      role: json['role'] as String? ?? '',
      briefing: json['briefing'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'basico',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 8,
      objectives: (json['objectives'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e as String)
          .toList(),
      takeaways: (json['takeaways'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e as String)
          .toList(),
      initialKpis: initial,
      steps: (json['steps'] as List<dynamic>)
          .map((dynamic e) => SimStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
