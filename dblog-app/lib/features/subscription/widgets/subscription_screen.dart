import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/payments/payment_provider.dart';
import '../../../shared/theme/app_theme.dart';

/// Pantalla de suscripción Pro con beneficios, comparativa y gestión.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar offerings al entrar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentProvider>();
      provider.loadOfferings();
      provider.checkEntitlements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripción Pro'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: Consumer<PaymentProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado actual si es suscriptor.
                if (provider.isSubscriber) ...[
                  _buildActiveSubscriptionCard(provider),
                  const SizedBox(height: 24),
                ],

                // Header con beneficios.
                _buildBenefitsHeader(),
                const SizedBox(height: 24),

                // Comparativa Free vs Pro.
                _buildComparisonTable(),
                const SizedBox(height: 24),

                // Precio y botón de suscripción.
                if (!provider.isSubscriber) ...[
                  _buildPriceCard(provider),
                  const SizedBox(height: 16),
                ],

                // Restaurar compras.
                _buildRestoreButton(provider),
                const SizedBox(height: 16),

                // Error.
                if (provider.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMd),
                      border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: const TextStyle(
                              color: AppTheme.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: AppTheme.danger, size: 16),
                          onPressed: provider.clearError,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(PaymentProvider provider) {
    final expirationDate = provider.subscriptionExpirationDate;
    final willRenew = provider.subscriptionWillRenew;

    String renewalText;
    if (expirationDate != null) {
      final dateStr =
          '${expirationDate.day}/${expirationDate.month}/${expirationDate.year}';
      renewalText = willRenew
          ? 'Se renueva el $dateStr'
          : 'Expira el $dateStr';
    } else {
      renewalText = 'Suscripción activa';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.2),
            AppTheme.accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSm),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.check_circle, color: AppTheme.accent, size: 20),
              const SizedBox(width: 6),
              const Text(
                'Suscripción activa',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            renewalText,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => provider.openManagementUrl(),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Gestionar suscripción'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Funciones Pro',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Desbloquea todo el potencial de dBLog',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        _buildBenefitItem(
          icon: Icons.nightlight_round,
          title: 'Vigilancia nocturna automática',
          description: 'Monitoreo continuo mientras duermes',
        ),
        _buildBenefitItem(
          icon: Icons.history_rounded,
          title: 'Historial ilimitado de grabaciones',
          description: 'Sin límite de 5 grabaciones',
        ),
        _buildBenefitItem(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Informes PDF ilimitados',
          description: 'Genera todos los informes que necesites',
        ),
        _buildBenefitItem(
          icon: Icons.ios_share_rounded,
          title: 'Exportación completa de evidencia',
          description: 'Audio + metadatos + informe legal',
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          // Cabecera.
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.borderRadiusMd),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Función',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Free',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Pro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildComparisonRow('Medidor de dB', true, true),
          _buildComparisonRow('Grabación de audio', true, true),
          _buildComparisonRow('Historial', false, true, freeNote: '5 máx'),
          _buildComparisonRow('Vigilancia nocturna', false, true),
          _buildComparisonRow('PDFs ilimitados', false, true),
          _buildComparisonRow('Exportar evidencia', false, true),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    bool free,
    bool pro, {
    String? freeNote,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: freeNote != null
                  ? Text(
                      freeNote,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    )
                  : Icon(
                      free ? Icons.check_rounded : Icons.close_rounded,
                      color: free ? AppTheme.accent : AppTheme.textSecondary,
                      size: 18,
                    ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                pro ? Icons.check_rounded : Icons.close_rounded,
                color: pro ? AppTheme.accent : AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(PaymentProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.15),
            AppTheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'dBLog Pro',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: '2,99\u20AC',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' /mes',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cancela cuando quieras',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isProcessingPurchase
                  ? null
                  : () => _handleSubscribe(provider),
              icon: provider.isProcessingPurchase
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  : const Icon(Icons.star_rounded),
              label: Text(
                provider.isProcessingPurchase
                    ? 'Procesando...'
                    : 'Suscribirse',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreButton(PaymentProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: provider.isProcessingPurchase
            ? null
            : () => _handleRestore(provider),
        icon: provider.isProcessingPurchase
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.restore_rounded, size: 20),
        label: const Text('Restaurar compras'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
          side: const BorderSide(color: AppTheme.surfaceLight),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _handleSubscribe(PaymentProvider provider) async {
    final success = await provider.purchaseSubscription();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suscripción activada correctamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _handleRestore(PaymentProvider provider) async {
    await provider.restorePurchases();

    if (!mounted) return;

    if (provider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.isSubscriber
                ? 'Compras restauradas - Suscripción Pro activa'
                : 'No se encontraron compras anteriores',
          ),
          backgroundColor:
              provider.isSubscriber ? AppTheme.success : AppTheme.warning,
        ),
      );
    }
  }
}
