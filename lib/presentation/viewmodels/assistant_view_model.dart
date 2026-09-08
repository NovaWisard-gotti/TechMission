import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/simulation_engine.dart';
import '../../domain/services/assistant_service.dart';

class AssistantMessage {
  const AssistantMessage({
    required this.text,
    required this.fromUser,
    this.fromAi = false,
  });

  final String text;
  final bool fromUser;
  final bool fromAi;
}

class AssistantState {
  const AssistantState({
    this.messages = const <AssistantMessage>[],
    this.thinking = false,
    this.suggestions = RuleBasedAssistant.defaultSuggestions,
  });

  final List<AssistantMessage> messages;
  final bool thinking;
  final List<String> suggestions;

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    bool? thinking,
    List<String>? suggestions,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      thinking: thinking ?? this.thinking,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class AssistantViewModel extends StateNotifier<AssistantState> {
  AssistantViewModel(this._service)
      : super(const AssistantState(messages: <AssistantMessage>[
          AssistantMessage(
            text:
                'Soy tu asistente de gestion. No resuelvo los casos por ti: te recuerdo el marco (ITIL 4, Scrum, PMBOK) y te devuelvo la pregunta que deberias hacerte antes de decidir.',
            fromUser: false,
          ),
        ]));

  final AssistantService _service;

  Future<void> ask(String question, {SimulationState? context}) async {
    final String trimmed = question.trim();
    if (trimmed.isEmpty || state.thinking) return;

    state = state.copyWith(
      thinking: true,
      messages: <AssistantMessage>[
        ...state.messages,
        AssistantMessage(text: trimmed, fromUser: true),
      ],
    );

    final AssistantReply reply =
        await _service.ask(question: trimmed, context: context);

    state = state.copyWith(
      thinking: false,
      suggestions: reply.suggestions,
      messages: <AssistantMessage>[
        ...state.messages,
        AssistantMessage(
          text: reply.text,
          fromUser: false,
          fromAi: reply.fromAi,
        ),
      ],
    );
  }

  void clear() => state = const AssistantState();
}
