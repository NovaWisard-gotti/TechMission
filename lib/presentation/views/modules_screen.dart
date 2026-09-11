import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/repositories/scenario_repository.dart';
import '../../domain/models/module.dart';
import '../../domain/models/progress.dart';
import '../providers/providers.dart';
import 'navigation.dart';
import '../widgets/app_card.dart';

class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ContentCatalog> catalogAsync = ref.watch(catalogProvider);
    final LearnerProgress progress = ref.watch(progressProvider).progress;

    return Scaffold(
      appBar: AppBar(title: const Text('Modulos')),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            Center(child: Text('Error al cargar modulos: $e')),
        data: (ContentCatalog catalog) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          itemCount: catalog.learningModules.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final LearningModule module = catalog.learningModules[index];
            final List<String> ids = catalog.scenarioIdsOf(module.id);
            final int done =
                ids.where((String id) => progress.isCompleted(id)).length;
            final bool locked = catalog.isModuleLocked(module, progress);

            return _ModuleCard(
              module: module,
              done: done,
              total: ids.length,
              locked: locked,
            );
          },
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.done,
    required this.total,
    required this.locked,
  });

  final LearningModule module;
  final int done;
  final int total;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool completed = total > 0 && done >= total;

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: AppCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: locked
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Resuelve al menos un caso del modulo anterior para desbloquear este.'),
                    ),
                  )
              : () => openModule(context, module),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: locked
                          ? const Icon(Icons.lock_outline, size: 17)
                          : Text('${module.order}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(module.title,
                              style: text.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(module.area, style: text.bodySmall),
                        ],
                      ),
                    ),
                    if (completed)
                      const Icon(Icons.verified,
                          color: AppTheme.good, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                Text(module.summary, style: text.bodySmall),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          minHeight: 6,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$done/$total casos', style: text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
