import 'package:flutter_test/flutter_test.dart';
import 'package:it_management_simulator/domain/services/assistant_service.dart';

void main() {
  const RuleBasedAssistant assistant = RuleBasedAssistant();

  test('responde con el concepto correcto ante una pregunta conocida', () async {
    final AssistantReply reply =
        await assistant.ask(question: '¿Cómo calculo la prioridad?');
    expect(reply.text.toLowerCase(), contains('impacto'));
    expect(reply.fromAi, isFalse);
  });

  test('tolera acentos y mayusculas', () async {
    final AssistantReply reply =
        await assistant.ask(question: 'QUÉ ES UN PROBLEMA Y SU CAUSA RAÍZ');
    expect(reply.text.toLowerCase(), contains('causa'));
  });

  test('no deja al estudiante sin respuesta ante un tema desconocido', () async {
    final AssistantReply reply =
        await assistant.ask(question: 'receta de causa limeña');
    expect(reply.text, isNotEmpty);
    expect(reply.suggestions, isNotEmpty);
  });

  test('el mensaje vacio devuelve una guia de uso', () async {
    final AssistantReply reply = await assistant.ask(question: '   ');
    expect(reply.text, isNotEmpty);
  });

  test('devuelve una pregunta de vuelta y no solo teoria', () async {
    final AssistantReply reply =
        await assistant.ask(question: 'que revisa un CAB antes de un cambio');
    expect(reply.text.toLowerCase(), contains('pregunta para ti'));
  });
}
