import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

/// Pantalla de onboarding con PageView de 5 páginas.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  final _addressController = TextEditingController();
  final _floorController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _addressController.dispose();
    _floorController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<OnboardingProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // Botón saltar.
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => provider.skipOnboarding(),
                    child: Text(
                      'Saltar',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                // PageView.
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: provider.setPage,
                    children: [
                      _MeasurePage(),
                      _RecordPage(),
                      _ReportPage(),
                      _PermissionsPage(provider: provider),
                      _AddressPage(
                        addressController: _addressController,
                        floorController: _floorController,
                        cityController: _cityController,
                        provider: provider,
                      ),
                    ],
                  ),
                ),
                // Dots indicator.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      OnboardingProvider.totalPages,
                      (index) => _Dot(active: index == provider.currentPage),
                    ),
                  ),
                ),
                // Botón siguiente / comenzar.
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _onNextPressed(provider),
                      child: Text(
                        provider.currentPage ==
                                OnboardingProvider.totalPages - 1
                            ? 'Comenzar'
                            : 'Siguiente',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onNextPressed(OnboardingProvider provider) {
    if (provider.currentPage < OnboardingProvider.totalPages - 1) {
      provider.nextPage();
      _goToPage(provider.currentPage);
    } else {
      // Última página: guardar dirección y completar.
      provider.setAddress(_addressController.text.trim());
      provider.setFloor(_floorController.text.trim());
      provider.setCity(_cityController.text.trim());
      provider.completeOnboarding();
    }
  }
}

// -- Página 1: Mide el ruido --

class _MeasurePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _OnboardingPageContent(
      icon: Icons.mic,
      iconColor: AppTheme.primary,
      title: 'Mide el ruido',
      description:
          'Utiliza el micrófono de tu dispositivo para medir el nivel '
          'de decibelios en tiempo real. Visualiza las mediciones con '
          'gráficas claras y estadísticas precisas.',
    );
  }
}

// -- Página 2: Documenta la evidencia --

class _RecordPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _OnboardingPageContent(
      icon: Icons.fiber_manual_record,
      iconColor: Colors.red,
      title: 'Documenta la evidencia',
      description:
          'Graba audio con metadatos legales: fecha, hora, ubicación '
          'y niveles de decibelios. Toda la información que necesitas '
          'para respaldar tu denuncia.',
    );
  }
}

// -- Página 3: Genera informes legales --

class _ReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _OnboardingPageContent(
      icon: Icons.picture_as_pdf,
      iconColor: Colors.orange,
      title: 'Genera informes legales',
      description:
          'Crea informes en PDF con validez legal que incluyen '
          'todas las mediciones, grabaciones y metadatos. Listos '
          'para presentar ante las autoridades.',
    );
  }
}

// -- Página 4: Permisos --

class _PermissionsPage extends StatelessWidget {
  final OnboardingProvider provider;

  const _PermissionsPage({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_outlined, size: 80, color: AppTheme.primary),
          const SizedBox(height: 24),
          const Text(
            'Permisos necesarios',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'dBLog necesita acceso a estos permisos para funcionar correctamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _PermissionTile(
            icon: Icons.mic,
            label: 'Micrófono',
            description: 'Para medir el nivel de ruido',
            granted: provider.microphoneGranted,
            onRequest: () => _requestMicrophone(context),
          ),
          const SizedBox(height: 12),
          _PermissionTile(
            icon: Icons.location_on,
            label: 'Ubicación',
            description: 'Para geolocalizar las mediciones',
            granted: provider.locationGranted,
            onRequest: () => _requestLocation(context),
          ),
          const SizedBox(height: 12),
          _PermissionTile(
            icon: Icons.notifications,
            label: 'Notificaciones',
            description: 'Para alertas de grabación activa',
            granted: provider.notificationsGranted,
            onRequest: () => _requestNotifications(context),
          ),
        ],
      ),
    );
  }

  Future<void> _requestMicrophone(BuildContext context) async {
    final status = await Permission.microphone.request();
    if (context.mounted) {
      provider.setMicrophoneGranted(status.isGranted);
    }
  }

  Future<void> _requestLocation(BuildContext context) async {
    final status = await Permission.locationWhenInUse.request();
    if (context.mounted) {
      provider.setLocationGranted(status.isGranted);
    }
  }

  Future<void> _requestNotifications(BuildContext context) async {
    final status = await Permission.notification.request();
    if (context.mounted) {
      provider.setNotificationsGranted(status.isGranted);
    }
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool granted;
  final VoidCallback onRequest;

  const _PermissionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.granted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (granted)
            const Icon(Icons.check_circle, color: AppTheme.levelQuiet, size: 28)
          else
            TextButton(
              onPressed: onRequest,
              child: const Text('Permitir'),
            ),
        ],
      ),
    );
  }
}

// -- Página 5: Dirección del inmueble --

class _AddressPage extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController floorController;
  final TextEditingController cityController;
  final OnboardingProvider provider;

  const _AddressPage({
    required this.addressController,
    required this.floorController,
    required this.cityController,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.home_outlined, size: 80, color: AppTheme.primary),
            const SizedBox(height: 24),
            const Text(
              'Dirección del inmueble',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Indica la dirección donde realizarás las mediciones. '
              'Puedes configurarla después.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: addressController,
              label: 'Dirección',
              hint: 'Calle, número...',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: floorController,
              label: 'Piso / Puerta',
              hint: '2o B',
              icon: Icons.door_front_door_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: cityController,
              label: 'Municipio',
              hint: 'Madrid',
              icon: Icons.location_city_outlined,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}

// -- Contenido genérico de página de onboarding --

class _OnboardingPageContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _OnboardingPageContent({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: iconColor),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// -- Dot indicator --

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : AppTheme.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
