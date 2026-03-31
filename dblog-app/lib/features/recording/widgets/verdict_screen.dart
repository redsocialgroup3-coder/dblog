import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/legal/legal_provider.dart';
import '../../../core/legal/models/verdict_result.dart';
import '../../../shared/theme/app_theme.dart';
import '../../history/widgets/history_screen.dart';

/// Pantalla de veredicto post-grabacion.
/// Muestra el resultado de la medicion comparado con el limite legal,
/// incluyendo municipio detectado, franja horaria y normativa aplicable.
class VerdictScreen extends StatefulWidget {
  final double avgDb;
  final double maxDb;
  final int durationSeconds;

  const VerdictScreen({
    super.key,
    required this.avgDb,
    required this.maxDb,
    required this.durationSeconds,
  });

  @override
  State<VerdictScreen> createState() => _VerdictScreenState();
}

class _VerdictScreenState extends State<VerdictScreen> {
  VerdictResult? _verdict;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVerdict();
  }

  Future<void> _loadVerdict() async {
    final legalProvider = context.read<LegalProvider>();
    legalProvider.refreshTimePeriod();
    final result = await legalProvider.getVerdict(widget.avgDb);
    if (mounted) {
      setState(() {
        _verdict = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Header.
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        const Text(
                          'Resultado',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Municipio y franja horaria.
                    _LegalInfoBar(verdict: _verdict),
                    const Spacer(),
                    // Veredicto principal.
                    if (_verdict != null) ...[
                      _VerdictBadge(verdict: _verdict!.verdict),
                      const SizedBox(height: 32),
                      // Comparacion dB medido vs limite.
                      _ComparisonCard(
                        avgDb: widget.avgDb,
                        maxDb: widget.maxDb,
                        legalLimit: _verdict!.limitDb,
                        verdict: _verdict!.verdict,
                        differenceDb: _verdict!.differenceDb,
                      ),
                    ] else ...[
                      _VerdictBadgeFallback(avgDb: widget.avgDb),
                      const SizedBox(height: 32),
                      _FallbackComparisonCard(
                        avgDb: widget.avgDb,
                        maxDb: widget.maxDb,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Normativa aplicable.
                    if (_verdict != null)
                      _RegulationCard(verdict: _verdict!),
                    const SizedBox(height: 16),
                    // Duracion de la grabacion.
                    _InfoCard(
                      icon: Icons.timer_outlined,
                      label: 'Duracion',
                      value: _formatDuration(widget.durationSeconds),
                    ),
                    const Spacer(),
                    // Botones de accion.
                    _buildActions(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Generar informe PDF (deshabilitado).
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Generar informe PDF (proximamente)'),
          ),
        ),
        const SizedBox(height: 12),
        // Ver en historial.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
            label: const Text('Ver en historial'),
          ),
        ),
        const SizedBox(height: 12),
        // Nueva medicion.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Nueva medicion'),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins min ${secs}s';
    }
    return '${secs}s';
  }
}

class _LegalInfoBar extends StatelessWidget {
  final VerdictResult? verdict;

  const _LegalInfoBar({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final legalProvider = context.watch<LegalProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              size: 16, color: AppTheme.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              verdict?.municipality ?? legalProvider.municipality ?? 'Sin ubicacion',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: AppTheme.surfaceLight,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.schedule_outlined,
              size: 16, color: AppTheme.warning),
          const SizedBox(width: 4),
          Text(
            verdict?.timePeriod ?? legalProvider.timePeriod,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictBadge extends StatelessWidget {
  final VerdictType verdict;

  const _VerdictBadge({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final (color, icon, title, subtitle) = switch (verdict) {
      VerdictType.supera => (
          AppTheme.danger,
          Icons.warning_rounded,
          'SUPERA EL LIMITE',
          'El nivel de ruido medido supera el limite legal',
        ),
      VerdictType.cercano => (
          AppTheme.warning,
          Icons.error_outline_rounded,
          'CERCANO AL LIMITE',
          'El nivel de ruido esta cerca del limite legal',
        ),
      VerdictType.noSupera => (
          AppTheme.success,
          Icons.check_circle_outline_rounded,
          'NO SUPERA',
          'El nivel de ruido no supera el limite legal',
        ),
    };

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 3,
            ),
          ),
          child: Icon(icon, color: color, size: 48),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VerdictBadgeFallback extends StatelessWidget {
  final double avgDb;

  const _VerdictBadgeFallback({required this.avgDb});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.textSecondary.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.gavel_rounded,
              color: AppTheme.textSecondary, size: 48),
        ),
        const SizedBox(height: 20),
        Text(
          '${avgDb.toStringAsFixed(1)} dB',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'No se pudo determinar la normativa aplicable',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final double avgDb;
  final double maxDb;
  final double legalLimit;
  final VerdictType verdict;
  final double differenceDb;

  const _ComparisonCard({
    required this.avgDb,
    required this.maxDb,
    required this.legalLimit,
    required this.verdict,
    required this.differenceDb,
  });

  @override
  Widget build(BuildContext context) {
    final verdictColor = switch (verdict) {
      VerdictType.supera => AppTheme.danger,
      VerdictType.cercano => AppTheme.warning,
      VerdictType.noSupera => AppTheme.success,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        border: Border.all(
          color: verdictColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Fila: Promedio medido vs Limite legal.
          Row(
            children: [
              Expanded(
                child: _DbValueColumn(
                  label: 'Promedio medido',
                  value: avgDb,
                  color: verdictColor,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppTheme.surfaceLight,
              ),
              Expanded(
                child: _DbValueColumn(
                  label: 'Limite legal',
                  value: legalLimit,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.surfaceLight, height: 1),
          const SizedBox(height: 16),
          // Diferencia y pico maximo.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Diferencia.
              Row(
                children: [
                  Icon(
                    differenceDb >= 0
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: verdictColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Diferencia: ',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${differenceDb >= 0 ? '+' : ''}${differenceDb.toStringAsFixed(1)} dB',
                    style: TextStyle(
                      color: verdictColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // Pico maximo.
              Row(
                children: [
                  const Icon(
                    Icons.arrow_upward_rounded,
                    color: AppTheme.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Pico: ',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${maxDb.toStringAsFixed(1)} dB',
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FallbackComparisonCard extends StatelessWidget {
  final double avgDb;
  final double maxDb;

  const _FallbackComparisonCard({
    required this.avgDb,
    required this.maxDb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DbValueColumn(
            label: 'Promedio',
            value: avgDb,
            color: AppTheme.textPrimary,
          ),
          Container(width: 1, height: 50, color: AppTheme.surfaceLight),
          _DbValueColumn(
            label: 'Pico maximo',
            value: maxDb,
            color: AppTheme.danger,
          ),
        ],
      ),
    );
  }
}

class _RegulationCard extends StatelessWidget {
  final VerdictResult verdict;

  const _RegulationCard({required this.verdict});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_rounded,
              color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict.regulationName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (verdict.article != null)
                  Text(
                    verdict.article!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DbValueColumn extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _DbValueColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'dB',
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
