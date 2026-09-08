import 'dart:convert';

import 'package:http/http.dart' as http;

import '../engine/simulation_engine.dart';

/// Respuesta del asistente de gestion.
class AssistantReply {
  const AssistantReply({
    required this.text,
    this.fromAi = false,
    this.suggestions = const <String>[],
  });

  final String text;
  final bool fromAi;
  final List<String> suggestions;
}

abstract class AssistantService {
  Future<AssistantReply> ask({
    required String question,
    SimulationState? context,
  });
}

/// Entrada de la base de conocimiento local.
class _KbEntry {
  const _KbEntry(this.keywords, this.answer, {this.followUp = ''});

  final List<String> keywords;
  final String answer;
  final String followUp;
}

/// Asistente basado en reglas: funciona sin conexion y sin costo.
///
/// Es el asistente por defecto del MVP. Su objetivo NO es resolver el caso por
/// el estudiante, sino recordar el marco de referencia y devolver una pregunta
/// que lo obligue a razonar la decision.
class RuleBasedAssistant implements AssistantService {
  const RuleBasedAssistant();

  static const List<String> defaultSuggestions = <String>[
    'Como se calcula la prioridad de un incidente',
    'Diferencia entre incidente y problema',
    'Que revisa un CAB antes de aprobar un cambio',
    'Que significa CPI y SPI',
  ];

