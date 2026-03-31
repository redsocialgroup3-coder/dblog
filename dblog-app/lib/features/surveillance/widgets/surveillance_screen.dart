import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/payments/payment_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../subscription/widgets/subscription_screen.dart';
import '../providers/surveillance_provider.dart';
import 'surveillance_event_tile.dart';
import 'surveillance_status_indicator.dart';
import 'threshold_slider.dart';

/// Pantalla principal de vigilancia nocturna.
///
/// Muestra tres estados:
/// - No suscriptor: paywall con mensaje y redirección a suscripción.
/// - Suscriptor con vigilancia inactiva: configuración (slider + botón activar).
/// - Vigilancia activa: indicador de estado, dB actual, lista de eventos.
class SurveillanceScreen extends StatelessWidget {
  const SurveillanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vigilancia nocturna'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer2<PaymentProvider, SurveillanceProvider>(
        builder: (context, paymentProvider, surveillanceProvider, _) {
          // Si no es suscriptor: mostrar paywall.
          if (!paymentProvider.isSubscriber) {
            return _PaywallView(
              onSubscribe: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              },
            );
          }

          // Si vigilancia activa: mostrar estado activo.
          if (surveillanceProvider.isActive) {
            return _ActiveView(provider: surveillanceProvider);
          }

          // Vigilancia inactiva: mostrar configuración.
          return _ConfigView(provider: surveillanceProvider);
        },
      ),
    );
  }
}

/// Vista de paywall para no suscriptores.
class _PaywallView extends StatelessWidget {
  final VoidCallback onSubscribe;

  const _PaywallView({required this.onSubscribe});

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
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.shield_moon_rounded,
                  size: 48,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Vigilancia nocturna',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Monitorea el ruido mientras duermes. La app escuchará '
                'continuamente y grabará automáticamente cuando se supere '
                'el umbral configurado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMd),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.hearing_rounded,
                      text: 'Detección automática de picos',
                    ),
                    SizedBox(height: 10),
                    _FeatureRow(
                      icon: Icons.fiber_manual_record_rounded,
                      text: 'Grabación automática de eventos',
                    ),
                    SizedBox(height: 10),
                    _FeatureRow(
                      icon: Icons.notifications_active_rounded,
                      text: 'Notificaciones en tiempo real',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSubscribe,
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('Ver planes de suscripción'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// Vista de configuración (vigilancia inactiva).
class _ConfigView extends StatelessWidget {
  final SurveillanceProvider provider;

  const _ConfigView({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensaje de error si existe.
            if (provider.errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSm),
                  border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppTheme.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: provider.clearError,
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.danger, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Slider de umbral.
            ThresholdSlider(
              value: provider.threshold,
              legalLimit: provider.legalLimit,
              onChanged: (value) => provider.setThreshold(value),
              onReset: () => provider.resetThresholdToLegal(),
            ),
            const SizedBox(height: 20),

            // Información sobre la vigilancia.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius:
                    BorderRadius.circular(AppTheme.borderRadiusSm),
                border: Border.all(
                  color: AppTheme.surfaceLight,
                  width: 1,
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.textSecondary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La vigilancia escuchará continuamente y grabará '
                      'automáticamente cuando el ruido supere el umbral.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón activar vigilancia.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => provider.start(),
                icon: const Icon(Icons.shield_moon_rounded, size: 22),
                label: const Text('Activar vigilancia'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista de vigilancia activa.
class _ActiveView extends StatelessWidget {
  final SurveillanceProvider provider;

  const _ActiveView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final events = provider.eventsDetected;

    return SafeArea(
      child: Column(
        children: [
          // Indicador de estado.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SurveillanceStatusIndicator(
              isRecording: provider.isRecording,
              currentDb: provider.currentDb,
              threshold: provider.threshold,
              sessionDurationSeconds: provider.totalDurationSeconds,
            ),
          ),

          // Lista de eventos detectados.
          Expanded(
            child: events.isEmpty
                ? const _EmptyEventsView()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: events.length + 1, // +1 para el header.
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              top: 8, bottom: 8),
                          child: Text(
                            'Eventos detectados (${events.length})',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      final event = events[events.length - index];
                      return SurveillanceEventTile(
                        event: event,
                        onTap: event.recordingId != null
                            ? () {
                                // TODO: navegar a detalle de grabación.
                              }
                            : null,
                      );
                    },
                  ),
          ),

          // Botón detener.
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final events = await provider.stop();
                  if (context.mounted && events.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Vigilancia detenida. ${events.length} evento(s) detectado(s).',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.stop_rounded, size: 22),
                label: const Text('Detener vigilancia'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista cuando no hay eventos detectados aún.
class _EmptyEventsView extends StatelessWidget {
  const _EmptyEventsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hearing_rounded,
            size: 40,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'Sin eventos detectados',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Los eventos aparecerán aquí cuando\nel ruido supere el umbral',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
