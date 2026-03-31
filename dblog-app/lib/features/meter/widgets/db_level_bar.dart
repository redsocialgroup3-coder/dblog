import 'package:flutter/material.dart';

import '../../../core/constants/audio_constants.dart';
import '../../../shared/theme/app_theme.dart';

/// Barra de nivel con gradiente y marcas de referencia.
class DbLevelBar extends StatelessWidget {
  final double db;

  const DbLevelBar({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    final fraction = ((db - AudioConstants.minDb) /
            (AudioConstants.maxDb - AudioConstants.minDb))
        .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra con gradiente.
          Stack(
            children: [
              // Fondo de la barra.
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Barra de progreso con gradiente.
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 100),
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.levelQuiet,
                        AppTheme.levelModerate,
                        AppTheme.levelLoud,
                        AppTheme.levelDangerous,
                      ],
                      stops: [0.0, 0.4, 0.65, 0.85],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Marcas de referencia.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ReferenceLabel(
                db: 30,
                label: 'Silencio',
                fraction: _fractionForDb(30),
              ),
              _ReferenceLabel(
                db: 50,
                label: 'Conversación',
                fraction: _fractionForDb(50),
              ),
              _ReferenceLabel(
                db: 70,
                label: 'Tráfico',
                fraction: _fractionForDb(70),
              ),
              _ReferenceLabel(
                db: 85,
                label: 'Daño auditivo',
                fraction: _fractionForDb(85),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _fractionForDb(int targetDb) {
    return ((targetDb - AudioConstants.minDb) /
            (AudioConstants.maxDb - AudioConstants.minDb))
        .clamp(0.0, 1.0);
  }
}

class _ReferenceLabel extends StatelessWidget {
  final int db;
  final String label;
  final double fraction;

  const _ReferenceLabel({
    required this.db,
    required this.label,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$db',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

/// Widget que anima su widthFactor con [AnimatedContainer]-like behavior.
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final AlignmentGeometry alignment;
  final Widget? child;

  const AnimatedFractionallySizedBox({
    super.key,
    required super.duration,
    required this.widthFactor,
    this.alignment = Alignment.center,
    this.child,
    super.curve = Curves.linear,
  });

  @override
  AnimatedFractionallySizedBoxState createState() =>
      AnimatedFractionallySizedBoxState();
}

class AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: widget.alignment,
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      child: widget.child,
    );
  }
}