  static const List<_KbEntry> knowledgeBase = <_KbEntry>[
    _KbEntry(
      <String>['prioridad', 'priorizar', 'matriz', 'impacto', 'urgencia'],
      'La prioridad de un incidente no se elige por quien grita mas fuerte: sale de cruzar impacto (cuantos usuarios y que servicio critico se ven afectados) con urgencia (que tan rapido se degrada el negocio si no se atiende). Esa matriz es la que define el SLA aplicable.',
      followUp:
          'Para el ticket que tienes al frente: cuantos usuarios estan afectados y que pasa si esperas 4 horas mas.',
    ),
    _KbEntry(
      <String>['incidente', 'interrupcion', 'restaurar'],
      'Un incidente es una interrupcion no planificada o una reduccion de la calidad de un servicio. El objetivo de la gestion de incidentes es restaurar el servicio lo antes posible, aunque sea con una solucion temporal. Encontrar la causa raiz no es su trabajo.',
      followUp: 'Tu decision aqui, restaura el servicio o investiga la causa.',
    ),
    _KbEntry(
      <String>['problema', 'causa raiz', 'raiz', 'recurrente', '5 porque', 'ishikawa'],
      'Un problema es la causa (conocida o no) de uno o mas incidentes. La gestion de problemas trabaja con analisis de causa raiz (5 porques, Ishikawa, analisis de tendencias) y puede terminar en una solucion temporal documentada como error conocido, no siempre en una solucion definitiva inmediata.',
      followUp:
          'La falla que ves se repite en un patron. Que dato usarias para probar tu hipotesis antes de tocar produccion.',
    ),
    _KbEntry(
      <String>['error conocido', 'kedb', 'workaround', 'solucion temporal'],
      'Un error conocido es un problema con causa documentada y una solucion temporal registrada. Guardarlo en la base de errores conocidos permite que la mesa de servicio resuelva el proximo incidente igual en minutos en vez de reabrir toda la investigacion.',
      followUp:
          'Si manana entra el mismo ticket, con lo que dejaste documentado, alguien mas podria resolverlo sin ti.',
    ),
    _KbEntry(
      <String>['solicitud', 'peticion', 'request', 'requerimiento'],
      'Una solicitud de servicio es algo previsto y de bajo riesgo (un acceso, un equipo, una instalacion estandar). No es un incidente porque nada se rompio, y confundirlas infla artificialmente las metricas de incidentes.',
      followUp: 'Lo que te piden, se rompio algo o simplemente falta algo.',
    ),
    _KbEntry(
      <String>['cambio', 'rfc', 'cab', 'aprobacion', 'estandar', 'emergencia'],
      'ITIL distingue tres tipos de cambio: estandar (preautorizado, bajo riesgo, repetible), normal (requiere evaluacion y autorizacion del CAB) y de emergencia (se autoriza por via rapida con el ECAB y se documenta despues). Clasificar mal un cambio normal como estandar es una de las causas mas frecuentes de incidentes mayores.',
      followUp:
          'El cambio que estas evaluando, ya se hizo antes con el mismo procedimiento y resultado.',
    ),
    _KbEntry(
      <String>['retroceso', 'rollback', 'plan de reversion', 'ventana'],
      'Ningun cambio de riesgo medio o alto deberia autorizarse sin plan de retroceso probado, ventana de mantenimiento acordada con el negocio y criterio explicito de exito. Si no sabes como volver atras, no tienes un plan, tienes una apuesta.',
      followUp:
          'Cuanto tarda tu rollback y cabe dentro de la ventana que acordaste.',
    ),
    _KbEntry(
      <String>['sla', 'ola', 'acuerdo', 'nivel de servicio'],
      'El SLA es el acuerdo con el cliente o el negocio; el OLA es el acuerdo interno entre equipos que hace posible cumplir el SLA. Cuando el SLA se incumple de forma sistematica, casi siempre el problema esta en un OLA que nadie negocio.',
      followUp:
          'El tiempo que estas prometiendo depende solo de tu equipo o de un tercero.',
    ),
    _KbEntry(
      <String>['escalar', 'escalamiento', 'jerarquico', 'funcional'],
      'Hay dos escalamientos distintos: el funcional lleva el ticket a un equipo con mas conocimiento tecnico, y el jerarquico avisa a la linea de mando porque hay una decision de negocio o de riesgo que tomar. Escalar tarde por miedo a molestar es un error clasico de un jefe de mesa de servicio novato.',
      followUp:
          'Lo que te falta es conocimiento tecnico o autoridad para decidir.',
    ),
    _KbEntry(
      <String>['itil', 'principios', 'valor', 'practica'],
      'ITIL 4 no es un procedimiento rigido sino un marco con principios rectores: empezar donde estas, progresar iterativamente con retroalimentacion, enfocarse en el valor, colaborar y promover la visibilidad, pensar de forma holistica, mantenerlo simple y practico, optimizar y automatizar.',
      followUp:
          'Que principio esta en tension en la decision que tienes ahora mismo.',
    ),
    _KbEntry(
      <String>['comunicar', 'usuario', 'informar', 'interesado', 'stakeholder'],
      'En un incidente mayor la comunicacion vale tanto como la solucion tecnica. Los usuarios toleran mucho mejor una caida informada con tiempo estimado y canal alterno que un silencio de dos horas seguido de un aviso de que ya esta resuelto.',
      followUp:
          'Quien necesita saber esto ahora y que decision toma esa persona con la informacion que le des.',
    ),
    _KbEntry(
      <String>['scrum', 'sprint', 'backlog', 'product owner', 'scrum master'],
      'En Scrum el alcance del sprint es un compromiso del equipo, no una lista abierta. Si entra trabajo nuevo a mitad de sprint, alguien tiene que decidir que sale, y esa decision es del Product Owner con el equipo, no del interesado que llego mas tarde.',
      followUp:
          'Lo que te estan pidiendo, no puede esperar al siguiente sprint o solo se siente urgente.',
    ),
    _KbEntry(
      <String>['definicion de terminado', 'dod', 'terminado', 'definition of done'],
      'La definicion de terminado existe para evitar el trabajo que parece completo y vuelve como incidente. Si una historia pasa a terminado sin pruebas, sin documentacion y sin despliegue verificado, el equipo esta trasladando deuda a operaciones.',
      followUp:
          'Lo que vas a marcar como terminado, podria entrar a produccion hoy sin retrabajo.',
    ),
    _KbEntry(
      <String>['pmbok', 'valor ganado', 'evm', 'cpi', 'spi', 'cronograma'],
      'En valor ganado, CPI = EV/AC mide eficiencia de costo y SPI = EV/PV mide avance frente al plan. Un valor menor a 1 indica desviacion. Un SPI de 0.8 con CPI de 1.0 dice que el proyecto va lento pero no caro, y eso cambia por completo la accion correctiva.',
      followUp:
          'Con los numeros del caso, el problema es de costo, de tiempo, o de ambos.',
    ),
    _KbEntry(
      <String>['riesgo', 'registro de riesgo', 'mitigar', 'contingencia'],
      'Un riesgo se gestiona antes de ocurrir: se identifica, se estima probabilidad e impacto, y se decide una respuesta (evitar, mitigar, transferir o aceptar) con un responsable y un disparador. Un riesgo sin responsable ni disparador es solo una anotacion en un acta.',
      followUp:
          'Ese riesgo, quien lo vigila y que senal concreta activaria la respuesta.',
    ),
    _KbEntry(
      <String>['mvp', 'alcance', 'producto', 'minimo viable'],
      'Un MVP no es una version incompleta del producto final: es la version mas pequena que ya entrega valor y genera aprendizaje real de los usuarios. Si al recortar una funcionalidad el usuario ya no puede completar el flujo principal, esa funcionalidad no era recortable.',
      followUp:
          'De las funciones que quieres incluir, cual romperia el flujo principal si la quitas.',
    ),
    _KbEntry(
      <String>['metrica', 'kpi', 'indicador', 'tablero'],
      'Los indicadores de TI se leen en conjunto, nunca aislados. Un SLA alto con satisfaccion baja suele significar que se estan cerrando tickets rapido sin resolver el problema del usuario, y ese patron es una senal de alerta, no un logro.',
      followUp:
          'En tu tablero, que indicador esta subiendo a costa de otro.',
    ),
  ];

