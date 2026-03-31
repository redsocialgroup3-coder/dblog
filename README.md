# dBLog - Noise Complaint Logger

App para medir, registrar y documentar legalmente el ruido excesivo causado por vecinos. Transforma la evidencia sonora en informes con validez legal.

## Estructura del monorepo

| Carpeta | Descripción | Stack |
|---------|-------------|-------|
| `dblog-app/` | App móvil iOS + Android | Flutter (Dart) |
| `dblog-api/` | Backend API | FastAPI (Python) |

## Features principales

- Medidor de decibelios en tiempo real
- Grabación de audio con metadatos (timestamp, geolocalización, dB)
- Comparación automática con límites legales por municipio
- Generación de informes PDF con validez legal
- Modo vigilancia nocturna con detección automática de picos
- Historial completo de evidencias

## Desarrollo

### App (Flutter)

```bash
cd dblog-app
flutter pub get
flutter run
```

### API (FastAPI)

```bash
cd dblog-api
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```
