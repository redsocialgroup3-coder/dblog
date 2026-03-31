# Flutter Developer Memory — dBLog

## Aprendizajes
- [2026-03-31] noise_meter ^5.0.2: expone Stream<NoiseReading> con meanDecibel/maxDecibel
- [2026-03-31] fl_chart ^0.70.0: usar duration: Duration.zero para gráficas tiempo real, sin dots
- [2026-03-31] permission_handler ^11.0.0 para permisos de micrófono
- [2026-03-31] Leq = 10 * log10(sumLinearPower / totalSamples), acumulación incremental
- [2026-03-31] WidgetsBindingObserver para pausar/reanudar audio en lifecycle changes
- [2026-03-31] shared_preferences ^2.3.0 para persistir configuración simple (calibración offset)
- [2026-03-31] record package para grabación AAC/M4A, geolocator para GPS, path_provider para storage local
- [2026-03-31] uuid package para IDs únicos de grabaciones
- [2026-03-31] Metadatos de grabación se almacenan como JSON junto al archivo de audio (.json con mismo nombre)
- [2026-03-31] Timer countdown con límite de 60s para tier gratuito, auto-stop al llegar al límite

## Patrones del proyecto
- Archivos en snake_case, clases en PascalCase
- Strings UI en español, código en inglés
- Provider + ChangeNotifier (no Riverpod)
- Feature-based: features/<name>/{models,providers,widgets,services}
- Widgets < 200 líneas, extraer en componentes
- Servicios de feature van en features/<name>/services/
- Servicios core compartidos van en core/<name>/
- RecordingProvider observa MeterProvider para acumular dB readings durante grabación

## Errores a evitar
- Siempre exponer errorMessage en providers cuando servicios nativos fallan
- Mostrar estado vacío antes de primera interacción del usuario
- flutter analyze debe pasar sin errores antes de commit
