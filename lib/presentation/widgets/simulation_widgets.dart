import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/kpi.dart';
import '../../domain/models/scenario.dart';

/// Tarjeta que reproduce el aspecto de un ticket en una herramienta real de
/// mesa de servicio (codigo, servicio, impacto, urgencia).
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.code,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(ticket.type, style: text.labelMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.title,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (ticket.detail.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(ticket.detail, style: text.bodySmall),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _MetaChip(icon: Icons.person_outline, label: ticket.reportedBy),
              _MetaChip(icon: Icons.dns_outlined, label: ticket.service),
              _MetaChip(
                  icon: Icons.groups_outlined, label: 'Impacto: ${ticket.impact}'),
              _MetaChip(
                  icon: Icons.timer_outlined, label: 'Urgencia: ${ticket.urgency}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

/// Opcion de decision seleccionable.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.option,
    required this.index,
    required this.selected,
    required this.revealed,
    required this.onTap,
  });

  final DecisionOption option;
  final int index;
  final bool selected;
  final bool revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Color border = scheme.outlineVariant;
    Color background = Colors.transparent;

    if (revealed) {
      if (option.quality == OptionQuality.optimal) {
        border = AppTheme.good;
        background = AppTheme.good.withOpacity(0.08);
      } else if (selected) {
        border = option.quality == OptionQuality.acceptable
            ? AppTheme.warning
            : AppTheme.bad;
        background = border.withOpacity(0.08);
      }
    } else if (selected) {
      border = scheme.primary;
      background = scheme.primary.withOpacity(0.06);
    }

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: revealed ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border, width: selected || revealed ? 1.6 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected || (revealed && option.quality == OptionQuality.optimal)
                      ? border
                      : scheme.surfaceContainerHighest,
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected || (revealed && option.quality == OptionQuality.optimal)
                        ? Colors.white
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (revealed && option.quality == OptionQuality.optimal)
                const Icon(Icons.check_circle, size: 18, color: AppTheme.good),
            ],
          ),
        ),
      ),
    );
  }
}

/// Retroalimentacion mostrada despues de confirmar una decision.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.option,
    required this.frameworkRef,
  });

  final DecisionOption option;
  final String frameworkRef;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (option.quality) {
      case OptionQuality.optimal:
        color = AppTheme.good;
        icon = Icons.check_circle_outline;
        break;
      case OptionQuality.acceptable:
        color = AppTheme.warning;
        icon = Icons.info_outline;
        break;
      case OptionQuality.poor:
        color = AppTheme.bad;
        icon = Icons.error_outline;
        break;
    }

    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        border: Border.all(color: color.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                option.quality.label,
                style: text.titleSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (option.consequence.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text('Que paso en la empresa',
                style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(option.consequence, style: text.bodySmall),
          ],
          const SizedBox(height: 10),
          Text('Por que',
              style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(option.feedback, style: text.bodySmall),
          if (frameworkRef.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                const Icon(Icons.menu_book_outlined, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(frameworkRef,
                      style: text.labelSmall
                          ?.copyWith(fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ],
          if (option.effects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: option.effects.entries.map((MapEntry<String, int> e) {
                final KpiDef def = KpiCatalog.byId(e.key);
                final bool improves =
                    def.higherIsBetter ? e.value > 0 : e.value < 0;
                final Color c = improves ? AppTheme.good : AppTheme.bad;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${def.shortLabel} ${e.value > 0 ? '+' : ''}${e.value}',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: c),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
