import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../history/providers/history_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../recording/models/recording.dart';
import '../models/report_request.dart';
import '../providers/report_provider.dart';
import 'pdf_preview_screen.dart';

/// Pantalla con formulario de datos del inmueble para generar un informe PDF.
/// Permite seleccionar grabaciones, rellenar datos del inmueble y generar
/// la vista previa del informe.
class ReportFormScreen extends StatefulWidget {
  /// Grabación pre-seleccionada (cuando se navega desde detalle).
  final Recording? preselectedRecording;

  const ReportFormScreen({super.key, this.preselectedRecording});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _floorDoorController = TextEditingController();
  final _reporterNameController = TextEditingController();

  String _selectedZoneType = 'residencial';
  final Set<String> _selectedRecordingIds = {};

  static const _zoneTypes = <String, String>{
    'residencial': 'Residencial',
    'industrial': 'Industrial',
    'sanitario': 'Sanitario',
    'educativo': 'Educativo',
    'recreativo': 'Recreativo / Ocio',
  };

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
    if (widget.preselectedRecording != null) {
      _selectedRecordingIds.add(widget.preselectedRecording!.id);
    }
  }

  void _prefillFromProfile() {
    final profile = context.read<ProfileProvider>();
    if (profile.address != null && profile.address!.isNotEmpty) {
      _addressController.text = profile.address!;
    }
    if (profile.floorDoor != null && profile.floorDoor!.isNotEmpty) {
      _floorDoorController.text = profile.floorDoor!;
    }
    if (profile.displayName != null && profile.displayName!.isNotEmpty) {
      _reporterNameController.text = profile.displayName!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _floorDoorController.dispose();
    _reporterNameController.dispose();
    super.dispose();
  }

  Future<void> _generatePreview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRecordingIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una grabación'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final request = ReportRequest(
      recordingIds: _selectedRecordingIds.toList(),
      address: _addressController.text.trim(),
      floorDoor: _floorDoorController.text.trim(),
      zoneType: _selectedZoneType,
      reporterName: _reporterNameController.text.trim(),
    );

    final reportProvider = context.read<ReportProvider>();
    await reportProvider.generatePreview(request);

    if (!mounted) return;

    if (reportProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reportProvider.error!),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (reportProvider.previewPdfPath != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            pdfPath: reportProvider.previewPdfPath!,
            reportRequest: request,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final reportProvider = context.watch<ReportProvider>();
    final recordings = historyProvider.recordings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar informe'),
      ),
      body: SafeArea(
        child: reportProvider.isGenerating
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Generando vista previa...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección: Datos del inmueble.
                      const _SectionTitle(title: 'Datos del inmueble'),
                      const SizedBox(height: 12),

                      // Dirección.
                      TextFormField(
                        controller: _addressController,
                        decoration: _inputDecoration(
                          label: 'Dirección',
                          hint: 'Calle, número, ciudad...',
                          icon: Icons.location_on_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La dirección es obligatoria';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Piso y puerta.
                      TextFormField(
                        controller: _floorDoorController,
                        decoration: _inputDecoration(
                          label: 'Piso / Puerta',
                          hint: '3º B',
                          icon: Icons.door_front_door_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tipo de zona.
                      DropdownButtonFormField<String>(
                        initialValue: _selectedZoneType,
                        decoration: _inputDecoration(
                          label: 'Tipo de zona',
                          icon: Icons.map_outlined,
                        ),
                        dropdownColor: AppTheme.surface,
                        items: _zoneTypes.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedZoneType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Nombre del denunciante.
                      TextFormField(
                        controller: _reporterNameController,
                        decoration: _inputDecoration(
                          label: 'Nombre del denunciante (opcional)',
                          hint: 'Tu nombre',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sección: Grabaciones.
                      const _SectionTitle(title: 'Grabaciones a incluir'),
                      const SizedBox(height: 8),

                      if (recordings.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadiusMd),
                          ),
                          child: const Text(
                            'No hay grabaciones disponibles.\n'
                            'Realiza una medición primero.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        ...recordings.map((recording) {
                          final isSelected =
                              _selectedRecordingIds.contains(recording.id);
                          final date = recording.timestamp.toLocal();
                          final dateStr =
                              '${date.day.toString().padLeft(2, '0')}/'
                              '${date.month.toString().padLeft(2, '0')}/'
                              '${date.year}';
                          final timeStr =
                              '${date.hour.toString().padLeft(2, '0')}:'
                              '${date.minute.toString().padLeft(2, '0')}';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedRecordingIds.remove(recording.id);
                                  } else {
                                    _selectedRecordingIds.add(recording.id);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusMd,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMd,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.surfaceLight,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            _selectedRecordingIds
                                                .add(recording.id);
                                          } else {
                                            _selectedRecordingIds
                                                .remove(recording.id);
                                          }
                                        });
                                      },
                                      activeColor: AppTheme.primary,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$dateStr  $timeStr',
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Prom: ${recording.avgDb.toStringAsFixed(1)} dB  '
                                            'Máx: ${recording.maxDb.toStringAsFixed(1)} dB  '
                                            '${_formatDuration(recording.durationSeconds)}',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.colorForDb(
                                            recording.avgDb),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 24),

                      // Botón generar vista previa.
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generatePreview,
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('Generar vista previa'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
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
        borderSide: const BorderSide(color: AppTheme.primary),
      ),
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      hintStyle: TextStyle(
        color: AppTheme.textSecondary.withValues(alpha: 0.5),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) return '${mins}m ${secs}s';
    return '${secs}s';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
