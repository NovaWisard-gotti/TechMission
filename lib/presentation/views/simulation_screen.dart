import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../domain/engine/simulation_engine.dart';
import '../../domain/models/competency.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/scenario.dart';
import '../providers/providers.dart';
import '../viewmodels/simulation_view_model.dart';
import '../widgets/assistant_panel.dart';
import '../widgets/kpi_dashboard.dart';
import '../widgets/simulation_widgets.dart';
import 'result_screen.dart';

/// Pantalla del caso: un paso a la vez, decision, consecuencia y feedback.
///
/// La secuencia decidir -> ver consecuencia -> leer explicacion es deliberada:
/// el estudiante debe comprometerse con una decision antes de recibir la
/// explicacion, que es lo que convierte el ejercicio en practica y no lectura.
class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({
    super.key,
    required this.scenarioId,
    this.isDiagnostic = false,
  });

  final String scenarioId;
  final bool isDiagnostic;

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  bool _saved = false;

  void _finish(SimulationState state) {
    if (_saved) return;
    _saved = true;
    final SimulationViewModel vm =
        ref.read(simulationProvider(widget.scenarioId).notifier);
    final ScenarioResult result = vm.buildResult();
    ref
        .read(progressProvider.notifier)
        .saveResult(result, isDiagnostic: widget.isDiagnostic);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          result: result,
          scenario: state.scenario,
          decisions: state.decisions,
          isDiagnostic: widget.isDiagnostic,
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Salir del caso'),
        content: const Text(
            'Si sales ahora se pierden las decisiones de esta corrida. El caso queda disponible para reintentarlo.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir en el caso'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  void _openAssistant(SimulationState state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: AssistantPanel(simulationContext: state),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SimulationState state =
        ref.watch(simulationProvider(widget.scenarioId));
    final SimulationViewModel vm =
        ref.read(simulationProvider(widget.scenarioId).notifier);
    final AppSettings settings = ref.watch(settingsProvider);

    ref.listen<SimulationState>(simulationProvider(widget.scenarioId),
        (SimulationState? previous, SimulationState next) {
      if (next.finished) _finish(next);
    });

    final SimStep step = state.currentStep;
    final TextTheme text = Theme.of(context).textTheme;
    final Map<String, int> deltas =
        state.revealed && state.selectedOption != null
            ? state.selectedOption!.effects
            : const <String, int>{};

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmExit,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(state.scenario.title,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis),
              Text(
                'Decision ${state.stepIndex + 1} de ${state.scenario.steps.length}',
                style: text.labelSmall,
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              tooltip: 'Asistente',
              onPressed: () => _openAssistant(state),
              icon: const Icon(Icons.support_agent_outlined),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: LinearProgressIndicator(
              value: (state.stepIndex + (state.revealed ? 1 : 0)) /
                  state.scenario.steps.length,
              minHeight: 3,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: <Widget>[
            KpiBoard(kpis: state.kpis, deltas: deltas, compact: true),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(step.title,
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Chip(
                  label: Text(
                    CompetencyCatalog.byId(step.competencyId).label,
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(step.situation, style: text.bodyMedium?.copyWith(height: 1.4)),
            if (step.ticket != null) ...<Widget>[
              const SizedBox(height: 14),
              TicketCard(ticket: step.ticket!),
            ],
            const SizedBox(height: 16),
            Text(step.question,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...List<Widget>.generate(step.options.length, (int index) {
              final DecisionOption option = step.options[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OptionCard(
                  option: option,
                  index: index,
                  selected: state.selectedOptionId == option.id,
                  revealed: state.revealed,
                  onTap: () => vm.select(option.id),
                ),
              );
            }),
            if (!state.revealed &&
                settings.hintsEnabled &&
                step.hint.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: vm.toggleHint,
                icon: Icon(state.hintVisible
                    ? Icons.visibility_off_outlined
                    : Icons.lightbulb_outline),
                label: Text(state.hintVisible ? 'Ocultar pista' : 'Ver pista'),
              ),
              if (state.hintVisible)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withOpacity(0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(step.hint, style: const TextStyle(fontSize: 13)),
                ),
            ],
            if (state.revealed && state.selectedOption != null) ...<Widget>[
              const SizedBox(height: 8),
              FeedbackPanel(
                option: state.selectedOption!,
                frameworkRef: step.frameworkRef,
              ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: state.revealed
                ? FilledButton.icon(
                    onPressed: vm.advance,
                    icon: Icon(state.isLastStep
                        ? Icons.flag_outlined
                        : Icons.arrow_forward_rounded),
                    label: Text(state.isLastStep
                        ? 'Ver resultados del caso'
                        : 'Siguiente decision'),
                  )
                : FilledButton(
                    onPressed:
                        state.selectedOptionId == null ? null : vm.confirm,
                    child: const Text('Confirmar decision'),
                  ),
          ),
        ),
      ),
    );
  }
}
