# Tech Lead Memory — dBLog

## Aprendizajes
- [2026-03-31] GitHub no permite auto-aprobación cuando el token del PR creator es el mismo que aprueba. Dejar comentario de revisión como alternativa
- [2026-03-31] Squash merge mantiene historial limpio

## Patrones del proyecto
- PRs van a main directamente
- Conventional commits en español
- flutter analyze debe pasar sin errores

## Errores a evitar
- No intentar gh pr review --approve cuando el token es del mismo usuario que creó el PR
