/// Indicadores de gestion del departamento de TI simulado.
///
/// Todos los KPI se expresan como un indice 0-100 para que el estudiante
/// pueda leer el tablero de un vistazo. `higherIsBetter == false` significa
/// que un valor alto es malo (por ejemplo, el nivel de riesgo).
class KpiDef {
  const KpiDef({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.initialValue,
    this.higherIsBetter = true,
  });

  final String id;
  final String label;
  final String shortLabel;
  final String description;
  final int initialValue;
  final bool higherIsBetter;
}

class KpiCatalog {
  KpiCatalog._();

  static const String sla = 'sla';
  static const String satisfaction = 'satisfaction';
  static const String budget = 'budget';
  static const String morale = 'morale';
  static const String risk = 'risk';

  static const List<KpiDef> all = <KpiDef>[
    KpiDef(
      id: sla,
      label: 'Cumplimiento de SLA',
      shortLabel: 'SLA',
      description:
          'Porcentaje de tickets resueltos dentro del tiempo acordado con el negocio.',
      initialValue: 72,
    ),
    KpiDef(
      id: satisfaction,
      label: 'Satisfaccion del usuario',
      shortLabel: 'CSAT',
      description:
          'Percepcion de los usuarios sobre la calidad y la comunicacion del servicio.',
      initialValue: 65,
    ),
    KpiDef(
      id: budget,
      label: 'Presupuesto disponible',
      shortLabel: 'Presupuesto',
      description:
          'Margen economico restante del area para el periodo simulado.',
      initialValue: 80,
    ),
    KpiDef(
      id: morale,
      label: 'Moral del equipo',
      shortLabel: 'Equipo',
      description:
          'Carga de trabajo, claridad de prioridades y desgaste del equipo tecnico.',
      initialValue: 70,
    ),
    KpiDef(
      id: risk,
      label: 'Nivel de riesgo operativo',
      shortLabel: 'Riesgo',
      description:
          'Exposicion a fallas, cambios sin control y deuda operativa acumulada.',
      initialValue: 40,
      higherIsBetter: false,
    ),
  ];

  static KpiDef byId(String id) {
    return all.firstWhere(
      (KpiDef k) => k.id == id,
      orElse: () => KpiDef(
        id: id,
        label: id,
        shortLabel: id,
        description: '',
        initialValue: 50,
      ),
    );
  }
}

/// Estado inmutable de los KPI en un momento de la simulacion.
class KpiSnapshot {
  const KpiSnapshot(this.values);

  final Map<String, int> values;

  factory KpiSnapshot.initial([Map<String, int>? overrides]) {
    final Map<String, int> base = <String, int>{
      for (final KpiDef k in KpiCatalog.all) k.id: k.initialValue,
    };
    if (overrides != null) {
      overrides.forEach((String key, int value) {
        if (base.containsKey(key)) base[key] = value;
      });
    }
    return KpiSnapshot(_clampAll(base));
  }

  int operator [](String id) => values[id] ?? 0;

  /// Aplica los efectos de una decision y devuelve un nuevo snapshot.
  KpiSnapshot apply(Map<String, int> deltas) {
    final Map<String, int> next = Map<String, int>.from(values);
    deltas.forEach((String key, int delta) {
      if (!next.containsKey(key)) return;
      next[key] = next[key]! + delta;
    });
    return KpiSnapshot(_clampAll(next));
  }

  /// Indice global de salud del area (0-100), normalizando los KPI invertidos.
  double get healthIndex {
    if (KpiCatalog.all.isEmpty) return 0;
    double total = 0;
    for (final KpiDef def in KpiCatalog.all) {
      final int raw = this[def.id];
      total += def.higherIsBetter ? raw : (100 - raw);
    }
    return total / KpiCatalog.all.length;
  }

  Map<String, int> toJson() => Map<String, int>.from(values);

  factory KpiSnapshot.fromJson(Map<String, dynamic> json) {
    final Map<String, int> parsed = <String, int>{};
    json.forEach((String key, dynamic value) {
      parsed[key] = (value as num).toInt();
    });
    return KpiSnapshot.initial(parsed);
  }

  static Map<String, int> _clampAll(Map<String, int> input) {
    final Map<String, int> out = <String, int>{};
    input.forEach((String key, int value) {
      out[key] = value < 0 ? 0 : (value > 100 ? 100 : value);
    });
    return out;
  }

  @override
  String toString() => 'KpiSnapshot($values)';
}
