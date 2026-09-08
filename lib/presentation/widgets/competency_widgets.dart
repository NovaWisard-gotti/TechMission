import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/competency.dart';
import 'app_card.dart';

/// Perfil de competencias en barras horizontales.
///
/// Se prefiere barras sobre un radar porque en pantalla de celular el radar es
/// bonito pero dificil de leer con precision, y aqui el estudiante necesita
/// comparar valores exactos para decidir que reforzar.
class CompetencyProfile extends StatelessWidget {
  const CompetencyProfile({
    super.key,
    required this.scores,
    this.title = 'Perfil de competencias',
    this.showEmpty = true,
  });

  final Map<String, double> scores;
  final String title;
  final bool showEmpty;

  @override
  Widget build(BuildContext context) {
    final List<CompetencyDef> defs = CompetencyCatalog.all
        .where((CompetencyDef d) => showEmpty || scores.containsKey(d.id))
        .toList();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ...defs.map((CompetencyDef def) {
              final double? value = scores[def.id];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 116,
                      child: Text(
                        def.label,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (value ?? 0) / 100,
                          minHeight: 8,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            value == null
                                ? Theme.of(context).colorScheme.outlineVariant
                                : AppTheme.statusColor(value),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 42,
                      child: Text(
                        value == null ? 'sin datos' : value.toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Anillo de puntaje del escenario.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    required this.label,
    this.size = 132,
  });

  final double score;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.statusColor(score);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: score / 100,
          color: color,
          track: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 11;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (math.min(size.width, size.height) - stroke) / 2;

    final Paint trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    final Paint valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value.clamp(0.0, 1.0),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
