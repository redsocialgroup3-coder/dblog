import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

/// Widget reutilizable de slider para configurar el umbral de detección en dB.
///
/// Muestra un slider con rango 20-80 dB, una marca visual del límite legal
/// del municipio como referencia, el valor actual y un botón para resetear
/// al límite legal.
class ThresholdSlider extends StatelessWidget {
  /// Valor actual del umbral en dB.
  final double value;

  /// Límite legal del municipio en dB (usado como referencia visual).
  final double legalLimit;

  /// Callback cuando el usuario cambia el valor del slider.
  final ValueChanged<double> onChanged;

  /// Callback cuando el usuario presiona "Resetear al límite legal".
  final VoidCallback onReset;

  /// Rango mínimo del slider.
  static const double minThreshold = 20.0;

  /// Rango máximo del slider.
  static const double maxThreshold = 80.0;

  const ThresholdSlider({
    super.key,
    required this.value,
    required this.legalLimit,
    required this.onChanged,
    required this.onReset,
  });

  /// Retorna el color del umbral según su relación con el límite legal.
  Color _thresholdColor() {
    final diff = value - legalLimit;
    if (diff < -5) return AppTheme.success;
    if (diff <= 5) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final color = _thresholdColor();
    final isAtLegalLimit = (value - legalLimit).abs() < 0.5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título y valor actual.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Umbral: ${value.round()} dB',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSm),
                ),
                child: Text(
                  'Límite legal: ${legalLimit.round()} dB',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slider con marca visual del límite legal.
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Slider principal.
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: color,
                      inactiveTrackColor: AppTheme.surfaceLight,
                      thumbColor: color,
                      overlayColor: color.withValues(alpha: 0.2),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: minThreshold,
                      max: maxThreshold,
                      divisions: ((maxThreshold - minThreshold)).round(),
                      onChanged: onChanged,
                    ),
                  ),

                  // Marca vertical del límite legal.
                  if (legalLimit >= minThreshold &&
                      legalLimit <= maxThreshold)
                    Positioned(
                      left: _legalLimitPosition(constraints.maxWidth),
                      top: 8,
                      child: Container(
                        width: 2,
                        height: 32,
                        color: AppTheme.chartLegalLimit.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              );
            },
          ),

          // Etiquetas de rango.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '20 dB',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '80 dB',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Botón resetear al límite legal.
          if (!isAtLegalLimit)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Resetear al límite legal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.surfaceLight),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSm),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Calcula la posición horizontal de la marca del límite legal.
  ///
  /// El slider de Material tiene un padding interno de ~24px a cada lado.
  double _legalLimitPosition(double totalWidth) {
    const sliderPadding = 24.0;
    final trackWidth = totalWidth - (sliderPadding * 2);
    final fraction =
        (legalLimit - minThreshold) / (maxThreshold - minThreshold);
    return sliderPadding + (trackWidth * fraction);
  }
}
