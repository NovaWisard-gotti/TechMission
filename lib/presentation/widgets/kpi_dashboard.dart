import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/kpi.dart';
import 'app_card.dart';

/// Tablero de indicadores del area de TI.
///
/// Se muestra siempre visible durante la simulacion: la idea es que el
/// estudiante vea el costo de sus decisiones mientras decide, no al final.
class KpiBoard extends StatelessWidget {
  const KpiBoard({
    super.key,
    required this.kpis,
    this.deltas = const <String, int>{},
    this.compact = false,
  });

  final KpiSnapshot kpis;
  final Map<String, int> deltas;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.speed_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Tablero del area',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                _HealthPill(value: kpis.healthIndex),
              ],
            ),
            const SizedBox(height: 10),
            ...KpiCatalog.all.map(
              (KpiDef def) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _KpiRow(
                  def: def,
                  value: kpis[def.id],
                  delta: deltas[def.id] ?? 0,
                  compact: compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.def,
    required this.value,
    required this.delta,
    required this.compact,
  });

  final KpiDef def;
  final int value;
  final int delta;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double normalized =
        def.higherIsBetter ? value.toDouble() : (100 - value).toDouble();
    final Color color = AppTheme.statusColor(normalized);
    final TextTheme text = Theme.of(context).textTheme;

    return Semantics(
      label: '${def.label}: $value de 100',
      child: Row(
        children: <Widget>[
          SizedBox(
            width: compact ? 78 : 96,
            child: Text(
              compact ? def.shortLabel : def.label,
              style: text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 42,
            child: delta == 0
                ? const SizedBox.shrink()
                : Text(
                    delta > 0 ? '+$delta' : '$delta',
                    textAlign: TextAlign.right,
                    style: text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _deltaColor(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _deltaColor() {
    final bool improves = def.higherIsBetter ? delta > 0 : delta < 0;
    return improves ? AppTheme.good : AppTheme.bad;
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.statusColor(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        'Salud ${value.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
