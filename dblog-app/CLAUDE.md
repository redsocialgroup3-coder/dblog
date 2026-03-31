# dBLog App - Flutter

App móvil para medir, registrar y documentar ruido excesivo.

## Comandos

```bash
flutter pub get          # Instalar dependencias
flutter run              # Ejecutar en dispositivo/simulador
flutter test             # Ejecutar tests
flutter analyze          # Análisis estático
flutter build ios        # Build iOS
flutter build apk        # Build Android
```

## GitHub

**IMPORTANTE**: Este repo pertenece al usuario `redsocialgroup3-coder`.
Para comandos `gh`, usar siempre:
```bash
DBLOG_GH_TOKEN=$(git -C .. remote get-url origin | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
GH_TOKEN=$DBLOG_GH_TOKEN gh <comando>
```
**NUNCA** usar otro usuario ni el `gh auth` global.

## Stack

- Flutter (Dart)
- Firebase Auth (autenticación)
- RevenueCat (pagos in-app)
- Plataformas: iOS + Android
