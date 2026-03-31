import 'package:flutter/material.dart';

import '../../features/legal/widgets/privacy_policy_screen.dart';
import '../../shared/theme/app_theme.dart';
import 'gdpr_service.dart';

/// Dialogo de consentimiento RGPD.
///
/// Se muestra al primer uso despues del onboarding.
/// Requiere aceptar la politica de privacidad para continuar.
class ConsentDialog extends StatefulWidget {
  const ConsentDialog({super.key});

  /// Muestra el dialogo si el usuario no ha dado consentimiento aun.
  /// Retorna true si el usuario acepto, false si cancelo.
  static Future<bool> showIfNeeded(BuildContext context) async {
    final hasConsented = await GdprService.instance.hasConsented();
    if (hasConsented) return true;

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ConsentDialog(),
    );

    return result ?? false;
  }

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  bool _privacyAccepted = false;
  bool _microphoneConsent = false;
  bool _locationConsent = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text(
        'Consentimiento de privacidad',
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para usar dBLog necesitamos tu consentimiento:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Politica de privacidad (obligatorio).
            CheckboxListTile(
              value: _privacyAccepted,
              onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppTheme.accent,
              contentPadding: EdgeInsets.zero,
              title: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Acepto la ',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                      TextSpan(
                        text: 'politica de privacidad',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppTheme.danger, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Microfono (recomendado).
            CheckboxListTile(
              value: _microphoneConsent,
              onChanged: (v) => setState(() => _microphoneConsent = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppTheme.accent,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Consiento el uso del microfono para medicion de ruido',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
              subtitle: const Text(
                'Recomendado',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),

            // Ubicacion (recomendado).
            CheckboxListTile(
              value: _locationConsent,
              onChanged: (v) => setState(() => _locationConsent = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppTheme.accent,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Consiento el uso de ubicacion para normativa local',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
              subtitle: const Text(
                'Recomendado',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              '* Obligatorio para usar la app',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _privacyAccepted
              ? () async {
                  await GdprService.instance.saveConsent(
                    privacyAccepted: _privacyAccepted,
                    microphoneConsent: _microphoneConsent,
                    locationConsent: _locationConsent,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                }
              : null,
          child: Text(
            'Aceptar y continuar',
            style: TextStyle(
              color: _privacyAccepted
                  ? AppTheme.accent
                  : AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
