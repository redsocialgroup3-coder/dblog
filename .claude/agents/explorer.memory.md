# Explorer Memory — dBLog

## Aprendizajes
- [2026-03-31] Estructura modular: core/audio, core/constants, core/calibration, features/meter, features/recording, shared/theme
- [2026-03-31] features/recording tiene services/ además de models/providers/widgets
- [2026-03-31] features/history para historial de grabaciones
- [2026-03-31] features/onboarding para flujo de primera vez
- [2026-03-31] features/recording/widgets/verdict_screen.dart para veredicto post-grabación

## Patrones del proyecto
- Feature-based organization: features/<name>/{models,providers,widgets}
- Servicios core compartidos en core/audio/
- State management con Provider + ChangeNotifier

## Errores a evitar
_Sin entradas aún._
