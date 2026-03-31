# Planner Memory — dBLog

## Aprendizajes
- [2026-03-31] noise_meter package funciona bien para captura de dB en tiempo real (100ms updates)
- [2026-03-31] fl_chart con duration: Duration.zero es la clave para gráficas en tiempo real
- [2026-03-31] Buffer circular de 600 entries = 60 segundos a 100ms interval

## Patrones del proyecto
- Provider + ChangeNotifier para state management
- Servicios en core/ son reutilizables entre features
- Selector para aislar rebuilds de widgets costosos (gráficas)

## Errores a evitar
- No olvidar manejo de lifecycle (pausar audio en background)
- Siempre exponer errores de servicios nativos a la UI
- Location service debe tener graceful failure (funcionar sin GPS para offline-first)
- Providers que dependen de otros: usar Consumer para inyectar dependencias en main.dart
