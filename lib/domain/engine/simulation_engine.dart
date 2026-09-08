import '../models/kpi.dart';
import '../models/progress.dart';
import '../models/scenario.dart';

/// Registro de una decision tomada por el estudiante.
class DecisionRecord {
  const DecisionRecord({
    required this.stepId,
    required this.stepTitle,
    required this.optionId,
    required this.optionLabel,
    required this.competencyId,
    required this.quality,
    required this.feedback,
    required this.frameworkRef,
    required this.effects,
    required this.kpisAfter,
  });

  final String stepId;
  final String stepTitle;
  final String optionId;
  final String optionLabel;
  final String competencyId;
  final OptionQuality quality;
  final String feedback;
  final String frameworkRef;
  final Map<String, int> effects;
  final KpiSnapshot kpisAfter;

  double get score => quality.score;
}

/// Estado inmutable de una corrida de simulacion.
class SimulationState {
  const SimulationState({
    required this.scenario,
    required this.stepIndex,
    required this.kpis,
    required this.decisions,
    required this.startedAt,
    this.selectedOptionId,
    this.revealed = false,
    this.finished = false,
    this.hintVisible = false,
  });

  final Scenario scenario;
  final int stepIndex;
  final KpiSnapshot kpis;
  final List<DecisionRecord> decisions;
  final DateTime startedAt;
  final String? selectedOptionId;

  /// true cuando ya se muestra la retroalimentacion del paso actual.
  final bool revealed;
  final bool finished;
  final bool hintVisible;

  SimStep get currentStep => scenario.steps[stepIndex];

  bool get isLastStep => stepIndex >= scenario.steps.length - 1;

  double get progress =>
      scenario.steps.isEmpty ? 0 : (stepIndex + (revealed ? 1 : 0)) / scenario.steps.length;

  DecisionOption? get selectedOption {
    if (selectedOptionId == null) return null;
    return currentStep.optionById(selectedOptionId!);
  }

  SimulationState copyWith({
    int? stepIndex,
    KpiSnapshot? kpis,
    List<DecisionRecord>? decisions,
    String? selectedOptionId,
    bool clearSelection = false,
    bool? revealed,
    bool? finished,
    bool? hintVisible,
  }) {
    return SimulationState(
      scenario: scenario,
      stepIndex: stepIndex ?? this.stepIndex,
      kpis: kpis ?? this.kpis,
      decisions: decisions ?? this.decisions,
      startedAt: startedAt,
      selectedOptionId:
          clearSelection ? null : (selectedOptionId ?? this.selectedOptionId),
      revealed: revealed ?? this.revealed,
      finished: finished ?? this.finished,
      hintVisible: hintVisible ?? this.hintVisible,
    );
  }
}

/// Logica pura de la simulacion. No depende de Flutter ni de almacenamiento,
/// lo que permite probarla con tests unitarios simples.
class SimulationEngine {
  const SimulationEngine();

  SimulationState start(Scenario scenario, {DateTime? now}) {
    return SimulationState(
      scenario: scenario,
      stepIndex: 0,
      kpis: scenario.startingKpis,
      decisions: const <DecisionRecord>[],
      startedAt: now ?? DateTime.now(),
    );
  }

  SimulationState select(SimulationState state, String optionId) {
    if (state.revealed || state.finished) return state;
    return state.copyWith(selectedOptionId: optionId);
  }

  SimulationState toggleHint(SimulationState state) {
    return state.copyWith(hintVisible: !state.hintVisible);
  }

  /// Confirma la decision: aplica efectos sobre los KPI y revela el feedback.
  SimulationState confirm(SimulationState state) {
    if (state.revealed || state.finished) return state;
    final String? optionId = state.selectedOptionId;
    if (optionId == null) return state;

    final SimStep step = state.currentStep;
    final DecisionOption option = step.optionById(optionId);
    final KpiSnapshot updated = state.kpis.apply(option.effects);

    final DecisionRecord record = DecisionRecord(
      stepId: step.id,
      stepTitle: step.title,
      optionId: option.id,
      optionLabel: option.label,
      competencyId: step.competencyId,
      quality: option.quality,
      feedback: option.feedback,
      frameworkRef: step.frameworkRef,
      effects: option.effects,
      kpisAfter: updated,
    );

    return state.copyWith(
      kpis: updated,
      revealed: true,
      hintVisible: false,
      decisions: <DecisionRecord>[...state.decisions, record],
    );
  }

  /// Avanza al siguiente paso o cierra el escenario.
  SimulationState advance(SimulationState state) {
    if (!state.revealed || state.finished) return state;
    if (state.isLastStep) {
      return state.copyWith(finished: true, clearSelection: true);
    }
    return state.copyWith(
      stepIndex: state.stepIndex + 1,
      revealed: false,
      hintVisible: false,
      clearSelection: true,
    );
  }

  /// Nota final del escenario: promedio ponderado de la calidad de cada
  /// decision, ajustado por la salud final del area (hasta +/- 10 puntos).
  ScenarioResult buildResult(SimulationState state, {DateTime? now}) {
    final DateTime end = now ?? DateTime.now();
    final List<DecisionRecord> decisions = state.decisions;

    double decisionScore = 0;
    if (decisions.isNotEmpty) {
      decisionScore = decisions
              .map((DecisionRecord d) => d.score)
              .reduce((double a, double b) => a + b) /
          decisions.length *
          100;
    }

    // El tablero de KPI pesa poco a proposito: la nota mide criterio de
    // gestion, no suerte con los indicadores.
    final double healthAdjustment = (state.kpis.healthIndex - 50) / 5;
    double finalScore = decisionScore + healthAdjustment;
    if (finalScore < 0) finalScore = 0;
    if (finalScore > 100) finalScore = 100;

    return ScenarioResult(
      scenarioId: state.scenario.id,
      moduleId: state.scenario.moduleId,
      scenarioTitle: state.scenario.title,
      scorePercent: double.parse(finalScore.toStringAsFixed(1)),
      competencyScores: competencyBreakdown(decisions),
      finalKpis: state.kpis.toJson(),
      completedAt: end,
      durationSeconds: end.difference(state.startedAt).inSeconds,
      optimalDecisions: decisions
          .where((DecisionRecord d) => d.quality == OptionQuality.optimal)
          .length,
      totalDecisions: decisions.length,
    );
  }

  /// Desempeno por competencia (0-100) usando solo los pasos que la evaluaron.
  Map<String, double> competencyBreakdown(List<DecisionRecord> decisions) {
    final Map<String, List<double>> buckets = <String, List<double>>{};
    for (final DecisionRecord d in decisions) {
      buckets.putIfAbsent(d.competencyId, () => <double>[]).add(d.score * 100);
    }
    final Map<String, double> out = <String, double>{};
    buckets.forEach((String key, List<double> values) {
      out[key] = double.parse(
        (values.reduce((double a, double b) => a + b) / values.length)
            .toStringAsFixed(1),
      );
    });
    return out;
  }

  /// Nivel sugerido tras el diagnostico inicial.
  LearnerLevel levelFromScore(double scorePercent) {
    if (scorePercent >= 80) return LearnerLevel.avanzado;
    if (scorePercent >= 55) return LearnerLevel.intermedio;
    return LearnerLevel.basico;
  }
}
