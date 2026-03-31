import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/audio_constants.dart';
import '../../../core/legal/legal_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/db_reading.dart';

/// Gráfica en tiempo real de los últimos 60 segundos de lecturas de dB.
/// Incluye línea de referencia del límite legal dinámico.
class DbChart extends StatelessWidget {
  final List<DbReading> readings;
  final DateTime? sessionStart;

  const DbChart({
    super.key,
    required this.readings,
    this.sessionStart,
  });

  @override
  Widget build(BuildContext context) {
    final legalProvider = context.watch<LegalProvider>();
    final legalLimit = legalProvider.currentLegalLimit ?? 65.0;

    final spots = _buildSpots();

    double maxX = AudioConstants.chartWindowSeconds.toDouble();
    if (spots.isNotEmpty && spots.last.x > maxX) {
      maxX = spots.last.x;
    }
    final minX = (maxX - AudioConstants.chartWindowSeconds).clamp(0.0, maxX);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la gráfica.
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Row(
              children: [
                const Text(
                  'Nivel de ruido',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Leyenda del límite legal.
                Container(
                  width: 12,
                  height: 2,
                  color: AppTheme.chartLegalLimit,
                ),
                const SizedBox(width: 4),
                Text(
                  'Límite legal (${legalLimit.toInt()} dB)',
                  style: TextStyle(
                    color: AppTheme.danger.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Gráfica.
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
              ),
              child: LineChart(
                LineChartData(
                  minY: AudioConstants.minDb,
                  maxY: AudioConstants.maxDb,
                  minX: minX,
                  maxX: maxX,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white10,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 15,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}s',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: legalLimit,
                        color: AppTheme.chartLegalLimit.withValues(alpha: 0.6),
                        strokeWidth: 2,
                        dashArray: [8, 4],
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          spots.isEmpty ? [const FlSpot(0, 30)] : spots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: AppTheme.chartLine,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.chartGradientTop,
                            AppTheme.chartGradientBottom,
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: const LineTouchData(enabled: false),
                ),
                duration: Duration.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    if (readings.isEmpty || sessionStart == null) return [];

    return readings.map((reading) {
      final secondsFromStart =
          reading.timestamp.difference(sessionStart!).inMilliseconds / 1000.0;
      return FlSpot(secondsFromStart, reading.db);
    }).toList();
  }
}
