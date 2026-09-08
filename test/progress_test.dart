import 'package:flutter_test/flutter_test.dart';
import 'package:techmission/domain/models/progress.dart';

ScenarioResult _result(String scenarioId, double score,
    {Map<String, double>? competencies}) {
  return ScenarioResult(
    scenarioId: scenarioId,
    moduleId: 'mod',
    scenarioTitle: 'Caso $scenarioId',
    scorePercent: score,
    competencyScores: competencies ?? <String, double>{'inc': score},
    finalKpis: const <String, int>{'sla': 70},
    completedAt: DateTime(2026, 3, 12),
    durationSeconds: 480,
    optimalDecisions: 3,
    totalDecisions: 4,
  );
}

void main() {
  group('LearnerProgress', () {
    test('conserva el mejor intento de cada escenario', () {
      const LearnerProgress empty = LearnerProgress();
      final LearnerProgress progress = empty.copyWith(
        results: <ScenarioResult>[
          _result('sc_a', 40),
          _result('sc_a', 88),
          _result('sc_b', 71),
        ],
      );

      expect(progress.bestByScenario.length, 2);
      expect(progress.bestFor('sc_a')!.scorePercent, 88);
      expect(progress.isCompleted('sc_a'), isTrue);
      expect(progress.isCompleted('sc_z'), isFalse);
    });

    test('el promedio general usa solo el mejor intento', () {
      final LearnerProgress progress = const LearnerProgress().copyWith(
        results: <ScenarioResult>[
          _result('sc_a', 40),
          _result('sc_a', 80),
          _result('sc_b', 60),
        ],
      );
      expect(progress.overallScore, 70);
    });

    test('identifica la competencia mas debil', () {
      final LearnerProgress progress = const LearnerProgress().copyWith(
        results: <ScenarioResult>[
          _result('sc_a', 90,
              competencies: <String, double>{'inc': 90, 'chg': 40}),
          _result('sc_b', 80,
              competencies: <String, double>{'inc': 70, 'plan': 95}),
        ],
      );

      expect(progress.weakestCompetency, 'chg');
      expect(progress.competencyAverages['inc'], 80);
    });

    test('marca un modulo como completado solo con todos sus casos', () {
      final LearnerProgress progress = const LearnerProgress()
          .copyWith(results: <ScenarioResult>[_result('sc_a', 75)]);

      expect(progress.isModuleCompleted('mod', <String>['sc_a']), isTrue);
      expect(progress.isModuleCompleted('mod', <String>['sc_a', 'sc_b']),
          isFalse);
      expect(progress.isModuleCompleted('mod', <String>[]), isFalse);
    });

    test('sobrevive a la serializacion completa', () {
      final LearnerProgress original = const LearnerProgress(
        level: LearnerLevel.avanzado,
        diagnosticDone: true,
      ).copyWith(results: <ScenarioResult>[_result('sc_a', 82.5)]);

      final LearnerProgress restored =
          LearnerProgress.fromJson(original.toJson());

      expect(restored.level, LearnerLevel.avanzado);
      expect(restored.diagnosticDone, isTrue);
      expect(restored.results.single.scorePercent, 82.5);
      expect(restored.results.single.scenarioTitle, 'Caso sc_a');
    });

    test('un progreso vacio no rompe los calculos', () {
      const LearnerProgress progress = LearnerProgress();
      expect(progress.overallScore, 0);
      expect(progress.weakestCompetency, isNull);
      expect(progress.competencyAverages, isEmpty);
    });
  });
}
