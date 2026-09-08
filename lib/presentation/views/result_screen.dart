import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../domain/engine/simulation_engine.dart';
import '../../domain/models/competency.dart';
import '../../domain/models/kpi.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/scenario.dart';
import '../widgets/competency_widgets.dart';
import '../widgets/kpi_dashboard.dart';
import 'simulation_screen.dart';
import '../widgets/app_card.dart';

/// Debriefing del caso.
///
/// Un simulador sin debriefing es un juego: aqui se cierra el ciclo mostrando
/// que decision se tomo, que efecto tuvo y que criterio profesional aplicaba.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.scenario,
    required this.decisions,
    this.isDiagnostic = false,
  });

  final ScenarioResult result;
  final Scenario scenario;
  final List<DecisionRecord> decisions;
  final bool isDiagnostic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isDiagnostic ? 'Resultado del diagnostico' : 'Resultado del caso'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: <Widget>[
          Center(
            child: ScoreRing(score: result.scorePercent, label: result.grade),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${result.optimalDecisions} de ${result.totalDecisions} decisiones optimas',
              style: text.bodySmall,
            ),
          ),
          const SizedBox(height: 18),
          if (isDiagnostic) _DiagnosticSummary(score: result.scorePercent),
          if (isDiagnostic) const SizedBox(height: 14),
          CompetencyProfile(
            scores: result.competencyScores,
            title: 'Competencias evaluadas en este caso',
            showEmpty: false,
          ),
          const SizedBox(height: 14),
          KpiBoard(kpis: KpiSnapshot(result.finalKpis)),
          const SizedBox(height: 18),
          Text('Revision de tus decisiones',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...List<Widget>.generate(decisions.length, (int index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DecisionReview(
                index: index + 1,
                record: decisions[index],
              ),
            );
          }),
          if (scenario.takeaways.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Que deberias llevarte de este caso',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...scenario.takeaways.map(
                      (String item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(Icons.arrow_right, size: 16),
                            ),
                            Expanded(
                                child: Text(item,
                                    style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => SimulationScreen(
                    scenarioId: scenario.id,
                    isDiagnostic: isDiagnostic,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.replay),
            label: const Text('Reintentar el caso'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).popUntil((Route<void> r) => r.isFirst),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticSummary extends StatelessWidget {
  const _DiagnosticSummary({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final LearnerLevel level = const SimulationEngine().levelFromScore(score);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Nivel asignado: ${level.label}',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(level.advice, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _DecisionReview extends StatelessWidget {
  const _DecisionReview({required this.index, required this.record});

  final int index;
  final DecisionRecord record;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (record.quality) {
      case OptionQuality.optimal:
        color = AppTheme.good;
        break;
      case OptionQuality.acceptable:
        color = AppTheme.warning;
        break;
      case OptionQuality.poor:
        color = AppTheme.bad;
        break;
    }
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(0.14),
            child: Text('$index',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
          title: Text(record.stepTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${record.quality.label} - ${CompetencyCatalog.byId(record.competencyId).label}',
            style: text.labelSmall?.copyWith(color: color),
          ),
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Elegiste: ${record.optionLabel}',
                  style: text.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(record.feedback, style: text.bodySmall),
            ),
            if (record.frameworkRef.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(record.frameworkRef,
                    style: text.labelSmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
