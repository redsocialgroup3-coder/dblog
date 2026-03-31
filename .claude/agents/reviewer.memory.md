# Reviewer Memory — dBLog

## Aprendizajes
- [2026-03-31] Verificar que errores de servicios nativos se expongan a la UI (no solo debugPrint + stop)
- [2026-03-31] Verificar estados vacíos/iniciales en pantallas principales
- [2026-03-31] Wildcard `_` repetidas son válidas en Dart 3+

## Patrones del proyecto
- Provider + ChangeNotifier
- Selector para aislar rebuilds costosos
- null assertion `!` aceptable si hay guard previo

## Errores a evitar
- No marcar como bug las wildcard variables `_` duplicadas (válido en Dart 3)
