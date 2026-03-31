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
- [2026-03-31] just_audio ^0.9.43 para reproducción de audio en historial
- [2026-03-31] CustomPainter para visualización de onda en detalle de grabación
- [2026-03-31] Onboarding con PageView, shared_preferences para persistir estado completado
- [2026-03-31] Tema oscuro profesional: fondo #1A1A2E, accent #00D4AA, danger #FF4757, warning #FFA502
- [2026-03-31] Gauge circular con CustomPainter para display de dB prominente
- [2026-03-31] Línea de referencia legal en gráfica fl_chart (ExtraLinesData horizontal)
- [2026-03-31] Verdict screen con 3 estados: SUPERA (rojo), CERCANO (amarillo), NO SUPERA (verde)
- [2026-03-31] firebase_core, firebase_auth, google_sign_in para auth
- [2026-03-31] ApiService con http package para comunicación con backend, auth token automático
- [2026-03-31] ProfileProvider con fallback local (shared_preferences) si no hay conexión
- [2026-03-31] geocoding package para reverse geocoding (municipio desde GPS)
- [2026-03-31] Datos offline de normativa embebidos en core/legal/data/ como constantes Dart
- [2026-03-31] connectivity_plus para detectar online/offline y auto-sync
- [2026-03-31] SyncService con cola persistente de uploads pendientes en shared_preferences
- [2026-03-31] share_plus para compartir archivos via share sheet nativo
- [2026-03-31] purchases_flutter ^8.0.0 para RevenueCat (pagos in-app)
- [2026-03-31] PaymentProvider con consumibles (PDF individual) y suscripción mensual
- [2026-03-31] ChangeNotifierProxyProvider para inyectar dependencias entre providers
- [2026-03-31] url_launcher para abrir URLs externas (gestión de suscripción en store)

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
