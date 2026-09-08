import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../domain/models/competency.dart';
import '../../domain/models/progress.dart';
import '../providers/providers.dart';
import '../viewmodels/progress_view_model.dart';
import '../widgets/competency_widgets.dart';
import '../widgets/app_card.dart';

/// Panel de progreso: perfil de competencias e historial de intentos.
///
/// Se muestra el perfil por competencia y no una sola nota global porque la
/// decision util para el estudiante es "que reforzar", no "cuanto saque".
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProgressState state = ref.watch(progressProvider);
    final LearnerProgress progress = state.progress;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reiniciar progreso',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Reiniciar progreso'),
                  content: const Text(
                      'Se borran todos tus resultados y el diagnostico. Esta accion no se puede deshacer.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Borrar'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(progressProvider.notifier).reset();
              }
            },
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : progress.results.isEmpty
              ? const _EmptyProgress()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: <Widget>[
                    _SummaryCard(progress: progress),
                    const SizedBox(height: 14),
                    CompetencyProfile(scores: progress.competencyAverages),
                    const SizedBox(height: 14),
                    _WeakestAdvice(progress: progress),
                    const SizedBox(height: 18),
                    Text('Historial de intentos',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...progress.results.reversed.map(
                      (ScenarioResult r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppTheme.statusColor(r.scorePercent)
                                      .withOpacity(0.14),
                              child: Text(
                                r.scorePercent.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.statusColor(r.scorePercent),
                                ),
                              ),
                            ),
                            title: Text(r.scenarioTitle,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${r.grade} - ${_formatDate(r.completedAt)} - ${r.durationSeconds ~/ 60} min',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.progress});

  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            ScoreRing(
              score: progress.overallScore,
              label: 'promedio',
              size: 96,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Stat(
                      label: 'Casos resueltos',
                      value: '${progress.bestByScenario.length}'),
                  _Stat(
                      label: 'Intentos totales',
                      value: '${progress.results.length}'),
                  _Stat(label: 'Nivel', value: progress.level.label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WeakestAdvice extends StatelessWidget {
  const _WeakestAdvice({required this.progress});

  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    final String? weakest = progress.weakestCompetency;
    if (weakest == null) return const SizedBox.shrink();
    final CompetencyDef def = CompetencyCatalog.byId(weakest);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.trending_up, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Refuerza ${def.label.toLowerCase()}: ${def.description} Repite los casos de ese modulo sin usar pistas.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.insights_outlined, size: 40),
            const SizedBox(height: 12),
            Text('Todavia no hay datos',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Resuelve el diagnostico o cualquier caso empresarial para empezar a construir tu perfil de competencias.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
