import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/gdpr/gdpr_service.dart';
import '../../../core/payments/payment_provider.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/widgets/login_screen.dart';
import '../../legal/widgets/privacy_policy_screen.dart';
import '../../legal/widgets/terms_screen.dart';
import '../../subscription/widgets/subscription_screen.dart';
import '../providers/profile_provider.dart';

/// Pantalla de perfil y ajustes del usuario.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _addressController;
  late TextEditingController _floorDoorController;
  late TextEditingController _municipalityController;
  late double _dbThreshold;
  late double _calibrationOffset;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _addressController = TextEditingController();
    _floorDoorController = TextEditingController();
    _municipalityController = TextEditingController();
    _dbThreshold = 65.0;
    _calibrationOffset = 0.0;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _addressController.dispose();
    _floorDoorController.dispose();
    _municipalityController.dispose();
    super.dispose();
  }

  void _initFromProfile(ProfileProvider provider) {
    if (!_initialized) {
      _displayNameController.text = provider.displayName ?? '';
      _addressController.text = provider.address ?? '';
      _floorDoorController.text = provider.floorDoor ?? '';
      _municipalityController.text = provider.municipality ?? '';
      _dbThreshold = provider.dbThreshold;
      _calibrationOffset = provider.calibrationOffset;
      _initialized = true;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProfileProvider>();
    final saved = await provider.updateProfile(
      displayName: _displayNameController.text.trim(),
      address: _addressController.text.trim(),
      floorDoor: _floorDoorController.text.trim(),
      municipality: _municipalityController.text.trim(),
      dbThreshold: _dbThreshold,
      calibrationOffset: _calibrationOffset,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Perfil guardado' : (provider.errorMessage ?? 'Guardado localmente'),
        ),
        backgroundColor: saved ? AppTheme.accent : AppTheme.warning,
      ),
    );
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(onSkip: () {
          Navigator.of(context).pop();
        }),
      ),
      (route) => false,
    );
  }

  Future<void> _exportData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exportando datos...'),
          backgroundColor: AppTheme.accent,
        ),
      );

      final filePath = await GdprService.instance.requestDataExport();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos exportados correctamente'),
          backgroundColor: AppTheme.accent,
        ),
      );

      // Compartir el archivo exportado.
      await Share.shareXFiles([XFile(filePath)], text: 'Exportacion de datos dBLog');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar datos: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    // Primera confirmacion.
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Se eliminaran todos tus datos de forma permanente, '
          'incluyendo grabaciones, informes y perfil. '
          'Esta accion no se puede deshacer.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted) return;

    // Segunda confirmacion (doble confirmacion RGPD).
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Confirmar eliminacion',
          style: TextStyle(color: AppTheme.danger),
        ),
        content: const Text(
          'Esta es tu ultima oportunidad. '
          'Todos tus datos seran eliminados permanentemente del servidor y del dispositivo. '
          'No podras recuperarlos.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );

    if (secondConfirm != true || !mounted) return;

    try {
      await GdprService.instance.deleteAllData();
      if (!mounted) return;
      await _logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar la cuenta: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil y ajustes'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          _initFromProfile(provider);

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seccion: Datos personales.
                  _buildSectionTitle('Datos personales'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _displayNameController,
                    label: 'Nombre',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildReadOnlyField(
                    value: context.read<AuthProvider>().user?.email ?? 'No disponible',
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 24),

                  // Seccion: Inmueble.
                  _buildSectionTitle('Inmueble'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Direccion',
                    icon: Icons.home_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _floorDoorController,
                    label: 'Piso / Puerta',
                    icon: Icons.door_front_door_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _municipalityController,
                    label: 'Municipio',
                    icon: Icons.location_city_outlined,
                  ),

                  const SizedBox(height: 24),

                  // Seccion: Preferencias.
                  _buildSectionTitle('Preferencias'),
                  const SizedBox(height: 12),
                  _buildThresholdSlider(),
                  const SizedBox(height: 12),
                  _buildCalibrationDisplay(),

                  const SizedBox(height: 32),

                  // Boton guardar.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _saveProfile,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar cambios'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Seccion: Sincronizacion.
                  _buildSyncSection(),

                  const SizedBox(height: 32),

                  // Seccion: Suscripcion.
                  _buildSubscriptionSection(),

                  const SizedBox(height: 32),

                  // Seccion: Legal.
                  _buildSectionTitle('Legal'),
                  const SizedBox(height: 12),
                  _buildLegalLink(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Política de privacidad',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLegalLink(
                    icon: Icons.description_outlined,
                    label: 'Términos de uso',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TermsScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Seccion: Cuenta y datos (RGPD).
                  _buildSectionTitle('Cuenta y datos'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _exportData,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Exportar mis datos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: const BorderSide(color: AppTheme.accent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesion'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.surfaceLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Eliminar cuenta y datos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncSection() {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, _) {
        final lastSync = syncProvider.lastSyncTime;
        final lastSyncText = lastSync != null
            ? '${lastSync.day}/${lastSync.month}/${lastSync.year} ${lastSync.hour}:${lastSync.minute.toString().padLeft(2, '0')}'
            : 'Nunca';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Sincronizacion'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                border: Border.all(color: AppTheme.surfaceLight),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        syncProvider.isOnline
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        color: syncProvider.isOnline
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              syncProvider.isOnline ? 'Conectado' : 'Sin conexion',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ultima sync: $lastSyncText',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (syncProvider.pendingUploads > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${syncProvider.pendingUploads} pendientes',
                            style: const TextStyle(
                              color: AppTheme.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: syncProvider.isSyncing
                          ? null
                          : () => syncProvider.syncAll(),
                      icon: syncProvider.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(
                        syncProvider.isSyncing
                            ? 'Sincronizando...'
                            : 'Sincronizar ahora',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: const BorderSide(color: AppTheme.accent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (syncProvider.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      syncProvider.errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionSection() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        final isSubscriber = paymentProvider.isSubscriber;
        final expirationDate = paymentProvider.subscriptionExpirationDate;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Suscripción'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                border: Border.all(color: AppTheme.surfaceLight),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isSubscriber ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isSubscriber ? AppTheme.accent : AppTheme.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSubscriber ? 'Plan Pro' : 'Plan Free',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isSubscriber && expirationDate != null)
                              Text(
                                'Renovación: ${expirationDate.day}/${expirationDate.month}/${expirationDate.year}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              )
                            else if (!isSubscriber)
                              const Text(
                                'Historial limitado a 5 grabaciones',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSubscriber
                              ? AppTheme.accent.withValues(alpha: 0.15)
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                        ),
                        child: Text(
                          isSubscriber ? 'PRO' : 'FREE',
                          style: TextStyle(
                            color: isSubscriber ? AppTheme.accent : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: isSubscriber
                        ? OutlinedButton.icon(
                            onPressed: () => paymentProvider.openManagementUrl(),
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            label: const Text('Gestionar suscripción'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accent,
                              side: const BorderSide(color: AppTheme.accent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SubscriptionScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.star_rounded, size: 18),
                            label: const Text('Ver planes'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppTheme.accent,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          borderSide: const BorderSide(color: AppTheme.surfaceLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          borderSide: const BorderSide(color: AppTheme.surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          borderSide: const BorderSide(color: AppTheme.accent),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      style: const TextStyle(color: AppTheme.textSecondary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          borderSide: const BorderSide(color: AppTheme.surfaceLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          borderSide: const BorderSide(color: AppTheme.surfaceLight),
        ),
      ),
    );
  }

  Widget _buildThresholdSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_up_outlined,
                  color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Umbral de dB',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${_dbThreshold.round()} dB',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.accent,
              inactiveTrackColor: AppTheme.surfaceLight,
              thumbColor: AppTheme.accent,
              overlayColor: AppTheme.accent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _dbThreshold,
              min: 30,
              max: 100,
              divisions: 70,
              onChanged: (value) {
                setState(() {
                  _dbThreshold = value;
                });
              },
            ),
          ),
          const Text(
            'Nivel a partir del cual se considera excesivo',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          border: Border.all(color: AppTheme.surfaceLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offset de calibracion',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ajusta desde el medidor (icono de calibracion)',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_calibrationOffset >= 0 ? '+' : ''}${_calibrationOffset.toStringAsFixed(1)} dB',
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
