import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/legal/legal_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../history/widgets/history_screen.dart';
import '../../profile/widgets/profile_screen.dart';
import '../../recording/providers/recording_provider.dart';
import '../../recording/widgets/recording_overlay.dart';
import '../../recording/widgets/verdict_screen.dart';
import '../models/db_reading.dart';
import '../providers/meter_provider.dart';
import 'calibration_dialog.dart';
import 'db_chart.dart';
import 'db_display.dart';
import 'db_level_bar.dart';
import 'db_stats_row.dart';

/// Pantalla principal del medidor de decibelios.
class MeterScreen extends StatefulWidget {
  const MeterScreen({super.key});

  @override
  State<MeterScreen> createState() => _MeterScreenState();
}

class _MeterScreenState extends State<MeterScreen> {
  /// Controla si ya se navegó al veredicto para evitar navegación duplicada.
  bool _navigatedToVerdict = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MeterProvider>(
        builder: (context, provider, _) {
          // Si el permiso fue denegado permanentemente.
          if (provider.permissionDeniedPermanently) {
            return _PermissionDeniedView(
              onOpenSettings: provider.openAppSettings,
            );
          }

          // Mostrar error si lo hay.
          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage!),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: provider.clearError,
                  ),
                ),
              );
              provider.clearError();
            });
          }

          // Mostrar error de grabación si lo hay.
          final recordingProvider = context.read<RecordingProvider>();
          if (recordingProvider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(recordingProvider.errorMessage!),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: recordingProvider.clearError,
                  ),
                ),
              );
              recordingProvider.clearError();
            });
          }

          // Navegar al veredicto cuando se completa una grabación.
          _checkVerdictNavigation(context, recordingProvider);

          // Estado inicial: no se ha iniciado ninguna medición.
          if (!provider.hasStarted && !provider.isListening) {
            return _EmptyStateView(onStart: provider.start);
          }

          return SafeArea(
            child: Column(
              children: [
                // Header con título y acciones.
                _buildHeader(context, provider),
                // Info legal: municipio y límite.
                const _LegalInfoBanner(),
                // Overlay de grabación.
                const RecordingOverlay(),
                // Disclaimer de medición orientativa.
                const _DisclaimerBanner(),
                const SizedBox(height: 16),
                // Gauge de dB.
                DbDisplay(db: provider.currentDb),
                const SizedBox(height: 12),
                // Barra de nivel.
                DbLevelBar(db: provider.currentDb),
                const SizedBox(height: 16),
                // Estadísticas.
                DbStatsRow(
                  maxDb: provider.maxDb,
                  leq: provider.leq,
                ),
                const SizedBox(height: 16),
                // Gráfica.
                Expanded(
                  child: Selector<MeterProvider,
                      ({List<DbReading> readings, DateTime? start})>(
                    selector: (_, p) =>
                        (readings: p.readings, start: p.sessionStart),
                    builder: (_, data, _) => DbChart(
                      readings: data.readings,
                      sessionStart: data.start,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Botones de acción.
                _buildActionButtons(context),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  void _checkVerdictNavigation(
      BuildContext context, RecordingProvider recordingProvider) {
    if (recordingProvider.lastRecording != null && !_navigatedToVerdict) {
      // Solo navegar cuando el estado es idle (terminó de guardar).
      if (!recordingProvider.isRecording && !recordingProvider.isSaving) {
        _navigatedToVerdict = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final recording = recordingProvider.lastRecording!;
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (_) => VerdictScreen(
                avgDb: recording.avgDb,
                maxDb: recording.maxDb,
                durationSeconds: recording.durationSeconds,
              ),
            ),
          )
              .then((_) {
            _navigatedToVerdict = false;
          });
        });
      }
    }
  }

  Widget _buildHeader(BuildContext context, MeterProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text(
            'dBLog',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.textSecondary),
            tooltip: 'Calibración',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CalibrationDialog(
                  calibrationService: provider.calibrationService,
                  onChanged: provider.onCalibrationChanged,
                ),
              );
            },
          ),
          if (provider.isListening)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
              tooltip: 'Reiniciar',
              onPressed: provider.reset,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer2<MeterProvider, RecordingProvider>(
      builder: (context, meterProvider, recordingProvider, _) {
        final listening = meterProvider.isListening;
        final isRecording = recordingProvider.isRecording;
        final isSaving = recordingProvider.isSaving;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              // Botón start/stop medidor.
              Expanded(
                child: _ActionButton(
                  icon: listening ? Icons.stop_rounded : Icons.mic_rounded,
                  label: listening ? 'Detener' : 'Medir',
                  color: listening ? AppTheme.danger : AppTheme.accent,
                  onPressed: isRecording
                      ? null
                      : (listening ? meterProvider.stop : meterProvider.start),
                ),
              ),
              const SizedBox(width: 12),
              // Botón grabar.
              Expanded(
                child: _ActionButton(
                  icon: isRecording
                      ? Icons.stop_circle_rounded
                      : Icons.fiber_manual_record_rounded,
                  label: isSaving
                      ? 'Guardando...'
                      : (isRecording ? 'Parar grabación' : 'Grabar'),
                  color: isRecording ? AppTheme.danger : AppTheme.warning,
                  enabled: listening && !isSaving,
                  onPressed: (!listening || isSaving)
                      ? null
                      : (isRecording
                          ? recordingProvider.stopRecording
                          : recordingProvider.startRecording),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.surfaceLight, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.speed_rounded,
                label: 'Medidor',
                isActive: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'Historial',
                isActive: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Ajustes',
                isActive: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool enabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || onPressed == null;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppTheme.surfaceLight.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          border: Border.all(
            color: isDisabled
                ? AppTheme.surfaceLight
                : color.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDisabled ? AppTheme.textSecondary : color,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? AppTheme.textSecondary : color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.accent : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyStateView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo/icono.
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  size: 56,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Medidor de ruido',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Mide el nivel de ruido en decibelios y documenta si supera el límite legal de tu municipio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Comenzar medición'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _PermissionDeniedView({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.danger.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.mic_off_rounded,
                  size: 48,
                  color: AppTheme.danger,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Permiso de micrófono denegado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'dBLog necesita acceso al micrófono para medir el nivel de ruido. '
                'Abre la configuración para conceder el permiso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Abrir configuración'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Medicion orientativa - no sustituye sonometro homologado',
              style: TextStyle(fontSize: 11, color: AppTheme.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalInfoBanner extends StatelessWidget {
  const _LegalInfoBanner();

  @override
  Widget build(BuildContext context) {
    return Consumer<LegalProvider>(
      builder: (context, legal, _) {
        final municipality = legal.municipality;
        final limit = legal.currentLegalLimit;
        final timePeriod = legal.timePeriod;

        return GestureDetector(
          onTap: () => _showMunicipalitySelector(context, legal),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              border: Border.all(
                color: AppTheme.surfaceLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppTheme.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    municipality ?? 'Detectando...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (limit != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSm),
                    ),
                    child: Text(
                      '${limit.toInt()} dB',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  timePeriod,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppTheme.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMunicipalitySelector(
      BuildContext context, LegalProvider legal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MunicipalitySheet(legal: legal),
    );
  }
}

class _MunicipalitySheet extends StatelessWidget {
  final LegalProvider legal;

  const _MunicipalitySheet({required this.legal});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Seleccionar municipio',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (legal.isManualMunicipality)
                  TextButton.icon(
                    onPressed: () {
                      legal.resetToAutoDetect();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                    label: const Text('Auto-detectar'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Zone type selector.
            Row(
              children: [
                const Text('Zona: ',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(width: 8),
                _ZoneChip(
                  label: 'Residencial',
                  selected: legal.zoneType == 'residencial',
                  onTap: () => legal.setZoneType('residencial'),
                ),
                const SizedBox(width: 6),
                _ZoneChip(
                  label: 'Comercial',
                  selected: legal.zoneType == 'comercial',
                  onTap: () => legal.setZoneType('comercial'),
                ),
                const SizedBox(width: 6),
                _ZoneChip(
                  label: 'Industrial',
                  selected: legal.zoneType == 'industrial',
                  onTap: () => legal.setZoneType('industrial'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Noise type selector.
            Row(
              children: [
                const Text('Tipo: ',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(width: 8),
                _ZoneChip(
                  label: 'Exterior',
                  selected: legal.noiseType == 'exterior',
                  onTap: () => legal.setNoiseType('exterior'),
                ),
                const SizedBox(width: 6),
                _ZoneChip(
                  label: 'Interior',
                  selected: legal.noiseType == 'interior',
                  onTap: () => legal.setNoiseType('interior'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.surfaceLight),
            SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: legal.availableMunicipalities.length,
                itemBuilder: (context, index) {
                  final m = legal.availableMunicipalities[index];
                  final isSelected = m == legal.municipality;
                  return ListTile(
                    title: Text(
                      m,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: AppTheme.accent, size: 20)
                        : null,
                    onTap: () {
                      legal.setMunicipality(m);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ZoneChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.15)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          border: Border.all(
            color: selected
                ? AppTheme.accent.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? AppTheme.accent : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
