import 'package:flutter_test/flutter_test.dart';
import 'package:techmission/domain/engine/simulation_engine.dart';
import 'package:techmission/domain/models/kpi.dart';
import 'package:techmission/domain/models/progress.dart';
import 'package:techmission/domain/models/scenario.dart';

Scenario _testScenario() {
  return Scenario.fromJson(<String, dynamic>{
    'id': 'sc_test',
    'moduleId': 'test',
    'title': 'Escenario de prueba',
    'company': 'Empresa X',
    'role': 'Analista',
    'briefing': 'briefing',
    'difficulty': 'basico',
    'objectives': <String>['obj'],
    'takeaways': <String>['take'],
    'initialKpis': <String, int>{'sla': 50, 'risk': 50},
    'steps': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 's1',
        'title': 'Paso 1',
        'situation': 'situacion',
        'question': 'pregunta',
        'competencyId': 'inc',
        'frameworkRef': 'ITIL 4',
        'hint': 'pista',
        'options': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'a',
            'label': 'buena',
            'quality': 'optimal',
            'feedback': 'f',
            'consequence': 'c',
            'effects': <String, int>{'sla': 10, 'risk': -10},
          },
          <String, dynamic>{
            'id': 'b',
            'label': 'mala',
            'quality': 'poor',
            'feedback': 'f',
            'consequence': 'c',
            'effects': <String, int>{'sla': -10},
          },
        ],
      },
      <String, dynamic>{
        'id': 's2',
        'title': 'Paso 2',
        'situation': 'situacion',
        'question': 'pregunta',
        'competencyId': 'chg',
        'options': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'a',
            'label': 'buena',
            'quality': 'optimal',
            'feedback': 'f',
            'consequence': 'c',
            'effects': <String, int>{'satisfaction': 5},
          },
          <String, dynamic>{
            'id': 'b',
            'label': 'regular',
            'quality': 'acceptable',
            'feedback': 'f',
            'consequence': 'c',
            'effects': <String, int>{'satisfaction': -5},
          },
        ],
      },
    ],
  });
}

void main() {
  group('KpiSnapshot', () {
    test('usa los valores iniciales del catalogo y aplica overrides', () {
      final KpiSnapshot snapshot =
          KpiSnapshot.initial(<String, int>{'sla': 40});
      expect(snapshot[KpiCatalog.sla], 40);
      expect(snapshot[KpiCatalog.budget],
          KpiCatalog.byId(KpiCatalog.budget).initialValue);
    });

    test('limita los valores al rango 0-100', () {
      final KpiSnapshot snapshot = KpiSnapshot.initial(<String, int>{'sla': 95})
          .apply(<String, int>{'sla': 40, 'risk': -999});
      expect(snapshot[KpiCatalog.sla], 100);
      expect(snapshot[KpiCatalog.risk], 0);
    });

    test('ignora claves de KPI desconocidas', () {
      final KpiSnapshot snapshot =
          KpiSnapshot.initial().apply(<String, int>{'inexistente': 50});
      expect(snapshot.values.containsKey('inexistente'), isFalse);
    });

    test('el indice de salud invierte los KPI donde menos es mejor', () {
      final KpiSnapshot good = KpiSnapshot.initial(<String, int>{
        'sla': 100,
        'satisfaction': 100,
        'budget': 100,
        'morale': 100,
        'risk': 0,
      });
      expect(good.healthIndex, 100);
    });
  });

  group('SimulationEngine', () {
    const SimulationEngine engine = SimulationEngine();

    test('inicia con los KPI del escenario y en el primer paso', () {
      final SimulationState state = engine.start(_testScenario());
      expect(state.stepIndex, 0);
      expect(state.kpis[KpiCatalog.sla], 50);
      expect(state.finished, isFalse);
      expect(state.decisions, isEmpty);
    });

    test('confirmar aplica los efectos y revela la retroalimentacion', () {
      SimulationState state = engine.start(_testScenario());
      state = engine.select(state, 'a');
      state = engine.confirm(state);

      expect(state.revealed, isTrue);
      expect(state.decisions.length, 1);
      expect(state.kpis[KpiCatalog.sla], 60);
      expect(state.kpis[KpiCatalog.risk], 40);
    });

    test('no permite confirmar sin haber seleccionado una opcion', () {
      final SimulationState state = engine.confirm(engine.start(_testScenario()));
      expect(state.revealed, isFalse);
      expect(state.decisions, isEmpty);
    });

    test('no permite cambiar la opcion despues de revelar el feedback', () {
      SimulationState state = engine.start(_testScenario());
      state = engine.select(state, 'a');
      state = engine.confirm(state);
      state = engine.select(state, 'b');
      expect(state.selectedOptionId, 'a');
    });

    test('avanza al siguiente paso y termina en el ultimo', () {
      SimulationState state = engine.start(_testScenario());
      state = engine.confirm(engine.select(state, 'a'));
      state = engine.advance(state);
      expect(state.stepIndex, 1);
      expect(state.revealed, isFalse);
      expect(state.selectedOptionId, isNull);

      state = engine.confirm(engine.select(state, 'a'));
      state = engine.advance(state);
      expect(state.finished, isTrue);
    });

    test('dos decisiones optimas dan una nota alta y todas las competencias al maximo', () {
      SimulationState state = engine.start(_testScenario());
      state = engine.advance(engine.confirm(engine.select(state, 'a')));
      state = engine.advance(engine.confirm(engine.select(state, 'a')));

      final ScenarioResult result = engine.buildResult(state);
      expect(result.scorePercent, greaterThanOrEqualTo(95));
      expect(result.optimalDecisions, 2);
      expect(result.totalDecisions, 2);
      expect(result.competencyScores['inc'], 100);
      expect(result.competencyScores['chg'], 100);
      expect(result.grade, 'Excelente');
      expect(result.approved, isTrue);
    });

    test('decisiones deficientes producen una nota reprobatoria', () {
      SimulationState state = engine.start(_testScenario());
      state = engine.advance(engine.confirm(engine.select(state, 'b')));
      state = engine.advance(engine.confirm(engine.select(state, 'b')));

      final ScenarioResult result = engine.buildResult(state);
      expect(result.scorePercent, lessThan(55));
      expect(result.grade, 'Requiere refuerzo');
      expect(result.approved, isFalse);
    });

    test('la nota nunca sale del rango 0-100', () {
      SimulationState state = engine.start(_testScenario());
      state = engine.advance(engine.confirm(engine.select(state, 'a')));
      state = engine.advance(engine.confirm(engine.select(state, 'b')));
      final ScenarioResult result = engine.buildResult(state);
      expect(result.scorePercent, inInclusiveRange(0, 100));
    });

    test('el nivel sugerido depende de la nota del diagnostico', () {
      expect(engine.levelFromScore(90), LearnerLevel.avanzado);
      expect(engine.levelFromScore(60), LearnerLevel.intermedio);
      expect(engine.levelFromScore(30), LearnerLevel.basico);
    });
  });
}
