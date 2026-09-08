import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/repositories/scenario_repository.dart';
import '../../domain/models/competency.dart';
import '../../domain/models/module.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/scenario.dart';
import '../providers/providers.dart';
import 'navigation.dart';
import '../widgets/app_card.dart';

class ModuleDetailScreen extends ConsumerWidget {
  const ModuleDetailScreen({super.key, required this.module});

  final LearningModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ContentCatalog> catalogAsync = ref.watch(catalogProvider);
    final LearnerProgress progress = ref.watch(progressProvider).progress;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) => Center(child: Text('Error: $e')),
        data: (ContentCatalog catalog) {
          final List<Scenario> scenarios = catalog.scenariosOf(module.id);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: <Widget>[
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(module.framework,
                          style: text.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 6),
                      Text(module.summary, style: text.bodyMedium),
                      const SizedBox(height: 12),
                      Text('Competencias que entrena',
                          style: text.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: module.competencies
                            .map((String id) => Chip(
                                  label: Text(
                                      CompetencyCatalog.byId(id).label),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Casos empresariales',
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...scenarios.map(
                (Scenario scenario) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ScenarioCard(
                    scenario: scenario,
                    result: progress.bestFor(scenario.id),
                    isDiagnostic: module.isDiagnostic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.result,
    required this.isDiagnostic,
  });

  final Scenario scenario;
  final ScenarioResult? result;
  final bool isDiagnostic;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () =>
            openBriefing(context, scenario, isDiagnostic: isDiagnostic),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(scenario.title,
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (result != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.statusColor(result!.scorePercent)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        result!.scorePercent.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.statusColor(result!.scorePercent),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(scenario.company, style: text.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  _Tag(
                      icon: Icons.signal_cellular_alt,
                      label: scenario.difficulty),
                  _Tag(
                      icon: Icons.timer_outlined,
                      label: '${scenario.estimatedMinutes} min'),
                  _Tag(
                      icon: Icons.rule,
                      label: '${scenario.steps.length} decisiones'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
