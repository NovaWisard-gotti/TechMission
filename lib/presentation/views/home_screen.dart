import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/repositories/scenario_repository.dart';
import '../../domain/models/competency.dart';
import '../../domain/models/module.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/scenario.dart';
import '../providers/providers.dart';
import '../viewmodels/progress_view_model.dart';
import 'navigation.dart';
import '../widgets/app_card.dart';

/// Pantalla de inicio: estado del estudiante y siguiente accion recomendada.
///
/// Regla de diseno: la app siempre debe responder "que hago ahora" con un solo
/// boton visible, para que el estudiante no gaste su tiempo navegando.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ContentCatalog> catalogAsync = ref.watch(catalogProvider);
    final ProgressState progressState = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TechMission'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () => openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => _ErrorView(error: error),
        data: (ContentCatalog catalog) => _HomeBody(
          catalog: catalog,
          progress: progressState.progress,
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.catalog, required this.progress});

  final ContentCatalog catalog;
  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    final Scenario? next = _recommendedScenario();
    final int completed = progress.bestByScenario.keys
        .where((String id) => catalog.scenarioById(id) != null)
        .length;
    final int total = catalog.scenarios
        .where((Scenario s) => s.moduleId != 'diagnostico')
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: <Widget>[
        _StatusHeader(progress: progress, completed: completed, total: total),
        const SizedBox(height: 14),
        if (!progress.diagnosticDone && catalog.diagnosticModule != null)
          _DiagnosticCard(catalog: catalog)
        else if (next != null)
          _NextCaseCard(scenario: next, progress: progress),
        const SizedBox(height: 14),
        _RecommendationCard(progress: progress),
        const SizedBox(height: 14),
        Text(
          'Modulos',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...catalog.learningModules.map(
          (LearningModule module) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ModuleMiniCard(
              module: module,
              scenarioIds: catalog.scenarioIdsOf(module.id),
              progress: progress,
            ),
          ),
        ),
      ],
    );
  }

  /// Siguiente caso: el primer escenario no completado del modulo mas atrasado.
  Scenario? _recommendedScenario() {
    for (final LearningModule module in catalog.learningModules) {
      for (final Scenario scenario in catalog.scenariosOf(module.id)) {
        if (!progress.isCompleted(scenario.id)) return scenario;
      }
    }
    // Todo completado: sugerir el escenario con la nota mas baja para repetir.
    ScenarioResult? worst;
    for (final ScenarioResult r in progress.bestByScenario.values) {
      if (worst == null || r.scorePercent < worst.scorePercent) worst = r;
    }
    return worst == null ? null : catalog.scenarioById(worst.scenarioId);
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.progress,
    required this.completed,
    required this.total,
  });

  final LearnerProgress progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primary.withOpacity(0.12),
                  child: Icon(Icons.badge_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Jefe de servicios TI en practicas',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Nivel ${progress.level.label}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (progress.results.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        progress.overallScore.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color:
                              AppTheme.statusColor(progress.overallScore),
                        ),
                      ),
                      Text('promedio',
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : completed / total,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$completed de $total casos empresariales resueltos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({required this.catalog});

  final ContentCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final LearningModule? module = catalog.diagnosticModule;
    if (module == null) return const SizedBox.shrink();
    final List<Scenario> scenarios = catalog.scenariosOf(module.id);
    if (scenarios.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.assignment_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Empieza por el diagnostico',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuatro decisiones rapidas de gestion para ubicar tu nivel y ordenar tu ruta. No es un examen: define por donde te conviene empezar.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () =>
                  openBriefing(context, scenarios.first, isDiagnostic: true),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Hacer diagnostico (4 min)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextCaseCard extends StatelessWidget {
  const _NextCaseCard({required this.scenario, required this.progress});

  final Scenario scenario;
  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    final bool repeated = progress.isCompleted(scenario.id);
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              repeated ? 'Repite tu caso mas debil' : 'Continua donde quedaste',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              scenario.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${scenario.company} - ${scenario.steps.length} decisiones - ${scenario.estimatedMinutes} min',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => openBriefing(context, scenario),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(repeated ? 'Reintentar caso' : 'Abrir caso'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.progress});

  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    final String? weakest = progress.weakestCompetency;
    final String message = weakest == null
        ? progress.level.advice
        : 'Tu punto mas debil hoy es ${CompetencyCatalog.byId(weakest).label.toLowerCase()}. ${CompetencyCatalog.byId(weakest).description}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.lightbulb_outline, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _ModuleMiniCard extends StatelessWidget {
  const _ModuleMiniCard({
    required this.module,
    required this.scenarioIds,
    required this.progress,
  });

  final LearningModule module;
  final List<String> scenarioIds;
  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    final int done =
        scenarioIds.where((String id) => progress.isCompleted(id)).length;
    return AppCard(
      child: ListTile(
        onTap: () => openModule(context, module),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.10),
          child: Text(
            '${module.order}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        title: Text(module.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${module.framework} - $done/${scenarioIds.length} casos',
            style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 12),
            const Text('No se pudo cargar el contenido educativo.'),
            const SizedBox(height: 6),
            Text('$error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
