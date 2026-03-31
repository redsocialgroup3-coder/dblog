import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/audio_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/db_reading.dart';

/// Gráfica en tiempo real de los últimos 60 segundos de lecturas de dB.
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
    final spots = _buildSpots();

    // Calcular el rango del eje X.
    double maxX = AudioConstants.chartWindowSeconds.toDouble();
    if (spots.isNotEmpty && spots.last.x > maxX) {
      maxX = spots.last.x;
    }
    final minX = (maxX - AudioConstants.chartWindowSeconds).clamp(0.0, maxX);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 200,
        padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
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
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots.isEmpty ? [const FlSpot(0, 30)] : spots,
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
          // CRÍTICO: duration zero para evitar animaciones costosas.
          duration: Duration.zero,
        ),
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
