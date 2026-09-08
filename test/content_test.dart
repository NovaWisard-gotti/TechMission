import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:it_management_simulator/domain/models/competency.dart';
import 'package:it_management_simulator/domain/models/kpi.dart';
import 'package:it_management_simulator/domain/models/module.dart';
import 'package:it_management_simulator/domain/models/scenario.dart';

/// Estos tests son el control de calidad del contenido educativo.
///
/// Cada vez que un docente agrega un caso nuevo, esta prueba verifica que el
/// archivo sea valido, que cada paso tenga exactamente una decision correcta y
/// que no se hayan inventado competencias o KPI fuera del catalogo.
void main() {
  final File modulesFile = File('assets/data/modules.json');

  List<LearningModule> readModules() {
    final Map<String, dynamic> json =
        jsonDecode(modulesFile.readAsStringSync()) as Map<String, dynamic>;
    return (json['modules'] as List<dynamic>)
        .map((dynamic e) => LearningModule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Scenario> readScenarios(LearningModule module) {
    final File file = File('assets/data/scenarios/${module.scenarioFile}');
    final Map<String, dynamic> json =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return (json['scenarios'] as List<dynamic>)
        .map((dynamic e) => Scenario.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  test('el catalogo de modulos existe y define un diagnostico', () {
    expect(modulesFile.existsSync(), isTrue);
    final List<LearningModule> modules = readModules();
    expect(modules.length, greaterThanOrEqualTo(7));
    expect(modules.where((LearningModule m) => m.isDiagnostic).length, 1);
  });

  test('todos los archivos de escenarios existen y son validos', () {
    for (final LearningModule module in readModules()) {
      final File file = File('assets/data/scenarios/${module.scenarioFile}');
      expect(file.existsSync(), isTrue,
          reason: 'Falta el archivo ${module.scenarioFile}');
      expect(readScenarios(module), isNotEmpty,
          reason: 'El modulo ${module.id} no tiene escenarios');
    }
  });

  test('cada escenario cumple las reglas de contenido del proyecto', () {
    final Set<String> scenarioIds = <String>{};
    final Set<String> competencyIds =
        CompetencyCatalog.all.map((CompetencyDef c) => c.id).toSet();
    final Set<String> kpiIds = KpiCatalog.all.map((KpiDef k) => k.id).toSet();

    for (final LearningModule module in readModules()) {
      for (final Scenario scenario in readScenarios(module)) {
        expect(scenarioIds.add(scenario.id), isTrue,
            reason: 'Id de escenario duplicado: ${scenario.id}');
        expect(scenario.moduleId, module.id);
        expect(scenario.steps.length, greaterThanOrEqualTo(3),
            reason: '${scenario.id} deberia tener al menos 3 decisiones');
        expect(scenario.briefing, isNotEmpty);
        expect(scenario.takeaways, isNotEmpty,
            reason: '${scenario.id} no tiene cierre pedagogico');

        final Set<String> stepIds = <String>{};
        for (final SimStep step in scenario.steps) {
          expect(stepIds.add(step.id), isTrue,
              reason: 'Paso duplicado en ${scenario.id}: ${step.id}');
          expect(competencyIds.contains(step.competencyId), isTrue,
              reason: 'Competencia desconocida en ${scenario.id}/${step.id}');
          expect(step.question, isNotEmpty);
          expect(step.options.length, greaterThanOrEqualTo(2));

          final int optimal = step.options
              .where((DecisionOption o) => o.quality == OptionQuality.optimal)
              .length;
          expect(optimal, 1,
              reason:
                  '${scenario.id}/${step.id} debe tener exactamente una opcion optima');

          for (final DecisionOption option in step.options) {
            expect(option.feedback, isNotEmpty,
                reason: 'Opcion sin explicacion en ${scenario.id}/${step.id}');
            for (final String kpi in option.effects.keys) {
              expect(kpiIds.contains(kpi), isTrue,
                  reason: 'KPI desconocido "$kpi" en ${scenario.id}');
            }
          }
        }
      }
    }
  });

  test('las competencias declaradas por cada modulo existen', () {
    final Set<String> competencyIds =
        CompetencyCatalog.all.map((CompetencyDef c) => c.id).toSet();
    for (final LearningModule module in readModules()) {
      for (final String id in module.competencies) {
        expect(competencyIds.contains(id), isTrue,
            reason: 'Competencia desconocida "$id" en el modulo ${module.id}');
      }
    }
  });

  test('los prerrequisitos apuntan a modulos existentes', () {
    final List<LearningModule> modules = readModules();
    final Set<String> ids = modules.map((LearningModule m) => m.id).toSet();
    for (final LearningModule module in modules) {
      final String? requires = module.requiresModuleId;
      if (requires != null) {
        expect(ids.contains(requires), isTrue,
            reason: '${module.id} depende de un modulo inexistente');
      }
    }
  });
}
