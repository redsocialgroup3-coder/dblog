# Flutter Developer Memory — dBLog

## Aprendizajes
- [2026-03-31] noise_meter ^5.0.2: expone Stream<NoiseReading> con meanDecibel/maxDecibel
- [2026-03-31] fl_chart ^0.70.0: usar duration: Duration.zero para gráficas tiempo real, sin dots
- [2026-03-31] permission_handler ^11.0.0 para permisos de micrófono
- [2026-03-31] Leq = 10 * log10(sumLinearPower / totalSamples), acumulación incremental
- [2026-03-31] WidgetsBindingObserver para pausar/reanudar audio en lifecycle changes

## Patrones del proyecto
- Archivos en snake_case, clases en PascalCase
- Strings UI en español, código en inglés
- Provider + ChangeNotifier (no Riverpod)
- Feature-based: features/<name>/{models,providers,widgets}
- Widgets < 200 líneas, extraer en componentes

## Errores a evitar
- Siempre exponer errorMessage en providers cuando servicios nativos fallan
- Mostrar estado vacío antes de primera interacción del usuario
- flutter analyze debe pasar sin errores antes de commit
