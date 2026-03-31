import 'package:flutter/material.dart';

import '../../../core/constants/audio_constants.dart';
import '../../../shared/theme/app_theme.dart';

/// Barra animada que muestra el nivel actual de dB.
class DbLevelBar extends StatelessWidget {
  final double db;

  const DbLevelBar({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    // Normalizar el valor entre 0 y 1.
    final fraction = ((db - AudioConstants.minDb) /
            (AudioConstants.maxDb - AudioConstants.minDb))
        .clamp(0.0, 1.0);

    final color = AppTheme.colorForDb(db);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 100),
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.7),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AudioConstants.minDb.toInt()} dB',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                    ),
              ),
              Text(
                '${AudioConstants.maxDb.toInt()} dB',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ),
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
