import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/audio_constants.dart';
import '../../../shared/theme/app_theme.dart';

/// Muestra el valor numérico de dB con un gauge circular profesional.
class DbDisplay extends StatelessWidget {
  final double db;
  final double? legalLimit;

  const DbDisplay({
    super.key,
    required this.db,
    this.legalLimit = 55.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorForDb(db);
    final label = AppTheme.labelForDb(db);

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gauge circular de fondo.
          CustomPaint(
            size: const Size(240, 240),
            painter: _GaugePainter(
              db: db,
              color: color,
              legalLimit: legalLimit,
            ),
          ),
          // Valor numérico centrado.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                db.toStringAsFixed(1),
                style: TextStyle(
                  color: color,
                  fontSize: 56,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -2,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'dB SPL',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pinta un arco (gauge) que refleja el nivel actual de dB.
class _GaugePainter extends CustomPainter {
  final double db;
  final Color color;
  final double? legalLimit;

  _GaugePainter({
    required this.db,
    required this.color,
    this.legalLimit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    // Arco base (fondo).
    const startAngle = math.pi * 0.75; // 135 grados
    const sweepAngle = math.pi * 1.5; // 270 grados

    final bgPaint = Paint()
      ..color = AppTheme.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Arco de progreso.
    final fraction = ((db - AudioConstants.minDb) /
            (AudioConstants.maxDb - AudioConstants.minDb))
        .clamp(0.0, 1.0);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          AppTheme.levelQuiet,
          AppTheme.levelModerate,
          AppTheme.levelLoud,
          AppTheme.levelDangerous,
        ],
        stops: const [0.0, 0.4, 0.65, 0.85],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * fraction,
      false,
      progressPaint,
    );

    // Marcador del límite legal.
    if (legalLimit != null) {
      final limitFraction = ((legalLimit! - AudioConstants.minDb) /
              (AudioConstants.maxDb - AudioConstants.minDb))
          .clamp(0.0, 1.0);
      final limitAngle = startAngle + sweepAngle * limitFraction;

      final outerRadius = radius + 4;
      final innerRadius = radius - 4;

      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(limitAngle),
        center.dy + outerRadius * math.sin(limitAngle),
      );
      final innerPoint = Offset(
        center.dx + innerRadius * math.cos(limitAngle),
        center.dy + innerRadius * math.sin(limitAngle),
      );

      final limitPaint = Paint()
        ..color = AppTheme.danger
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(innerPoint, outerPoint, limitPaint);

      // Punto exterior del marcador.
      final dotPoint = Offset(
        center.dx + (outerRadius + 8) * math.cos(limitAngle),
        center.dy + (outerRadius + 8) * math.sin(limitAngle),
      );
      canvas.drawCircle(
        dotPoint,
        3,
        Paint()..color = AppTheme.danger,
      );
    }

    // Marcas de graduación cada 10 dB.
    final tickPaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (var i = AudioConstants.minDb.toInt();
        i <= AudioConstants.maxDb.toInt();
        i += 10) {
      final tickFraction = ((i - AudioConstants.minDb) /
              (AudioConstants.maxDb - AudioConstants.minDb))
          .clamp(0.0, 1.0);
      final tickAngle = startAngle + sweepAngle * tickFraction;
      final outer = radius - 12;
      final inner = radius - 18;

      canvas.drawLine(
        Offset(
          center.dx + inner * math.cos(tickAngle),
          center.dy + inner * math.sin(tickAngle),
        ),
        Offset(
          center.dx + outer * math.cos(tickAngle),
          center.dy + outer * math.sin(tickAngle),
        ),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.db != db || oldDelegate.color != color;
  }
}
