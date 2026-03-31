import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../shared/theme/app_theme.dart';

/// Pantalla que muestra los términos y condiciones de uso desde el asset.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  Future<String> _loadTerms() async {
    return rootBundle.loadString('assets/legal/terms_of_service.md');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos de uso'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: FutureBuilder<String>(
        future: _loadTerms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'No se pudieron cargar los términos de uso.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildMarkdownContent(snapshot.data!),
          );
        },
      ),
    );
  }

  /// Renderiza el contenido Markdown de forma simplificada sin
  /// dependencias externas.
  Widget _buildMarkdownContent(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            line.substring(2),
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6),
          child: Text(
            line.substring(3),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(
            line.substring(4),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        final text = line.startsWith('- ')
            ? line.substring(2)
            : line.substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ',
                  style: TextStyle(
                      color: AppTheme.accent, fontSize: 14)),
              Expanded(
                child: Text(
                  text.replaceAll('**', ''),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            line.replaceAll('**', ''),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