  @override
  Future<AssistantReply> ask({
    required String question,
    SimulationState? context,
  }) async {
    final String normalized = _normalize(question);

    if (normalized.trim().isEmpty) {
      return const AssistantReply(
        text:
            'Preguntame por un concepto de gestion (prioridad, cambio, causa raiz, CPI) o pideme una pista del caso actual.',
        suggestions: defaultSuggestions,
      );
    }

    // Pista contextual del paso actual.
    final bool asksForHint = <String>['pista', 'ayuda', 'no se', 'no entiendo', 'que hago']
        .any((String k) => normalized.contains(k));
    if (asksForHint && context != null) {
      final String hint = context.currentStep.hint;
      final String ref = context.currentStep.frameworkRef;
      return AssistantReply(
        text: hint.isEmpty
            ? 'Revisa que te pide exactamente el caso y con que criterio se decide en ${ref.isEmpty ? 'el marco de referencia' : ref}.'
            : '$hint\n\nReferencia: ${ref.isEmpty ? 'gestion de servicios TI' : ref}.\n\nNo te voy a dar la opcion correcta: decide y luego comparamos.',
        suggestions: defaultSuggestions,
      );
    }

    _KbEntry? best;
    int bestScore = 0;
    for (final _KbEntry entry in knowledgeBase) {
      int score = 0;
      for (final String keyword in entry.keywords) {
        if (normalized.contains(keyword)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }

    if (best == null) {
      return AssistantReply(
        text:
            'No tengo una respuesta preparada para eso sin conexion. Puedo ayudarte con prioridad, incidentes, problemas, cambios, SLA, Scrum, valor ganado, riesgos, MVP e indicadores. Si activas el asistente con IA en Ajustes, puedo responder preguntas abiertas.',
        suggestions: defaultSuggestions,
      );
    }

    final StringBuffer buffer = StringBuffer(best.answer);
    if (best.followUp.isNotEmpty) {
      buffer.write('\n\nPregunta para ti: ${best.followUp}');
    }
    if (context != null) {
      buffer.write(
          '\n\nCaso actual: ${context.scenario.title} - paso "${context.currentStep.title}".');
    }
    return AssistantReply(text: buffer.toString(), suggestions: defaultSuggestions);
  }

  String _normalize(String input) {
    const Map<String, String> accents = <String, String>{
      'a': 'á',
      'e': 'é',
      'i': 'í',
      'o': 'ó',
      'u': 'úü',
      'n': 'ñ',
    };
    String out = input.toLowerCase();
    accents.forEach((String plain, String variants) {
      for (final String rune in variants.split('')) {
        out = out.replaceAll(rune, plain);
      }
    });
    return out;
  }
}

/// Asistente con modelo de lenguaje. Solo se activa si el usuario configura
/// una clave de API en Ajustes; si falla, cae al asistente de reglas para que
/// la app nunca quede sin respuesta.
class LlmAssistant implements AssistantService {
  LlmAssistant({
    required this.apiKey,
    this.fallback = const RuleBasedAssistant(),
    http.Client? client,
    this.model = defaultModel,
  }) : _client = client ?? http.Client();

  static const String defaultModel = 'claude-sonnet-5';
  static const String endpoint = 'https://api.anthropic.com/v1/messages';

  final String apiKey;
  final AssistantService fallback;
  final String model;
  final http.Client _client;

  static const String systemPrompt = '''
Eres el tutor de un simulador educativo de gestion de servicios TI para estudiantes universitarios de Ingenieria de Sistemas.
Reglas estrictas:
1. Nunca digas cual opcion debe elegir el estudiante ni des la respuesta del caso.
2. Explica el marco de referencia (ITIL 4, Scrum o PMBOK) que aplica y devuelve una pregunta que obligue a razonar.
3. Maximo 120 palabras, en espanol, tono profesional y directo.
4. Si el estudiante insiste en que le des la respuesta, recuerdale que el objetivo es que la sustente el.
''';

  @override
  Future<AssistantReply> ask({
    required String question,
    SimulationState? context,
  }) async {
    if (apiKey.trim().isEmpty) {
      return fallback.ask(question: question, context: context);
    }
    try {
      final StringBuffer prompt = StringBuffer();
      if (context != null) {
        prompt.writeln('Contexto del caso: ${context.scenario.title}.');
        prompt.writeln('Paso actual: ${context.currentStep.title}.');
        prompt.writeln('Situacion: ${context.currentStep.situation}');
        if (context.currentStep.frameworkRef.isNotEmpty) {
          prompt.writeln('Marco aplicable: ${context.currentStep.frameworkRef}');
        }
        prompt.writeln('---');
      }
      prompt.write('Pregunta del estudiante: $question');

      final http.Response response = await _client
          .post(
            Uri.parse(endpoint),
            headers: <String, String>{
              'content-type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode(<String, dynamic>{
              'model': model,
              'max_tokens': 400,
              'system': systemPrompt,
              'messages': <Map<String, dynamic>>[
                <String, dynamic>{'role': 'user', 'content': prompt.toString()},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return fallback.ask(question: question, context: context);
      }

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> content = data['content'] as List<dynamic>? ?? <dynamic>[];
      final String text = content
          .where((dynamic block) =>
              (block as Map<String, dynamic>)['type'] == 'text')
          .map((dynamic block) =>
              (block as Map<String, dynamic>)['text'] as String? ?? '')
          .join('\n')
          .trim();

      if (text.isEmpty) {
        return fallback.ask(question: question, context: context);
      }
      return AssistantReply(
        text: text,
        fromAi: true,
        suggestions: RuleBasedAssistant.defaultSuggestions,
      );
    } catch (_) {
      return fallback.ask(question: question, context: context);
    }
  }
}
