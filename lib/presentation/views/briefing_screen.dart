import 'package:flutter/material.dart';

import '../../domain/models/scenario.dart';
import '../widgets/kpi_dashboard.dart';
import 'simulation_screen.dart';
import '../widgets/app_card.dart';

/// Briefing del caso: contexto de la empresa, rol asignado y estado inicial
/// del area. Cumple la funcion del "encargo" que recibiria un jefe de servicios
/// TI real antes de empezar a decidir.
class BriefingScreen extends StatelessWidget {
  const BriefingScreen({
    super.key,
    required this.scenario,
    this.isDiagnostic = false,
  });

  final Scenario scenario;
  final bool isDiagnostic;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(isDiagnostic ? 'Diagnostico' : 'Briefing')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          Text(scenario.title,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('${scenario.company}  -  ${scenario.difficulty}',
              style: text.bodySmall),
          const SizedBox(height: 16),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.work_outline, size: 17),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Tu rol: ${scenario.role}',
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(scenario.briefing,
                      style: text.bodyMedium?.copyWith(height: 1.4)),
                ],
              ),
            ),
          ),
          if (scenario.objectives.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Text('Que vas a practicar',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...scenario.objectives.map(
              (String objective) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle_outline, size: 15),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(objective,
                            style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          KpiBoard(kpis: scenario.startingKpis),
          const SizedBox(height: 10),
          Text(
            'Cada decision mueve estos indicadores. Tu nota mide el criterio de gestion, no la suerte.',
            style: text.bodySmall,
          ),
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
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
                'Iniciar (${scenario.steps.length} decisiones - ${scenario.estimatedMinutes} min)'),
          ),
        ],
      ),
    );
  }
}
