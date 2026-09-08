import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../domain/engine/simulation_engine.dart';
import '../providers/providers.dart';
import '../viewmodels/assistant_view_model.dart';

/// Chat del asistente de gestion, reutilizado en la pestana Asistente y en la
/// hoja inferior que se abre durante un caso.
class AssistantPanel extends ConsumerStatefulWidget {
  const AssistantPanel({super.key, this.simulationContext});

  /// Estado del caso en curso, si el panel se abre dentro de una simulacion.
  final SimulationState? simulationContext;

  @override
  ConsumerState<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends ConsumerState<AssistantPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String value) {
    final String text = value.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref
        .read(assistantProvider.notifier)
        .ask(text, context: widget.simulationContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 160,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AssistantState state = ref.watch(assistantProvider);
    final AppSettings settings = ref.watch(settingsProvider);

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: <Widget>[
              Icon(
                settings.aiEnabled ? Icons.auto_awesome : Icons.rule_folder_outlined,
                size: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  settings.aiEnabled
                      ? 'Modo tutor con IA activo. Verifica siempre con tu docente.'
                      : 'Modo local sin conexion. Responde con la base de conocimiento de la app.',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            itemCount: state.messages.length + (state.thinking ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index >= state.messages.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Pensando...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }
              return _Bubble(message: state.messages[index]);
            },
          ),
        ),
        if (state.suggestions.isNotEmpty && state.messages.length <= 2)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) => ActionChip(
                label: Text(state.suggestions[index],
                    style: const TextStyle(fontSize: 11)),
                onPressed: () => _send(state.suggestions[index]),
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: const InputDecoration(
                      hintText: 'Pregunta un concepto o pide una pista',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _send(_controller.text),
                  icon: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool user = message.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: user
              ? scheme.primary.withOpacity(0.10)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(user ? 14 : 4),
            bottomRight: Radius.circular(user ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Text(message.text, style: const TextStyle(fontSize: 13, height: 1.35)),
            if (message.fromAi)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('respuesta generada con IA',
                    style: Theme.of(context).textTheme.labelSmall),
              ),
          ],
        ),
      ),
    );
  }
}
