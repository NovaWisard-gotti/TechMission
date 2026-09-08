/// Competencias observables que la simulacion evalua.
///
/// Cada paso de un escenario declara la competencia que pone a prueba, de modo
/// que el resultado final no sea una nota unica sino un perfil por competencia.
class CompetencyDef {
  const CompetencyDef({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class CompetencyCatalog {
  CompetencyCatalog._();

  static const String incidents = 'inc';
  static const String problems = 'prb';
  static const String changes = 'chg';
  static const String planning = 'plan';
  static const String prioritization = 'prio';
  static const String communication = 'comm';

  static const List<CompetencyDef> all = <CompetencyDef>[
    CompetencyDef(
      id: incidents,
      label: 'Gestion de incidentes',
      description:
          'Clasificar, escalar y restaurar el servicio en el menor tiempo posible.',
    ),
    CompetencyDef(
      id: problems,
      label: 'Gestion de problemas',
      description:
          'Encontrar la causa raiz de fallas recurrentes y decidir entre solucion temporal y definitiva.',
    ),
    CompetencyDef(
      id: changes,
      label: 'Gestion de cambios',
      description:
          'Evaluar riesgo, autorizar y desplegar cambios con plan de retroceso.',
    ),
    CompetencyDef(
      id: planning,
      label: 'Planificacion',
      description:
          'Estimar, secuenciar y controlar alcance, tiempo y costo del trabajo de TI.',
    ),
    CompetencyDef(
      id: prioritization,
      label: 'Priorizacion',
      description:
          'Decidir que se atiende primero cuando la demanda supera la capacidad.',
    ),
    CompetencyDef(
      id: communication,
      label: 'Comunicacion con interesados',
      description:
          'Informar estado, expectativas y decisiones a usuarios y direccion.',
    ),
  ];

  static CompetencyDef byId(String id) {
    return all.firstWhere(
      (CompetencyDef c) => c.id == id,
      orElse: () => CompetencyDef(id: id, label: id, description: ''),
    );
  }
}
